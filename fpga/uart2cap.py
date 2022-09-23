
import sys
import serial
import os

class SERIAL_TYPE(object):
  def __init__(self, ip, port, baudrate, output):
    self.ip = ip
    self.serial = serial.Serial(
      port = port,
      baudrate = baudrate,
      parity=serial.PARITY_ODD, # 校验位
      stopbits=serial.STOPBITS_TWO, # 停止位
      bytesize=serial.SEVENBITS # 数据位
    )
    self.output = output

  def read_serial(self):
    if not os.path.isfile(self.output):
      os.popen(f"touch {self.output}")
    while True:
      data = self.serial.readline()
      file = open(self.output, 'a')
      file.writelines(data.decode('utf-8'))
      file.flush()
      file.close()



ser = SERIAL_TYPE(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
ser.read_serial()
