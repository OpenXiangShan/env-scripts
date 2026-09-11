// GBus register-channel probe: answers the two questions the SRAM staging
// window depends on, without needing a new bitstream.
//
//   1. Does gbus_read(count > 1) return consecutive words, or does it ignore the
//      count/address?  The SRAM C2H drain reads a 1 KiB window, so this decides
//      whether a 768-byte DiffTest range costs 192 register round trips or one.
//   2. How long does one register round trip actually take?  That number is the
//      C2H bandwidth ceiling for this interface layer.
//
// The config BAR at 0x1000..0x1030 is used as ground truth: it exists in every
// GBus bitstream we have built, its words are known to differ from each other,
// and single-word reads of it are already verified to match (see
// build_logs/uvhs_gbus_20260910/DIAGNOSIS.md).
//
// Build (on the FPGA host, against the UVHS runtime library):
//   g++ -O2 -std=c++20 -I<gbus_runtime>/include gbus_reg_probe.cpp \
//       -L<gbus_runtime>/lib -Wl,-rpath,<gbus_runtime>/lib -luvgbus -o gbus_reg_probe
//
// Run:
//   GBUS_HOST=<runtime-host> GBUS_FPGA=2 GBUS_CONFIG_BASE=0x1000 ./gbus_reg_probe
//
// Read-only: the probe never writes a register.

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
uint64_t single_reads = 200;

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

std::string hex32(const std::vector<uint8_t> &v, size_t index) {
  if (v.size() < (index + 1) * 4)
    return "--------";
  char b[16];
  std::snprintf(b, sizeof(b), "%02x%02x%02x%02x", v[index * 4 + 3], v[index * 4 + 2], v[index * 4 + 1], v[index * 4]);
  return b;
}

bool read_words(uint64_t offset, size_t count, std::vector<uint8_t> &out, int *rc) {
  const int r = gbus_read(prototyping, board, fpga, instance, config_base + offset, count, out);
  if (rc)
    *rc = r;
  return r == 1 && out.size() == count * 4;
}

} // namespace

int main() {
  const char *host = std::getenv("GBUS_HOST");
  prototyping = static_cast<uint8_t>(env_u64("GBUS_PROTOTYPING_INSTANCE", 0));
  board = static_cast<uint8_t>(env_u64("GBUS_BOARD", 0));
  fpga = static_cast<uint8_t>(env_u64("GBUS_FPGA", 2));
  instance = static_cast<uint8_t>(env_u64("GBUS_CONFIG_INSTANCE", 0));
  config_base = env_u64("GBUS_CONFIG_BASE", 0x1000);
  single_reads = env_u64("GBUS_SINGLE_READS", 200);

  if (!gbus_initialize(host && *host ? host : "localhost")) {
    std::fprintf(stderr, "gbus_initialize failed\n");
    return 2;
  }
  std::printf("config_base=0x%llx fpga=%u instance=%u single_reads=%llu\n",
              static_cast<unsigned long long>(config_base), fpga, instance,
              static_cast<unsigned long long>(single_reads));

  // The first access to the channel costs about a second (socket/JTAG setup).
  // Warm it up and keep it out of every measurement below.
  std::vector<uint8_t> warmup;
  const uint64_t warm_begin = now_us();
  read_words(0, 1, warmup, nullptr);
  std::printf("warm-up first register read: %llu us\n", static_cast<unsigned long long>(now_us() - warm_begin));

  // --- 1. per-read latency ------------------------------------------------
  const uint64_t latency_begin = now_us();
  for (uint64_t i = 0; i < single_reads; ++i) {
    std::vector<uint8_t> word;
    if (!read_words((i % 13) * 4, 1, word, nullptr)) {
      std::fprintf(stderr, "single register read %llu failed\n", static_cast<unsigned long long>(i));
      gbus_finalize();
      return 1;
    }
  }
  const uint64_t latency_total = now_us() - latency_begin;
  std::printf("single-word reads: %llu in %llu us -> %.1f us/read (%.1f kwords/s)\n",
              static_cast<unsigned long long>(single_reads), static_cast<unsigned long long>(latency_total),
              single_reads ? static_cast<double>(latency_total) / single_reads : 0.0,
              latency_total ? 1000.0 * single_reads / latency_total : 0.0);

  // --- 2. multi-word semantics -------------------------------------------
  // Ground truth is the per-word read the single-word path already proves works.
  constexpr size_t kWords = 13;
  std::vector<uint8_t> ones;
  for (size_t i = 0; i < kWords; ++i) {
    std::vector<uint8_t> word;
    if (!read_words(i * 4, 1, word, nullptr)) {
      std::fprintf(stderr, "ground-truth read of word %zu failed\n", i);
      gbus_finalize();
      return 1;
    }
    ones.insert(ones.end(), word.begin(), word.end());
  }

  std::vector<uint8_t> block;
  int rc = 0;
  const uint64_t block_begin = now_us();
  const bool sized = read_words(0, kWords, block, &rc);
  const uint64_t block_us = now_us() - block_begin;
  std::printf("multi-word read count=%zu rc=%d bytes=%zu elapsed=%llu us\n", kWords, rc, block.size(),
              static_cast<unsigned long long>(block_us));
  if (block_us)
    std::printf("  -> %.1f us/word at count=%zu\n", static_cast<double>(block_us) / kWords, kWords);

  std::printf("  idx  single    block\n");
  size_t mismatches = 0;
  for (size_t i = 0; i < kWords; ++i) {
    const std::string a = hex32(ones, i);
    const std::string b = hex32(block, i);
    const bool same = a == b;
    mismatches += same ? 0 : 1;
    std::printf("  %3zu  %s  %s  %s\n", i, a.c_str(), b.c_str(), same ? "" : "MISMATCH");
  }

  if (!sized) {
    std::printf("VERDICT: count>1 is NOT usable (wrong return size); drain must use one read per word\n");
  } else if (mismatches == 0) {
    std::printf("VERDICT: count>1 returns consecutive words; the staging window can be drained in one call per KiB\n");
  } else {
    std::printf("VERDICT: count>1 returned %zu/%zu wrong words; treat it as unusable\n", mismatches, kWords);
  }

  gbus_finalize();
  return 0;
}
