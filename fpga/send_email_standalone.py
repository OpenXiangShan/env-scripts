#! /usr/bin/env python3

import os
import sys
from send_email import send_email

title = sys.argv[1]
content = sys.argv[2]

send_email(title, content)
