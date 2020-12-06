import sys

n = 0
for l in sys.stdin:
  line = l.strip()
  if not line:
    print('1')
    n = 0
  else:
    if n % 4 == 0 and n != 0:
      print('0')
    n += 1
