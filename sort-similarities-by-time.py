import sys
import os
import os.path, time

a = None
b = None

for line in sys.stdin:
    line = line.strip()
    if line:
        if not a:
            a = line
        else:
            b = line
            if os.path.getctime(a) > os.path.getctime(b):
                a, b = b, a
            print(a)
            print(b)
            print('')
            a = None
            b = None

