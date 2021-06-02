#include "common.h"

#define QUEUE_SIZE 1024
static char queue[QUEUE_SIZE] = {};
static int f = 0, r = 0;

static void uart_enqueue(char ch) {
  int next = (r + 1) % QUEUE_SIZE;
  if (next != f) {
    // not full
    queue[r] = ch;
    r = next;
  }
}

static int uart_dequeue(void) {
  int k = 0;
  if (f != r) {
    k = queue[f];
    f = (f + 1) % QUEUE_SIZE;
  } else {
    static int last = 0;
    k = "root\n"[last ++];
    if (last == 5) last = 0;
    // generate a random key every 1s for pal
    //k = -1;//"uiojkl"[rand()% 6];
  }
  return k;
}

uint8_t uart_getc() {
  static uint32_t lasttime = 0;

  uint8_t ch = -1;
  return ch;
}

void uart_putc(char c) {
  printf("%c", c);
  fflush(stdout);
}

static void preset_input() {
  char rtthread_cmd[128] = "memtrace\n";
  char init_cmd[128] = "2" // choose PAL
    "jjjjjjjkkkkkk" // walk to enemy
    ;
  char busybox_cmd[128] =
    "ls\n"
    "echo 123\n"
    "cd /root/benchmark\n"
    "ls\n"
    "./stream\n"
    "ls\n"
    "cd /root/redis\n"
    "ls\n"
    "ifconfig -a\n"
    "./redis-server\n";
  char debian_cmd[128] = "root\n";
  char *buf = debian_cmd;
  int i;
  for (i = 0; i < strlen(buf); i ++) {
    uart_enqueue(buf[i]);
  }
}

void init_uart(void) {
  preset_input();
}

