// Functional, port-level GBD1 endpoint regression. No DUT internals or hardware.
#include "Vuvhs_gbus_c2h_dma.h"
#include "verilated.h"
#include <array>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <stdexcept>
#include <string>

using Beat = std::array<uint32_t, 8>;
static Beat payload(uint32_t index) {
    Beat b{};
    for (unsigned i = 0; i < b.size(); ++i)
        b[i] = 0xa5190000u ^ (index * 0x10201u) ^ (i * 0x1234567u);
    return b;
}

struct Test {
    Vuvhs_gbus_c2h_dma d;
    uint64_t cycles = 0, responses = 0, accepted = 0, stalled = 0;
    int pending = 0, seen = 0;
    uint8_t expected_id = 0;
    uint32_t expected_first = 0;
    bool expected_error = false, expected_incr = true;
    unsigned expected_shift = 5; // ARSIZE in bits; consecutive beats advance by 2^shift bytes
    bool held = false;
    Beat held_data{};
    unsigned held_id = 0, held_resp = 0, held_last = 0;
    bool producer = false;
    uint32_t produced = 0, produce_goal = 0;

    void check(bool ok, const std::string &message) {
        if (!ok) throw std::runtime_error("cycle " + std::to_string(cycles) + ": " + message);
    }
    Beat rdata() const {
        Beat b{};
        for (unsigned i = 0; i < 8; ++i) b[i] = d.s_rdata[i];
        return b;
    }
    void set_data(uint32_t index) {
        Beat b = payload(index);
        for (unsigned i = 0; i < 8; ++i) d.s_tdata[i] = b[i];
    }
    void tick() {
        if (producer) {
            d.s_tvalid = produced < produce_goal;
            set_data(produced);
            d.s_tkeep = 0xffffffffu;
            d.s_tlast = produced % 24 == 23;
        }
        d.clk = 0;
        d.eval();
        if (d.rstn) {
            if (held) {
                check(d.s_rvalid, "RVALID dropped while stalled/reset");
                check(rdata() == held_data && d.s_rid == held_id &&
                      d.s_rresp == held_resp && d.s_rlast == held_last,
                      "AXI response changed while stalled/reset");
            }
            held = d.s_rvalid && !d.s_rready;
            if (held) {
                held_data = rdata(); held_id = d.s_rid;
                held_resp = d.s_rresp; held_last = d.s_rlast;
            }
            if (d.s_rvalid) {
                check(pending > 0, "unexpected/extra AXI response beat");
                check(d.s_rid == expected_id, "RID mismatch");
                check(d.s_rlast == (seen == pending - 1), "RLAST mismatch");
                check(d.s_rresp == (expected_error ? 2u : 0u), "RRESP mismatch");
                // A narrow transfer revisits the same 32-byte bank beat until
                // the address crosses a beat boundary, so advance by ARSIZE.
                const unsigned step = (seen * (1u << expected_shift)) / 32;
                const Beat want = expected_error ? Beat{} :
                    payload(expected_first + (expected_incr ? step : 0));
                check(rdata() == want, "RDATA mismatch at beat " + std::to_string(seen));
                if (d.s_rready) {
                    ++seen; ++responses;
                    if (seen == pending) pending = 0;
                }
            }
            if (d.s_arvalid && d.s_arready) {
                check(pending == 0, "overlapping AXI acceptance");
                pending = d.s_arlen + 1; seen = 0; expected_id = d.s_arid;
            }
        } else {
            pending = 0; held = false;
        }
        const bool stream_take = d.s_tvalid && d.s_tready;
        if (stream_take) ++accepted;
        if (d.s_tvalid && !d.s_tready) ++stalled;
        d.clk = 1;
        d.eval();
        if (producer && stream_take) ++produced;
        d.clk = 0;
        d.eval();
        ++cycles;
        check(cycles < 10000000, "global timeout");
    }
    void idle(int n = 1) { while (n--) tick(); }
    void reset(bool fabric = true) {
        producer = false;
        d.s_tvalid = 0; d.s_arvalid = 0; d.s_rready = 0;
        d.cfg_wr_en = 0; d.cfg_rd_en = 0;
        d.stream_rstn = 0;
        if (fabric) d.rstn = 0;
        idle(3);
        d.rstn = 1; d.stream_rstn = 1;
        idle(4);
    }
    uint32_t reg(uint16_t address) {
        d.cfg_rd_addr = address; d.cfg_rd_en = 1;
        tick();
        check(d.cfg_rdata_vld, "register response missing");
        uint32_t result = d.cfg_rdata;
        d.cfg_rd_en = 0;
        return result;
    }
    void eqreg(uint16_t address, uint32_t want) {
        uint32_t got = reg(address);
        check(got == want, "register " + std::to_string(address) +
              " got " + std::to_string(got) + " wanted " + std::to_string(want));
    }
    void ctrl(uint32_t value) {
        d.cfg_wr_addr = 0x1204; d.cfg_wdata = value; d.cfg_wr_en = 1;
        tick(); d.cfg_wr_en = 0;
    }
    void send(uint32_t first, unsigned count, int bad_last = -1, bool bad_keep = false) {
        for (unsigned i = 0; i < count; ++i) {
            set_data(first + i);
            d.s_tvalid = 1;
            d.s_tkeep = bad_keep ? 0xfffffffeu : 0xffffffffu;
            d.s_tlast = bad_last < 0 ? ((first + i) % 24 == 23) : (int(i) == bad_last);
            d.eval();
            unsigned guard = 0;
            while (!d.s_tready) { tick(); check(++guard < 10000, "send timeout"); }
            tick();
        }
        d.s_tvalid = 0;
        // One pointer-sync cycle: the following FILL lands as fhas rises,
        // while FIFO output VALID still has its prefetch cycle to go.
        idle(1);
    }
    unsigned finish_fill() {
        for (int i = 0; i < 100; ++i) {
            uint32_t s = reg(0x1200);
            if (!(s & 0x80)) {
                check(s & 0x80000000u, "present bit absent");
                unsigned words = (s >> 8) & 0x1ff;
                check(words % 8 == 0 && words <= 256, "bad staged_words encoding");
                check(bool(s & 0x20) == (words != 0), "frozen/count disagreement");
                eqreg(0x1204, words);
                return words / 8;
            }
        }
        check(false, "fill timeout"); return 0;
    }
    void fill(unsigned count) {
        ctrl(1); check(finish_fill() == count, "unexpected published beat count");
    }
    void ar(uint32_t addr, unsigned len, unsigned burst, bool error,
            uint32_t first = 0, unsigned size = 5, unsigned race_control = 0) {
        check(pending == 0, "test issued AR before previous completion");
        expected_error = error; expected_first = first; expected_incr = burst == 1;
        expected_shift = size;
        d.s_araddr = addr; d.s_arlen = len; d.s_arburst = burst; d.s_arsize = size;
        d.s_arid = uint8_t(cycles * 37 + 0x91); d.s_arvalid = 1;
        if (race_control) {
            d.cfg_wr_en = 1; d.cfg_wr_addr = 0x1204; d.cfg_wdata = race_control;
        }
        d.eval(); check(d.s_arready, "AR unexpectedly blocked");
        tick(); d.s_arvalid = 0; d.cfg_wr_en = 0;
        check(pending == int(len + 1), "AR not accepted");
    }
    void drain(bool stalls = true) {
        unsigned guard = 0;
        while (pending) {
            d.s_rready = !stalls || (guard % 5 == 3);
            tick(); check(++guard < 200, "AXI drain timeout");
        }
        d.s_rready = 0;
        tick();
        check(!d.s_rvalid, "extra response after RLAST");
    }
    void read(uint32_t addr, unsigned len, unsigned burst, bool error,
              uint32_t first = 0, unsigned size = 5) {
        ar(addr, len, burst, error, first, size); drain();
    }
    void debug_bank(uint32_t first, unsigned beats) {
        for (unsigned i = 0; i < beats * 8; ++i)
            eqreg(uint16_t(0x2000 + i * 4), payload(first + i / 8)[i % 8]);
        if (beats < 32) eqreg(uint16_t(0x2000 + beats * 32), 0);
        eqreg(0x2400, 0);
    }
    void pass(const char *what) { std::cout << "PASS " << what << '\n'; }

    void run() {
        reset();
        eqreg(0x1200, 0x80000000); eqreg(0x1208, 0x47424431);
        eqreg(0x1210, 0x10000000); eqreg(0x1214, 1024); eqreg(0x120c, 0);
        tick(); check(!d.cfg_rdata_vld, "cfg_rdata_vld not pulsed");
        fill(0); eqreg(0x120c, 0); eqreg(0x1200, 0x80000000);
        read(0x10000000, 15, 1, true); ctrl(4);
        ctrl(2); check(reg(0x1200) & (1u << 29), "idle ACK not rejected"); ctrl(4);
        ctrl(3); eqreg(0x1200, 0xa0000000); ctrl(4);
        pass("ABI, empty fill termination, idle reads/controls");

        // Start before FIFO output prefetch is valid, but after pointer sync.
        send(0, 1); fill(1); eqreg(0x120c, 1);
        eqreg(0x1200, 0x80000820); // count shift, no FIFO data despite frozen bank
        debug_bank(0, 1); read(0x10000000, 15, 0, false); // FIXED repeats one beat
        read(0x10000000, 1, 1, true); read(0x10000020, 0, 0, true);
        ctrl(4); ctrl(2); eqreg(0x2000, 0); eqreg(0x120c, 1);
        pass("prefetch-aware partial publication, count and FIXED vs INCR bounds");

        reset(); send(0, 48); idle(5); fill(32); eqreg(0x120c, 1);
        check(!(reg(0x1200) & (1u << 30)), "valid framing flagged");
        debug_bank(0, 32);
        for (unsigned len = 0; len < 16; ++len) {
            read(0x10000000, len, 1, false);
            read(0x100003e0, len, 0, false, 31);
        }
        read(0x10000200, 15, 1, false, 16);
        ctrl(1); check(reg(0x1200) & (1u << 29), "fill overwrote frozen bank");
        ctrl(3); debug_bank(0, 32); ctrl(4);
        // AR/ACK race: AR wins and the frozen bank survives.
        ar(0x10000000, 15, 1, false, 0, 5, 2);
        eqreg(0x1200, 0xa0010070);
        ctrl(2); ctrl(1); idle(5); drain(); debug_bank(0, 32);
        ctrl(4); ctrl(2); fill(16); eqreg(0x120c, 2); debug_bank(32, 16);
        read(0x10000000, 15, 1, false, 32);
        read(0x100001e0, 15, 0, false, 47);
        read(0x100001e0, 1, 1, true);
        pass("TLAST does not publish, immutable 1-KiB banks, all ARLEN values, ACK/AR race");

        // Entire transactions fail, never return an OK prefix. Test every
        // invalid length, burst type, alignment and aperture alias boundary.
        for (unsigned len = 0; len < 16; ++len) read(0x10000200, len, 1, true);
        for (unsigned size = 6; size < 8; ++size)
            read(0x10000000, 15, 1, true, 0, size);
        for (unsigned offset = 1; offset < 32; ++offset)
            read(0x10000000 + offset, 1, 0, true);
        read(0x10000000, 15, 2, true); read(0x10000000, 15, 3, true);
        for (uint32_t addr : {0x0fffffe0u, 0x100003e0u, 0x10000400u,
                             0x10000fe0u, 0x10001000u, 0xffffffe0u})
            read(addr, 15, 1, true);
        // Transfers narrower than the 32-byte bus are ordinary AXI reads: they
        // touch the same bytes and must return the correct lanes.  The bank
        // currently holds stream beats 32..47 at bank indices 0..15.
        read(0x10000000, 0, 0, false, 32, 0);  // one byte
        read(0x10000000, 7, 1, false, 32, 2);  // 8 x 4 bytes = one bank beat
        read(0x10000020, 3, 1, false, 33, 3);  // 4 x 8 bytes inside beat 1
        read(0x10000040, 15, 1, false, 34, 4); // 16 x 16 bytes = 256 bytes

        // The bring-up diagnostics must report the transaction the endpoint
        // actually received, not a latched or defaulted value.
        const uint32_t ar_count_before = reg(0x1220);
        read(0x10000000, 0, 1, false, 32, 5);
        eqreg(0x1220, ar_count_before + 1);
        eqreg(0x1218, 0x10000000);
        check(((reg(0x121c) >> 22) & 3U) == 1U, "AR burst not recorded");
        check(((reg(0x121c) >> 19) & 7U) == 5U, "AR size not recorded");
        check(((reg(0x121c) >> 15) & 0xfU) == 0U, "AR length not recorded");
        read(0x10000020, 2, 0, false, 33, 3);
        eqreg(0x1218, 0x10000020);
        check(((reg(0x121c) >> 22) & 3U) == 0U, "FIXED burst not recorded");
        check(reg(0x1220) == ar_count_before + 2U, "AR count did not advance");

        ctrl(4); ctrl(2);
        // FILL colliding with AR must not consume the FIFO.
        send(48, 4); idle(5);
        ar(0x10000000, 0, 1, true, 0, 5, 1); drain();
        check((reg(0x1200) & 0xa0) == 0, "AR/FILL race started filling");
        ctrl(4); fill(4); debug_bank(48, 4);
        // Transfers narrower than the 32-byte bus are ordinary AXI reads: they
        // touch the same bytes and must return the correct lanes.
        pass("SLVERR exact lengths/stalls, invalid size/alignment/burst/aperture, narrow transfers");

        reset(); send(0, 24, 0); // early AND missing final TLAST
        check(reg(0x1200) & (1u << 30), "early TLAST not flagged");
        ctrl(2); ctrl(4);
        check((reg(0x1200) & 0x60000000) == 0x40000000, "clear changed frame_error");
        send(24, 24); check(reg(0x1200) & (1u << 30), "good frame cleared sticky error");
        reset(false); send(0, 24, 99);
        check(reg(0x1200) & (1u << 30), "missing TLAST not flagged");
        reset(false); send(0, 1, -1, true);
        check(reg(0x1200) & (1u << 30), "partial TKEEP not flagged");
        reset(false); send(0, 24); check(!(reg(0x1200) & (1u << 30)), "reset framing failed");
        pass("accepted-beat frame checks, full TKEEP, sticky errors and stream reset");

        reset(); send(0, 48); idle(5); fill(32);
        ar(0x10000000, 15, 1, false);
        idle(3); // outstanding first beat stalled
        reset(false); // all response signals/data must survive
        eqreg(0x120c, 0); eqreg(0x2000, 0);
        check((reg(0x1200) & 0x4001fff0) == 0x10, "stream metadata not cleared");
        send(0, 8); ctrl(1); check(reg(0x1200) & (1u << 29), "fill allowed before reset burst drained");
        idle(5); drain(); ctrl(4); fill(8); debug_bank(0, 8);
        // Reset during a later beat, and drain while reset remains asserted.
        ar(0x10000000, 7, 1, false);
        d.s_rready = 1; idle(3); d.s_rready = 0; idle(2);
        d.stream_rstn = 0; idle(2); drain();
        check(!d.s_tready, "ready asserted during reset");
        read(0x10000000, 15, 0, true);
        d.stream_rstn = 1; idle(4); ctrl(4); fill(0);
        // Error bursts also survive stream reset. Fabric reset may abort.
        ar(0x10000400, 15, 1, true); reset(false); drain();
        ar(0x10000000, 15, 1, true); idle(2); reset();
        check(!d.s_rvalid, "fabric reset did not abort AXI");
        // Reset aborts an in-progress fill and discards all FIFO payload.
        send(0, 48); idle(5); ctrl(1); idle(3);
        check(reg(0x1200) & 0x80, "fill not in progress");
        ctrl(2); ctrl(3); check(reg(0x1200) & (1u << 29), "busy control not rejected");
        reset(false); ctrl(4); fill(0); eqreg(0x120c, 0);
        pass("stream reset preserves stalled/mid-burst/error responses; fabric reset abort; fill reset");

        reset(); send(0, 32); idle(5); ctrl(1);
        ar(0x10000000, 15, 1, true); // bank not yet published
        // A second address must remain blocked until the outstanding response
        // drains, even with ARVALID held high during a stalled R channel.
        d.s_arvalid = 1;
        for (int i = 0; i < 4; ++i) {
            check(!d.s_arready, "ARREADY accepted a second outstanding burst");
            tick();
        }
        d.s_arvalid = 0;
        check(reg(0x1200) & 0x80, "invalid AR lost in-progress fill");
        // ACK on the final handshake is still busy, not an early release.
        d.s_rready = 1; idle(15); ctrl(2);
        check(pending == 0, "continuous-ready error burst failed to complete");
        d.s_rready = 0;
        check(finish_fill() == 32, "fill failed to resume after invalid AXI");
        check(reg(0x1200) & (1u << 29), "last-handshake control not rejected");
        read(0x10000000, 15, 1, false); debug_bank(0, 32);
        ctrl(4); ctrl(2);
        pass("AR during fill, one outstanding burst, continuous RREADY, final-handshake control rejection");

        // Real default 2048-entry FIFO: pause the host until ready goes low,
        // keep producer VALID/data held, then drain slowly through wraps.
        reset(); producer = true; produced = 0; produce_goal = 5000;
        const uint64_t before_stalls = stalled;
        idle(2200);
        check(produced >= 2047 && produced <= 2049, "wrong default FIFO capacity");
        check(stalled > before_stalls + 100, "FIFO never backpressured sender");
        uint32_t consumed = 0, publications = 0;
        while (consumed < produce_goal) {
            ctrl(1); unsigned n = finish_fill();
            check(n > 0, "unexpected empty slow-drain bank");
            ++publications;
            for (unsigned j = 0; j < n; j += 16) {
                unsigned chunk = (n - j > 16) ? 16 : n - j;
                read(0x10000000 + j * 32, chunk - 1, 1, false, consumed + j);
            }
            idle(25); // delayed ACK must not lose or duplicate incoming data
            consumed += n; ctrl(2);
        }
        check(produced == produce_goal && consumed == produce_goal, "stream loss on resume");
        producer = false; d.s_tvalid = 0; idle(5);
        eqreg(0x120c, publications); eqreg(0x1200, 0x80000000); fill(0);
        pass("64-KiB FIFO full/backpressure/slow drain/resume and 5000 beats byte-exact");

        // Cross the old draft's 16-bit sequence boundary using real publishes.
        reset();
        for (uint32_t i = 0; i < 65537; ++i) {
            send(i, 1); fill(1); ctrl(2);
        }
        eqreg(0x120c, 65537); fill(0); eqreg(0x120c, 65537);
        pass("32-bit publication sequence crosses 65535 without truncation");
        std::cout << "ALL PASS: " << cycles << " cycles, " << responses
                  << " checked AXI beats, " << accepted << " accepted stream beats\n";
    }
};

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    try { Test t; t.run(); }
    catch (const std::exception &e) { std::cerr << "FAIL " << e.what() << '\n'; return EXIT_FAILURE; }
    return EXIT_SUCCESS;
}
