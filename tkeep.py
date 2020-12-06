import sys

n = 0
for l in sys.stdin:
  line = l.strip()
  if not line:
    if n % 4 == 1:
      print('0000000000000000')
      print('0000000000000000')
      print('0000000000000000')
    elif n % 4 == 2:
      print('0000000000000000')
      print('0000000000000000')
    elif n % 4 == 3:
      print('0000000000000000')
    n = 0
  else:
    bit = ['1' if line[i*3+6:i*3+8] != '  ' else '0' for i in range (0, 16)]
    print(''.join(bit[::-1]))
    n += 1
