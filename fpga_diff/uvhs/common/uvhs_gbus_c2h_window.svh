// GBD1 streaming frame ring geometry, shared by every block that has to
// recognise the ring's address range.
//
// The host learns the base and size from 0x1210/0x1214, but the read router,
// the write guard and the config-window decode each carry their own copy of
// the range.  Keeping the copy in one place is what stops them drifting: the
// ring moved from a 256 KiB window at 0x0ffc_0000 to a 768 KiB window at
// 0x0ff4_0000, and a stale copy silently sends host frame reads to the DDR
// instead of the FIFO.
`ifndef UVHS_GBUS_C2H_WINDOW_SVH
`define UVHS_GBUS_C2H_WINDOW_SVH
`define UVHS_C2H_FRAMES       1024
`define UVHS_C2H_FRAME_BEATS  24
`define UVHS_C2H_BEAT_BYTES   32
`define UVHS_C2H_APERTURE     32'h0ff4_0000
`define UVHS_C2H_RING_BYTES   (`UVHS_C2H_FRAMES * `UVHS_C2H_FRAME_BEATS * `UVHS_C2H_BEAT_BYTES)
// Last byte of the ring; it ends exactly at the 0x1000_0000 top of port 0.
`define UVHS_C2H_WINDOW_LAST  (`UVHS_C2H_APERTURE + `UVHS_C2H_RING_BYTES - 1)
// First and last config-window registers the streaming engine decodes.
`define UVHS_C2H_CFG_FIRST    16'h1200
`define UVHS_C2H_CFG_LAST     16'h1254
`endif
