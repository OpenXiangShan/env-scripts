#!/usr/bin/env python3
from pathlib import Path
import datetime
import json
import os
import re
import shlex
import subprocess
import sys
import time

from uvhs_build_complete import read_make_result


REMOTE = r'''
from pathlib import Path
import hashlib, json, sys
owner = json.loads(sys.argv[1])
path = Path('/proc') / str(owner['pid'])
try:
    fields = (path / 'stat').read_text().rsplit(')', 1)[1].split()
    status = dict(line.split(':', 1) for line in (path / 'status').read_text().splitlines() if ':' in line)
    actual = {'starttime': fields[19], 'uid': int(status['Uid'].split()[0]),
              'cwd': str((path / 'cwd').resolve()),
              'argv': [v.decode(errors='replace') for v in (path / 'cmdline').read_bytes().split(b'\0')[:-1]],
              'script_sha256': hashlib.sha256(Path(owner['script']).read_bytes()).hexdigest()}
    valid = all(actual[key] == owner[key] for key in actual)
    print(json.dumps({'state': 'live' if valid and fields[0] != 'Z' else 'identity_mismatch', 'actual': actual}))
except (FileNotFoundError, ProcessLookupError):
    print(json.dumps({'state': 'gone'}))
except Exception as exc:
    print(json.dumps({'state': 'unknown', 'error': str(exc)}))
'''


def atomic(path, value):
    temp = path.with_name(path.name + '.tmp')
    temp.write_text(json.dumps(value, indent=2) + '\n')
    os.replace(temp, path)


def log_tail(path):
    if not path.exists():
        return ''
    with path.open('rb') as stream:
        stream.seek(0, 2)
        size = stream.tell()
        stream.seek(max(0, size - 65536))
        data = stream.read().decode(errors='replace')
    return data.split('\n', 1)[1] if size > 65536 and '\n' in data else data


def evaluate(root, worker, now=None):
    complete = root / 'completion-result.json'
    if complete.is_file():
        value = json.loads(complete.read_text())
        return {'event': 'completion_callback_observed', 'action': value.get('action'),
                'completion_event': value.get('event'),
                'debug_hook_triggered': value.get('debug_hook_triggered', False),
                'terminal': True}
    result = root / 'make-result.json'
    try:
        value = read_make_result(result, 0)
        modified = result.stat().st_mtime if value is not None else None
    except (OSError, ValueError, RuntimeError) as exc:
        return {'event': 'build_monitor_alert', 'action': 'inspect_invalid_make_result',
                'error': 'Invalid atomic make result: ' + str(exc),
                'debug_hook_triggered': False, 'terminal': True}
    if value is not None:
        if value['make_rc'] != 0:
            return {'event': 'build_failure_repair', 'action': 'inspect_and_fix_build',
                    'make_rc': value['make_rc'], 'debug_hook_triggered': False, 'terminal': True}
        elapsed = (time.time() if now is None else now) - modified
        if elapsed > 1800:
            return {'event': 'build_monitor_alert', 'action': 'inspect_completion_validator',
                    'error': 'Successful make has no completed artifact validation after 30 minutes',
                    'debug_hook_triggered': False, 'terminal': True}
        return {'event': 'build_monitor_active', 'action': 'wait_for_success_validation',
                'build_state': 'validating', 'debug_hook_triggered': False, 'terminal': False}
    project = Path(json.loads((root / 'source-inputs.json').read_text())['project'])
    for path in [root / 'build-node004.log', project / 'frontend_run.log', project / 'backend_run.log']:
        tail = log_tail(path)
        failures = [line for line in tail.splitlines()
                    if re.search(r'^make(?:\[\d+\])?: \*\*\* .*Error [1-9]\d*', line)]
        if failures:
            return {'event': 'build_failure_repair', 'action': 'inspect_owned_build_and_fix_after_exit',
                    'error': failures[-1], 'log': str(path),
                    'debug_hook_triggered': False, 'terminal': True}
    state = worker.get('state', 'unknown')
    if state != 'live':
        return {'event': 'build_monitor_alert', 'action': 'inspect_remote_state_before_any_retry',
                'error': 'Owned queue/build worker is not proven live: ' + state,
                'worker': worker, 'debug_hook_triggered': False, 'terminal': True}
    return {'event': 'build_monitor_active', 'action': 'observe_current_build',
            'build_state': 'building' if (root / 'build-start.json').exists() else 'queued',
            'debug_hook_triggered': False, 'terminal': False}


def probe(host, owner):
    command = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
               '-o', 'ServerAliveInterval=10', '-o', 'ServerAliveCountMax=2',
               host, 'python3 - ' + shlex.quote(json.dumps(owner))]
    try:
        done = subprocess.run(command, input=REMOTE, text=True, capture_output=True, timeout=45)
        if done.returncode:
            return {'state': 'unknown', 'error': 'SSH rc=' + str(done.returncode) + ': ' + done.stderr[-1000:]}
        return json.loads(done.stdout)
    except (subprocess.TimeoutExpired, ValueError) as exc:
        return {'state': 'unknown', 'error': str(exc)}


def main(root):
    owner = json.loads((root / 'monitor-identity.json').read_text())
    host = json.loads((root / 'source-inputs.json').read_text())['host']
    start = {'started_at': datetime.datetime.now().astimezone().isoformat(),
             'pid': os.getpid(), 'kind': 'one-shot build failure observer',
             'schedule': 'none', 'can_launch_or_stop_compilers': False}
    atomic(root / 'failure-monitor-start.json', start)
    while True:
        worker = probe(host, owner)
        result = evaluate(root, worker)
        result.update(checked_at=datetime.datetime.now().astimezone().isoformat(),
                      hardware_actions=[], compiler_actions=[])
        atomic(root / 'failure-monitor-state.json', result)
        if result['terminal']:
            atomic(root / 'failure-monitor-result.json', result)
            print('BUILD_FAILURE_MONITOR_NOTIFICATION ' + json.dumps(result), flush=True)
            return 0 if result['event'] == 'completion_callback_observed' else 1
        time.sleep(30)


if __name__ == '__main__':
    sys.exit(main(Path(sys.argv[1])))
