#include <common.h>
#include <iostream>
#include <fstream>
#include <stdlib.h>
#include "xs_MemRam.h"

using namespace std;
#define GCPT_MAX_SIZE 0x700

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
xs_MemRam::load_bin(char * bin_file)
{
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


static char bin_file[256] = "ram.bin";
static char gcpt_bin_file[256] = "gcpt.bin";
static bool enable_overr_gcpt = false;
static xs_MemRam *MemRam = NULL;
static bool init_ok = false;


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

  MemRam->load_bin(bin_file);
  printf("load bin_file %s\n",bin_file);

  // override gcpt-restore
  if (enable_overr_gcpt) {
    MemRam->load_bin(gcpt_bin_file);
    printf("ram override gcpt_bin_file %s\n",gcpt_bin_file);
  }

  init_ok = 1;
}

extern "C" void free_xs_ram() {
  MemRam->~xs_MemRam();
  delete MemRam;
}

