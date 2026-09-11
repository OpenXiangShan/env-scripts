// Focused probe for the GBus C2H SRAM staging window.
//
// The first board run left fpga-host looping on the drain path: every status
// read returned present|has_data with staged_words == 0, so a fill never
// produced anything.  This probe reads the window directly and answers, in
// order of importance:
//
//   1. what the status word actually is, and whether it changes over time
//   2. what a fill does to it
//   3. whether the staging window holds anything
//   4. whether gbus_read(count > 1) returns consecutive words (this is open
//      since the host-side multi-word probe was never independently checked)
//   5. how long one register round trip takes
//
// Read-only apart from writing the fill control register, so it is safe to run
// against a board that is otherwise idle.
//
// Build (on the FPGA host, against the UVHS runtime library):
//   g++ -O2 -std=c++20 -I<gbus_runtime>/include gbus_sram_probe.cpp \
//       -L<gbus_runtime>/lib -Wl,-rpath,<gbus_runtime>/lib -luvgbus -o gbus_sram_probe

#include <uvaps_gbus_runtime.h>

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

namespace {

uint8_t prototyping = 0;
uint8_t board = 0;
uint8_t fpga = 0;
uint8_t instance = 0;
uint64_t config_base = 0x1000;

// GeneralBD local offsets (the 0x1000 config window is added by config_base).
constexpr uint64_t REG_STATUS = 0x1200;
constexpr uint64_t REG_CTRL = 0x1204;
constexpr uint64_t REG_DATA = 0x2000;
constexpr uint32_t STAGE_WORDS = 256;

uint64_t env_u64(const char *name, uint64_t fallback) {
  const char *v = std::getenv(name);
  if (!v || !*v)
    return fallback;
  char *end = nullptr;
  const unsigned long long parsed = std::strtoull(v, &end, 0);
  return (end == v || *end) ? fallback : static_cast<uint64_t>(parsed);
}

uint64_t now_us() {
  return static_cast<uint64_t>(
      std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::steady_clock::now().time_since_epoch())
          .count());
}

uint32_t load_le32(const std::vector<uint8_t> &v) {
  if (v.size() < 4)
    return 0;
  return static_cast<uint32_t>(v[0]) | (static_cast<uint32_t>(v[1]) << 8) | (static_cast<uint32_t>(v[2]) << 16) |
         (static_cast<uint32_t>(v[3]) << 24);
}

std::string decode_status(uint32_t s) {
  char buf[256];
  std::snprintf(buf, sizeof(buf),
                "present=%u frame_error=%u draining=%u staged_words=%u filling=%u has_data=%u",
                (s >> 31) & 1u, (s >> 30) & 1u, (s >> 29) & 1u, (s >> 8) & 0x1ffu, (s >> 7) & 1u, (s >> 6) & 1u);
  return buf;
}

bool read_reg(uint64_t local_offset, size_t count, std::vector<uint8_t> &out) {
  return gbus_read(prototyping, board, fpga, instance, config_base + local_offset, count, out) == 1 &&
         out.size() == count * 4;
}

bool write_reg(uint64_t local_offset, uint32_t value) {
  std::vector<uint8_t> data = {static_cast<uint8_t>(value), static_cast<uint8_t>(value >> 8),
                               static_cast<uint8_t>(value >> 16), static_cast<uint8_t>(value >> 24)};
  return gbus_write(prototyping, board, fpga, instance, config_base + local_offset, 1, data) == 1;
}

uint32_t read_status() {
  std::vector<uint8_t> v;
  if (!read_reg(REG_STATUS, 1, v))
    return 0xdeadbeef;
  return load_le32(v);
}

} // namespace

int main() {
  prototyping = static_cast<uint8_t>(env_u64("GBUS_PROTOTYPING_INSTANCE", 0));
  board = static_cast<uint8_t>(env_u64("GBUS_BOARD", 0));
  fpga = static_cast<uint8_t>(env_u64("GBUS_FPGA", 2));
  instance = static_cast<uint8_t>(env_u64("GBUS_CONFIG_INSTANCE", 0));
  config_base = env_u64("GBUS_CONFIG_BASE", 0x1000);

  const char *host = std::getenv("GBUS_HOST");
  if (!gbus_initialize(host && *host ? host : "localhost")) {
    std::fprintf(stderr, "gbus_initialize failed\n");
    return 2;
  }
  std::printf("config_base=0x%llx fpga=%u instance=%u\n", static_cast<unsigned long long>(config_base), fpga, instance);

  // Warm up: the first access on a fresh channel costs about a second.
  const uint64_t warm = now_us();
  read_status();
  std::printf("warm-up: %llu us\n\n", static_cast<unsigned long long>(now_us() - warm));


  // --- 0. address map sanity ----------------------------------------------
  // A hole must read differently from a decoded register.  If a known-empty
  // address returns the same word as the C2H status register, then the status
  // we are reading is not the FIFO's at all and every conclusion below is
  // meaningless.  The config BAR is included because it is known-good.
  std::printf("== address map scan (host offset = 0x1000 + local) ==\n");
  struct Probe { uint64_t local; const char *what; };
  const Probe probes[] = {
      {0x0000, "config CFG_RESET (self-clearing, expect 0)"},
      {0x0010, "config SQUASH_ENABLE"},
      {0x1200, "C2H STATUS"},
      {0x1204, "C2H CTRL"},
      {0x1400, "hole between CTRL and window"},
      {0x2000, "C2H staging window word 0"},
      {0x2400, "hole inside/after window"},
      {0x2800, "hole"},
      {0x4000, "hole well past the C2H block"},
  };
  for (const Probe &p : probes) {
    std::vector<uint8_t> v;
    const bool ok = read_reg(p.local, 1, v);
    std::printf("  local=0x%04llx read=0x%08x ok=%d  %s\n", static_cast<unsigned long long>(p.local),
                ok ? load_le32(v) : 0u, ok ? 1 : 0, p.what);
  }

  // --- 1. status over time, untouched --------------------------------------
  std::printf("== status, no register written ==\n");
  for (int i = 0; i < 8; ++i) {
    const uint32_t s = read_status();
    std::printf("  [%d] 0x%08x  %s\n", i, s, decode_status(s).c_str());
  }

  // --- 2. what a fill does -------------------------------------------------
  std::printf("\n== write CTRL=1 (start fill), then poll ==\n");
  if (!write_reg(REG_CTRL, 1))
    std::printf("  CTRL write failed\n");
  for (int i = 0; i < 12; ++i) {
    const uint32_t s = read_status();
    std::printf("  [%d] 0x%08x  %s\n", i, s, decode_status(s).c_str());
  }

  // --- 3. staging window contents -----------------------------------------
  std::printf("\n== staging window, first 16 words ==\n");
  const uint32_t st = read_status();
  const uint32_t words = (st >> 8) & 0x1ffu;
  const uint32_t show = words < 16 ? words : 16;
  std::printf("  staged_words=%u (showing %u)\n", words, show);
  for (uint32_t i = 0; i < show; ++i) {
    std::vector<uint8_t> v;
    if (!read_reg(REG_DATA + i * 4, 1, v)) {
      std::printf("  [%2u] read failed\n", i);
      continue;
    }
    std::printf("  [%2u] 0x%08x\n", i, load_le32(v));
  }

  // --- 4. multi-word read semantics ---------------------------------------
  // Ground truth is the single-word path, which the config BAR already proved
  // works.  Four registers that are known to be readable individually.
  std::printf("\n== multi-word read test at STATUS (count=4) ==\n");
  std::vector<uint8_t> block;
  const int rc = gbus_read(prototyping, board, fpga, instance, config_base + REG_STATUS, 4, block);
  std::printf("  gbus_read(count=4) rc=%d bytes=%zu\n", rc, block.size());
  for (size_t i = 0; i < block.size() / 4; ++i) {
    std::vector<uint8_t> one;
    read_reg(REG_STATUS + i * 4, 1, one);
    const uint32_t b = load_le32(std::vector<uint8_t>(block.begin() + i * 4, block.begin() + i * 4 + 4));
    const uint32_t s1 = load_le32(one);
    std::printf("  word%zu block=0x%08x single=0x%08x %s\n", i, b, s1, b == s1 ? "" : "MISMATCH");
  }

  // --- 5. register round-trip cost ----------------------------------------
  constexpr int kN = 30;
  const uint64_t t0 = now_us();
  for (int i = 0; i < kN; ++i)
    read_status();
  const uint64_t dt = now_us() - t0;
  std::printf("\n== latency: %d reads in %llu us -> %.1f us/read (%.0f words/s)\n", kN,
              static_cast<unsigned long long>(dt), static_cast<double>(dt) / kN,
              dt ? 1e6 * kN / dt : 0.0);
  std::printf("   a 768-byte range is %u words -> %.1f ms per range at this rate\n", 768 / 4,
              (double)dt / kN * (768 / 4) / 1000.0);


  // --- 6. burst read cost -------------------------------------------------
  // count > 1 works (see above), so the drain can fetch a window in one call.
  // Measure what that actually costs: it bounds the C2H bandwidth of the whole
  // register-window design.
  std::printf("\n== burst read cost (read-only, at STATUS) ==\n");
  for (size_t n : {2u, 4u, 16u, 64u, 256u}) {
    std::vector<uint8_t> buf;
    const uint64_t b0 = now_us();
    const int brc = gbus_read(prototyping, board, fpga, instance, config_base + REG_STATUS, n, buf);
    const uint64_t bdt = now_us() - b0;
    std::printf("  count=%3zu rc=%d bytes=%4zu  %7llu us  -> %6.1f us/word, %8.0f words/s, %6.1f ms/range\n", n, brc,
                buf.size(), static_cast<unsigned long long>(bdt), (double)bdt / n, bdt ? 1e6 * n / bdt : 0.0,
                (double)bdt / n * (768 / 4) / 1000.0);
  }

  gbus_finalize();
  return 0;
}
