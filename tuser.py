import sys

# TUSER[15:0]:    length of the packet in bytes
# TUSER[23:16]:   source port: identifies the port at which the packet was received. Note that each port is one-hot, _i.e._ encoded as an individual bit (and a maximum of 8ports is supported.)
# TUSER[31:24]:   destination port: identifies the port from which the packet is to be transmitted. Note one-hot encoding, and that multicast is possible as each port is associated with each bit. (A maximum of 8 ports is supported.)
# TUSER[47:32]:   user definable meta data slot 0
# TUSER[63:48]:   user definable meta data slot 1
# TUSER[79:64]:   user definable meta data slot 2
# TUSER[95:80]:   user definable meta data slot 3
# TUSER[111:96]:  user definable meta data slot 4
# TUSER[127:112]: user definable meta data slot 5

n = 0
length = 0
for l in sys.stdin:
  line = l.strip()
  if not line:
    byte = '0000000000000000000000000201' + format(length, '04x')
    for i in range((n + 1)//2):
      print(byte)
    if (n + 1)//2 % 2 == 1:
      print('00000000000000000000000000000000')
    n = 0
    length = 0
  else:
    for i in range (6, 6 + 16*3, 3):
      if line[i:i+2] != '  ':
        length += 1
    n += 1
