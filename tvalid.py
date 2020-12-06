import sys

n = 0
for l in sys.stdin:
  line = l.strip()
  if n % 4 == 0 and line:
    print('1')
  n = n + 1 if line else 0

for i in range(0, 256):
  print('0')
