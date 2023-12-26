#include <common.h>
#include <iostream>
#include <fstream>
#include <stdlib.h>
using namespace std;

static char bin_file[256] = "ram.bin";
static char gcpt_bin_file[256] = "gcpt.bin";
static char *ram = NULL;
static bool enable_overr_gcpt = false;
static uint64_t set_size = 0;
static bool init_ok = false;
void check_ram_addr(uint64_t addr) {
  if (set_size < addr) {
    printf("xs-ram addr out of bounds\n");
    assert(0);
  }
}

extern "C" void ram_load_bin_file(char *s) {
  printf("ram image:%s\n",s);
  strcpy(bin_file, s);
}
extern "C" void ram_load_gcpt_file(char *s) {
  printf("gcpt image:%s\n",s);
  enable_overr_gcpt = true;
  strcpy(gcpt_bin_file, s);
}

extern "C" void ram_read_data(uint64_t addr, uint64_t *r_data) {
  check_ram_addr(addr);
  *r_data = (*((uint64_t *)ram + addr));
}

extern "C" void ram_write_data(uint64_t addr, uint64_t w_mask, uint64_t data) {
  check_ram_addr(addr);
  (*((uint64_t *)ram + addr)) = (data & w_mask) | ((*((uint64_t *)ram + addr)) & ~w_mask);
}

extern "C" void init_ram(uint64_t size) {
  if (init_ok) return;
  assert(size > 0);

  int ret;
  uint64_t length;
  ram = (char *)calloc(size,1);
  printf("ram init size %d MB",size/1024/1024);

	ifstream fp(bin_file,ios::binary);
  if (!fp) {
    printf("can not open %s \n",bin_file);
    free(ram);
    assert(0);
  }

	// get size
	fp.seekg(0, fp.end);
	length = fp.tellg();
	fp.seekg(0, fp.beg);
  length = (length > size) ? size : length;

  // load bin
	if (fp.is_open()) {
		fp.read(ram, length);
	}
  printf("ram load ram %s\n",bin_file);
	fp.close();


  // override gcpt_restore
  if (enable_overr_gcpt) {
    ifstream gcpt(gcpt_bin_file,ios::binary);
    if (!gcpt) {
      printf("can not open %s \n",gcpt_bin_file);
      free(ram);
      assert(0);
    }
    // get size
    gcpt.seekg(0, gcpt.end);
    length = gcpt.tellg();
    gcpt.seekg(0, gcpt.beg);
    length = (length > size) ? size : length;

    // load bin
    if (gcpt.is_open()) {
      gcpt.read(ram, length);
    }

    printf("ram load gcpt %s, size %ld\n",gcpt_bin_file, gcpt.gcount());
    gcpt.close();
  }

  set_size = size;
  init_ok = true;
}
