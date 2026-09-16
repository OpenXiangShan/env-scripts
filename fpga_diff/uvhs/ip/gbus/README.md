# UVHS GBus protected IP

This directory contains the protected GeneralBD and 256-bit GeneralBus release
artifacts required by the UVHS GBus flow. The DCPs are opaque vendor IP and are
not modified. The generated synthesis stubs retain the vendor interfaces while
omitting build-host metadata.

`uvhs/compilation/prepare_ip.sh` copies these fixed release assets into the
UVHS work directory. The applicable IP license and redistribution terms are
those of the UVHS vendor release.

| File | SHA-256 |
| --- | --- |
| `generalBD/generalBD.dcp` | `ce46fdc91cc7267916ace4bf84bbfb5d1b718d20f63810e35eb522f5f7653748` |
| `generalBD/generalBD_Stub.v` | `1c51fa52b9310e26a410cdd34765302efb5769dada6716c71b72506377fa1934` |
| `uvw_general_bus/uvw_general_bus.dcp` | `8acb76af84c6ab6c010d16c7dcccf06f3370576ca39dba1a0b1d5f3060bd82ce` |
| `uvw_general_bus/uvw_general_bus_Stub.v` | `290f51da48f5732e5ecec31e62fa4d76c4e2619e6ecd509bf0952d923209fd37` |
