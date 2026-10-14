#!/usr/bin/env python3
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess


DIAGNOSTIC = re.compile(r'^\s*(?:\[[^\]]+\]\s*)*(?:ERROR|FATAL)\s*:', re.I)


def clock_rows(text):
    rows = {}
    for line in text.splitlines():
        fields = line.split()
        if len(fields) < 6 or not re.fullmatch(r'B\d+', fields[0]):
            continue
        try:
            frequency = float(fields[3])
        except ValueError as exc:
            raise RuntimeError('invalid offline clock row: ' + line) from exc
        name = fields[4]
        if name in rows and rows[name] != frequency:
            raise RuntimeError('inconsistent offline clock frequency: ' + name)
        rows[name] = frequency
    return rows


def validate_output(text, returncode):
    if returncode != 0:
        raise RuntimeError('offline runtime query exited with rc=' + str(returncode))
    for line in text.splitlines():
        if DIAGNOSTIC.search(line) or 'Error: in running command' in line:
            raise RuntimeError('offline runtime query failed: ' + line)
    if text.splitlines().count('OFFLINE_CLOCK_QUERY_SUCCESS') != 1:
        raise RuntimeError('offline runtime query has no unique success marker')
    sections = {}
    for kind in ['DEFAULT', 'CURRENT']:
        begin, end = 'CLOCK_' + kind + '_BEGIN', 'CLOCK_' + kind + '_END'
        if text.splitlines().count(begin) != 1 or text.splitlines().count(end) != 1:
            raise RuntimeError('offline runtime query missing exact clock table: ' + kind)
        sections[kind] = clock_rows(text.split(begin + '\n', 1)[1].split(end, 1)[0])
    defaults, current = sections['DEFAULT'], sections['CURRENT']
    for name in ['clk5_p', 'clk6_p']:
        if name not in defaults or name not in current:
            raise RuntimeError('offline runtime required clock absent: ' + name)
    if set(defaults) != set(current):
        raise RuntimeError('offline default and current clock inventories differ')
    for name, value in defaults.items():
        if not 0 < value < float('inf'):
            raise RuntimeError('invalid offline sign-off clock frequency: ' + name)
    return {'default_mhz': defaults, 'current_mhz': current,
            'hardware_actions': [], 'mode': 'explicit local offline runtime query'}


def validate_offline(database, work, settings):
    database, work = Path(database), Path(work)
    if database.is_symlink() or database.resolve(strict=True) != database:
        raise RuntimeError('offline runtime database must be canonical')
    compat = Path(settings['compat'])
    if compat.is_symlink() or hashlib.sha256(compat.read_bytes()).hexdigest() != settings['compat_sha256']:
        raise RuntimeError('offline runtime compatibility launcher identity changed')
    uv_root = Path(settings['uv_root'])
    if uv_root != Path('/nfs/tools/UVHS'):
        raise RuntimeError('offline validation requires the pinned local UVHS installation')
    work.mkdir(mode=0o700)
    script = work / 'query-defaults.tcl'
    if any(char in str(database) for char in '{}\r\n'):
        raise RuntimeError('offline runtime database path cannot be quoted safely')
    script.write_text('load_db -db {' + str(database) + '}\n'
                      'puts "CLOCK_DEFAULT_BEGIN"\nputs [query -clock -default -tclobj]\n'
                      'puts "CLOCK_DEFAULT_END"\nputs "CLOCK_CURRENT_BEGIN"\n'
                      'puts [query -clock -tclobj]\nputs "CLOCK_CURRENT_END"\n'
                      'puts "OFFLINE_CLOCK_QUERY_SUCCESS"\nexit\n')
    env = {key: os.environ[key] for key in ['HOME', 'USER', 'LOGNAME', 'SHELL', 'PATH', 'LANG', 'LC_ALL']
           if key in os.environ}
    env.update(UV_ROOT=str(uv_root), UV_LICENSE=settings['license'],
               XILINXD_LICENSE_FILE=settings['license'], LM_LICENSE_FILE=settings['license'],
               UVHS_LOCAL_ENV='/dev/null', UVHS_RUNTIME_LIB_DIR=str(work / 'libs'),
               UVSHELL_EXEC_NAME=str(compat), UV_ASLR_ON='1')
    command = ['bash', str(uv_root / 'bin/uv_shell'), '-t', 'runtime', '-d', 'U2', '-offline',
               '-workdir', str(work), '-script', str(script)]
    with (work / 'query-result.log').open('x') as log:
        done = subprocess.run(command, cwd=work, env=env, stdin=subprocess.DEVNULL,
                              stdout=log, stderr=subprocess.STDOUT, timeout=90)
    result = validate_output((work / 'query-result.log').read_text(errors='replace'), done.returncode)
    result.update(command=command, database=str(database), workdir=str(work))
    with (work / 'query-proof.json').open('x') as stream:
        stream.write(json.dumps(result, indent=2) + '\n')
    return result
