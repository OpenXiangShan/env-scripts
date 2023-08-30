from tl_const import *
from utils import *


class Record:
    def __init__(self, row):
        self.row = row
        self.channel = self.get_channel()
        self.opcode = self.get_opcode()
        self.location = self.get_location()
        self.time = self.get_time()
        self.address = self.get_address()

    def __str__(self):
        return "time: %9s address: 0x%x location: %10s channel: %1s opcode: %15s" % \
               (str(self.time), self.address, self.location.name, self.channel.name, self.opcode.name)

    def get_time(self):
        return self.row[13]

    def get_location(self):
        return Location[self.row[14]]

    def get_opcode(self):
        if (self.channel.value == 0):
            return Opcode_a(self.row[11])
        elif (self.channel.value == 1):
            return Opcode_b(self.row[11])
        elif (self.channel.value == 2):
            return Opcode_c(self.row[11])
        elif (self.channel.value == 3):
            return Opcode_d(self.row[11])
        # Ignore E channel response

    def get_channel(self):
        return Channel(self.row[12])

    def get_address(self):
        return self.row[7]

    def is_acquire(self):
        return self.channel == Channel.A and (self.opcode == Opcode_a.AcquirePerm or self.opcode == Opcode_a.AcquireBlock)

    def is_grant(self):
        return self.channel == Channel.D and (self.opcode == Opcode_d.Grant or self.opcode == Opcode_d.GrantData)

    def is_release(self):
        return self.channel == Channel.C and (self.opcode == Opcode_c.Release or self.opcode == Opcode_c.ReleaseData)

    def is_releaseack(self):
        return self.channel == Channel.D and self.opcode == Opcode_d.ReleaseAck

    def is_probe(self):
        return self.channel == Channel.B and self.opcode == Opcode_b.Probe

    def is_probeack(self):
        return self.channel == Channel.C and (self.opcode == Opcode_c.ProbeAck or self.opcode == Opcode_c.ProbeAckData)

    def is_get(self):
        return self.channel == Channel.A and self.opcode == Opcode_a.Get

    def is_accessack(self):
        return self.channel == Channel.D and (self.opcode == Opcode_d.AccessAck or self.opcode == Opcode_d.AccessAckData)

    def is_hint(self):
        return self.channel == Channel.A and self.opcode == Opcode_a.Hint

    def has_data(self):
        return self.channel == Channel.C and (self.opcode == Opcode_c.ProbeAckData or self.opcode == Opcode_c.ReleaseData) or \
               self.channel == Channel.D and (self.opcode == Opcode_d.GrantData or self.opcode == Opcode_d.AccessAckData)


class Transaction:
    def __init__(self, r: Record):
        self.state = TxnState.Pending
        self.records = [r]
        self.address = r.address
        if r.channel == Channel.B or r.is_hint():
            self.initNode = down_node(r.location.value)
        else:
            self.initNode = up_node(r.location.value)
        # print(self.initNode)
        self.byHint = r.is_hint()
        self.end_node = self.initNode

    def dump(self):
        for item in self.records:
            print(item)

    def len(self):
        return len(self.records)

    def get_top(self):
        return self.records[0]

    def append(self, new_r, last_r):
        self.records.append(new_r)
        if new_r.channel == Channel.C:
            self.end_node = down_node(new_r.location.value)
        else:
            self.end_node = up_node(new_r.location.value)
        if self.initNode == self.end_node:
            self.state = TxnState.Finished
        return True

    def merge(self, r):
        last_record = self.records[-1]

        if r.location == last_record.location:
            # new record should be response
            if r.is_grant() and last_record.is_acquire():
                return self.append(r, last_record)
            if r.is_accessack() and last_record.is_get():
                return self.append(r, last_record)
            if r.is_releaseack() and last_record.is_release():
                return self.append(r, last_record)
            if r.is_probeack() and last_record.is_probe():
                return self.append(r, last_record)
            return False
        else:
            # derived record
            if self.byHint:
                if r.is_grant():
                    return self.append(r, last_record)
                if r.is_hint():
                    # duplicated hint, ignore
                    return True
                if r.is_acquire() and down_node(r.location.value) != down_node(last_record.location.value):
                    # correct state
                    self.append(r, last_record)
                    self.state = TxnState.Pending
                    return True

            if r.channel == Channel.D:
                if (down_node(r.location.value) != up_node(last_record.location.value)):
                    return False
                assert down_node(r.location.value) == up_node(last_record.location.value)
            else:
                if up_node(r.location.value) != down_node(last_record.location.value):
                    return False
                assert up_node(r.location.value) == down_node(last_record.location.value)

            if (r.is_acquire() or r.is_get()) and (last_record.is_acquire() or last_record.is_get() or last_record.is_hint()):
                return self.append(r, last_record)
            if r.is_probe() and last_record.is_probe():
                return self.append(r, last_record)
            if (r.is_accessack() or r.is_grant()) and (last_record.is_grant() or last_record.is_accessack()):
                return self.append(r, last_record)
            return False
        # TODO: consider multiple probe
