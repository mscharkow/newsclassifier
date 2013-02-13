#!/usr/bin/env python
# Read every line, do something, output result
import fileinput
for line in fileinput.input():
    print len(line.split()) # Simple word count