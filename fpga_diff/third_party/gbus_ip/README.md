# Bundled UVHS GBus IP

This directory contains the protected-IP release artifacts used by the optional
`DIFFTEST_HOSTIF=GBUS` UVHS flow:

* `uvw_general_bus/` is generated from the official U2.2 `uvw_gbus.3.1`
  generator with the repository's `uvw_axi3_generalbus.json` settings and
  Vivado 2024.2, part `xcvu19p-fsva3824-2-e`.
* `generalBD/` is the official U2.2 GeneralBD DCP and synthesis stub.

The DCPs are opaque vendor IP and are not modified. Their SHA-256 values are
checked by `install/check_gbus_ip.sh` and again when `make uvhs_generate_gbus_ip`
stages them into a generated UVHS project. The corresponding generator and
example are installed under `/nfs/tools/UVHS`; the bundled copies make a
checkout reproducible without requiring that installation at build time.

The IP license and redistribution terms are those of the UVHS vendor release.
