#!/usr/bin/env python

from __future__ import print_function

import numpy as np
import sys

inlines = sys.stdin.readlines()

runtimes = []

for s in inlines:
    if s:
        runtimes.append(int(s.strip()))

mean = np.mean(runtimes)
std = np.std(runtimes)

print(" {:.2f} {:.2f}".format(mean, std), end='')
