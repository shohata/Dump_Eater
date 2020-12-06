import sys

n = 0
for l in sys.stdin:
  line = l.strip()
  if not line:
    if n % 4 == 1:
      print('00000000000000000000000000000000')
      print('00000000000000000000000000000000')
      print('00000000000000000000000000000000')
    elif n % 4 == 2:
      print('00000000000000000000000000000000')
      print('00000000000000000000000000000000')
    elif n % 4 == 3:
      print('00000000000000000000000000000000')
    n = 0
  else:
    byte = [line[i:i+2] if line[i:i+2] != '  ' else '00' for i in range (6, 6 + 16*3, 3)]
    print(''.join(byte[::-1]))
    n += 1
