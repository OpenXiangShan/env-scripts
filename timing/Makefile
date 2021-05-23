# vme arguments
ifdef VME_USR
VME_ARGS = -u $(VME_USR)
endif
ifdef VME_OUT
VME_ARGS += -o $(VME_OUT)
endif
ifdef VME_SOURCE
VME_ARGS += -s $(VME_SOURCE)
endif
ifdef VME_MODULES
VME_ARGS += -m $(VME_MODULES)
endif

ifdef help
VME_ARGS += -h
endif

vme:
	mill timing.runMain timing.VMETest $(VME_ARGS)

# tap arguments
ifdef TAP_SOURCE
TAP_ARGS = -s $(TAP_SOURCE)
endif
ifdef TAP_OUT
TAP_ARGS += -o $(TAP_OUT)
endif
ifdef TAP_CYCLE
TAP_ARGS += -c $(TAP_CYCLE)
endif
ifdef help
TAP_ARGS = -h
endif

#TODO: a script which
# 1. get all timing report paths in 199:/share/
# 2. if there exists an analysis file, then process it and put it there
tap:
	mill timing.runMain timing.TAPTest $(TAP_ARGS)

# tdp arguments
ifdef TDP_SOURCE
TDP_ARGS = -s $(TDP_SOURCE)
endif
ifdef TDP_SLACK
TDP_ARGS += --slack $(TDP_SLACK)
endif
ifdef help
TDP_ARGS = -h
endif

#TODO: a script which
# 1. get all timing report paths in 199:/share/
# 2. if there exists an detail file, then process it and put it there
tdp:
	mill timing.runMain timing.TDPTest $(TDP_ARGS)

help:
	mill timing.runMain timing.VMETest -h
	mill timing.runMain timing.TAPTest -h
	mill timing.runMain timing.TDPTest -h

.PHONY: vme tap tdp help
