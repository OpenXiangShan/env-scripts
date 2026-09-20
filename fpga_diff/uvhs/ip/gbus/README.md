# UVHS GBus protected IP

This directory no longer stores vendor DCP binaries. `compilation/prepare_ip.sh`
builds the required checkpoints from the local UVHS installation:

- `uvw_general_bus` comes from `$UV_ROOT/platform/U2.2/Prototype/ips/uvw_gbus.3.1`.
  The optional GBus DiffTest hostif uses the vendor 256-bit AXI3 configuration;
  XDMA keeps the existing 64-bit generator used by the UVHS flash path.
- `generalBD` copies `$UV_ROOT/platform/U2.2/Prototype/ips/gbd/generalBD/generalBD.dcp`
  and wraps it with `$UV_ROOT/etc/auxtools/prepare_ip/prepare_ip.py`.

The applicable IP license and redistribution terms are those of the UVHS
vendor release. Generated DCP and stub files stay in the UVHS work directory.
