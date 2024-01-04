#include <common.h>
#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <zlib.h>
#include "xs_MemRam.h"

using namespace std;
#define GCPT_MAX_SIZE 0x700
static bool isGzFile(const char *filename);
static long readFromGz(void* ptr, const char *file_name, long buf_size);

xs_MemRam::xs_MemRam(uint64_t size)
{
  ram_size = size;
  ram = (char *)malloc(size);
}

xs_MemRam::~xs_MemRam()
{
  free(ram);
}

uint64_t
xs_MemRam::read_data(uint64_t addr)
{
  check_ram_addr(addr);
  return (*((uint64_t *)ram + addr));
}

void
xs_MemRam::write_data(uint64_t addr, uint64_t w_mask, uint64_t data)
{
  check_ram_addr(addr);
  (*((uint64_t *)ram + addr)) = (data & w_mask) | ((*((uint64_t *)ram + addr)) & ~w_mask);
}

void
xs_MemRam::check_ram_addr(uint64_t addr)
{
  if (ram_size < addr) {
    printf("xs-ram addr out of bounds\n");
    assert(0);
  }
}

void
xs_MemRam::load_bin(const char * bin_file)
{
  if (isGzFile(bin_file)) {
    readFromGz(ram,bin_file,ram_size);
  }
  else {
    ifstream fp(bin_file,ios::binary);
    if (!fp) {
      printf("can not open %s \n",bin_file);
      free(ram);
      assert(0);
    }
    // get size
    fp.seekg(0, fp.end);
    uint64_t length = fp.tellg();
    fp.seekg(0, fp.beg);
    length = (length > ram_size) ? ram_size : length;
    // load bin
    if (fp.is_open()) {
      fp.read(ram, length);
    }

    fp.close();
  }
}


static char bin_file[256] = "ram.gz";
static char gcpt_bin_file[256] = "gcpt.bin";
static xs_MemRam *MemRam = NULL;
static bool init_ok = false;

extern "C" void ram_read_data(uint64_t addr, uint64_t *r_data) {
  *r_data = MemRam->read_data(addr);
}

extern "C" void ram_write_data(uint64_t addr, uint64_t w_mask, uint64_t data) {
  MemRam->write_data(addr, w_mask, data);
}

extern "C" void init_ram(uint64_t size) {
  if (init_ok) return;
  assert(size > 0);

  MemRam = new xs_MemRam(size);
  printf("ram init size %d MB\t",size/1024/1024);
  char file_path[128];

#ifdef MEMORY_IMAGE
  sscanf(MEMORY_IMAGE,"%s",file_path);
  MemRam->load_bin(file_path);
  printf("load bin_file %s\n",MEMORY_IMAGE);
#ifdef GCPT_IMAGE
  // override gcpt-restore
  memset(file_path,0,128);
  sscanf(GCPT_IMAGE,"%s",file_path);
  MemRam->load_bin(file_path);
  printf("ram override gcpt_bin_file %s\n",GCPT_IMAGE);
#endif // GCPT_IMAGE
#else
  eprintf("ram cannot be uninitialized");
  assert(0);
#endif // GCPT_IMAGE

  init_ok = 1;
}

extern "C" void free_xs_ram() {
  MemRam->~xs_MemRam();
  delete MemRam;
}

// Return whether the file is a gz file
bool isGzFile(const char *filename) {
  if (filename == NULL || strlen(filename) < 4) {
    return false;
  }
  return !strcmp(filename + (strlen(filename) - 3), ".gz");
}

long readFromGz(void* ptr, const char *file_name, long buf_size) {
  assert(buf_size > 0);
  gzFile gz_file = gzopen(file_name, "rb");

  if (gz_file == NULL) {
    printf("Can't open compressed binary file '%s'", file_name);
    return -1;
  }

  uint64_t curr_size = 0;
  const uint32_t chunk_size = 16384;

  long *temp_page = new long[chunk_size];

  while (curr_size < buf_size) {
    uint32_t bytes_read = gzread(gz_file, temp_page, chunk_size * sizeof(long));
    if (bytes_read == 0) {
      break;
    }
    for (uint32_t x = 0; x < bytes_read / sizeof(long) + 1; x++) {
      if (*(temp_page + x) != 0) {
        long *pmem_current = (long*)((uint8_t*)ptr + curr_size + x * sizeof(long));
        *pmem_current = *(temp_page + x);
      }
    }
    curr_size += bytes_read;
  }

  if(gzread(gz_file, temp_page, chunk_size) > 0) {
    printf("File size is larger than buf_size!\n");
    assert(0);
  }

  delete [] temp_page;

  if(gzclose(gz_file)) {
    printf("Error closing '%s'\n", file_name);
    return -1;
  }
  return curr_size;
}