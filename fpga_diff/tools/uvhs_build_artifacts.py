#!/usr/bin/env python3
from pathlib import Path
import re


DIAGNOSTIC = re.compile(
    r'^\s*(?:\[[A-Z][A-Z0-9]*-\d+\]\s*)?(?:ERROR|FATAL)\s*:', re.I)
CLOCK_FAILURE = re.compile(r'\[TCK-(?:104|123)\]|Error: in running command', re.I)


def validate_build_logs(project):
    project = Path(project)
    for filename, markers in [
        ('frontend_run.log', ['UVHS_FRONTEND_SUCCESS']),
        ('backend_run.log', ['UVHS_CLOCK_INFERENCE_SUCCESS',
                             'UVHS_CLOCK_TRANSFORM_SUCCESS', 'UVHS_BACKEND_SUCCESS']),
    ]:
        path = project / filename
        if path.is_symlink() or not path.is_file():
            raise RuntimeError('missing regular build log: ' + filename)
        found = []
        with path.open(errors='replace') as stream:
            for number, line in enumerate(stream, 1):
                text = line.rstrip('\r\n')
                if DIAGNOSTIC.search(text) or CLOCK_FAILURE.search(text):
                    raise RuntimeError('{}:{}: {}'.format(filename, number, text[:1000]))
                if text in markers:
                    found.append(text)
        if found != markers:
            raise RuntimeError('missing, repeated or out-of-order success markers in ' + filename)
