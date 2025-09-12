import re
import sys

src = open(sys.argv[1]).read()

filtered = re.sub(r"/\*.*?\*/", '', src, flags=re.S)

if filtered == src:
  print('???');

open(sys.argv[2], 'w').write(filtered)
