from enum import Enum


class Node(Enum):
    L1I = 1
    L1D = 2
    L2  = 3
    L3  = 4
    PTW = 5
    MEM = 6


class Location(Enum):
    L2_L1I_0 = 0
    L2_L1D_0 = 1
    L3_L2_0  = 2
    MEM_L3   = 3
    L2_PTW_0 = 4


def up_node(loc):
    map = {
        0: Node.L1I,
        1: Node.L1D,
        2: Node.L2,
        3: Node.L3,
        4: Node.PTW
    }
    return map.get(loc)


def down_node(loc):
    map = {
        0: Node.L2,
        1: Node.L2,
        2: Node.L3,
        3: Node.MEM,
        4: Node.L2
    }
    return map.get(loc)


class Channel(Enum):
    A = 0
    B = 1
    C = 2
    D = 3


class Opcode_a(Enum):
    PutFullData    = 0
    PutPartialData = 1
    ArithmeticData = 2
    LogicalData    = 3
    Get            = 4
    Hint           = 5
    AcquireBlock   = 6
    AcquirePerm    = 7


class Opcode_b(Enum):
    Probe          = 6


class Opcode_c(Enum):
    ProbeAck       = 4
    ProbeAckData   = 5
    Release        = 6
    ReleaseData    = 7


class Opcode_d(Enum):
    AccessAck      = 0
    AccessAckData  = 1
    HintAck        = 2
    Grant          = 4
    GrantData      = 5
    ReleaseAck     = 6


class TxnState(Enum):
    Invalid  = 0
    Pending  = 1
    Finished = 2


class TxnType(Enum):
    ICacheGet = 1
    ICacheHint = 2
    DCacheAcquire = 3
    DCacheRelease = 4
    DCacheHint = 5
    L2Release = 6
    L3Release = 7
    L2Probe = 8
    L3Probe = 9