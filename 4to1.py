#!/usr/bin/python3

import sys

n = 0
for l in sys.stdin:
  line = l.strip()
  if n == 0:
    line0 = line
  elif n == 1:
    line1 = line
  elif n == 2:
    line2 = line
  else:
    print(line + line2 + line1 + line0)
    n = -1
  n += 1
