#!/usr/bin/python3

import sys

n = 0
for l in sys.stdin:
  line = l.strip()
  if n == 0:
    n = 1
    line0 = line
  else:
    n = 0
    print(line + line0)
