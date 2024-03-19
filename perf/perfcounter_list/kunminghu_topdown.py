import sys
import os
abs_path=os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(abs_path))
from calculation_base import Calculator

# performance counter selected for gcpt-perf-collection.py

# selected perf counter
# 0: key words of perf counter
# 1: name of perf counter
class CalculatorTopDown(Calculator):
  parse_map = [
    ["backend.ctrlBlock.dispatch: NoStall, ",              "NoStall", True],
    ["backend.ctrlBlock.dispatch: OverrideBubble, ",       "OverrideBubble", True],
    ["backend.ctrlBlock.dispatch: FtqUpdateBubble, ",      "FtqUpdateBubble", True],
    ["backend.ctrlBlock.dispatch: TAGEMissBubble, ",       "TAGEMissBubble", True],
    ["backend.ctrlBlock.dispatch: SCMissBubble, ",         "SCMissBubble", True],
    ["backend.ctrlBlock.dispatch: ITTAGEMissBubble, ",     "ITTAGEMissBubble", True],
    ["backend.ctrlBlock.dispatch: RASMissBubble, ",        "RASMissBubble", True],
    ["backend.ctrlBlock.dispatch: MemVioRedirectBubble, ", "MemVioRedirectBubble", True],
    ["backend.ctrlBlock.dispatch: OtherRedirectBubble, ",  "OtherRedirectBubble", True],
    ["backend.ctrlBlock.dispatch: FtqFullStall, ",         "FtqFullStall", True],
    ["backend.ctrlBlock.dispatch: ICacheMissBubble, ",     "ICacheMissBubble", True],
    ["backend.ctrlBlock.dispatch: ITLBMissBubble, ",       "ITLBMissBubble", True],
    ["backend.ctrlBlock.dispatch: BTBMissBubble, ",        "BTBMissBubble", True],
    ["backend.ctrlBlock.dispatch: FetchFragBubble, ",      "FetchFragBubble", True],
    ["backend.ctrlBlock.dispatch: DivStall, ",             "DivStall", True],
    ["backend.ctrlBlock.dispatch: IntNotReadyStall, ",     "IntNotReadyStall", True],
    ["backend.ctrlBlock.dispatch: FPNotReadyStall, ",      "FPNotReadyStall", True],
    ["backend.ctrlBlock.dispatch: MemNotReadyStall, ",     "MemNotReadyStall", True],
    ["backend.ctrlBlock.dispatch: IntFlStall, ",           "IntFlStall", True],
    ["backend.ctrlBlock.dispatch: FpFlStall, ",            "FpFlStall", True],
    ["backend.ctrlBlock.dispatch: IntDqStall, ",           "IntDqStall", True],
    ["backend.ctrlBlock.dispatch: FpDqStall, ",            "FpDqStall", True],
    ["backend.ctrlBlock.dispatch: LsDqStall, ",            "LsDqStall", True],
    ["backend.ctrlBlock.dispatch: LoadTLBStall, ",         "LoadTLBStall", True],
    ["backend.ctrlBlock.dispatch: LoadL1Stall, ",          "LoadL1Stall", True],
    ["backend.ctrlBlock.dispatch: LoadL2Stall, ",          "LoadL2Stall", True],
    ["backend.ctrlBlock.dispatch: LoadL3Stall, ",          "LoadL3Stall", True],
    ["backend.ctrlBlock.dispatch: LoadMemStall, ",         "LoadMemStall", True],
    ["backend.ctrlBlock.dispatch: StoreStall, ",           "StoreStall", True],
    ["backend.ctrlBlock.dispatch: AtomicStall, ",          "AtomicStall", True],
    ["backend.ctrlBlock.dispatch: LoadVioReplayStall, ",   "LoadVioReplayStall", True],
    ["backend.ctrlBlock.dispatch: LoadMSHRReplayStall, ",  "LoadMSHRReplayStall", True],
    ["backend.ctrlBlock.dispatch: ControlRecoveryStall, ", "ControlRecoveryStall", True],
    ["backend.ctrlBlock.dispatch: MemVioRecoveryStall, ",  "MemVioRecoveryStall", True],
    ["backend.ctrlBlock.dispatch: OtherRecoveryStall, ",   "OtherRecoveryStall", True],
    ["backend.ctrlBlock.dispatch: FlushedInsts, ",         "FlushedInsts", True],
    ["backend.ctrlBlock.dispatch: OtherCoreStall, ",       "OtherCoreStall", True],
    # ["backend.ctrlBlock.dispatch: NumStallReasons, ",      "NumStallReasons", True],
  ]