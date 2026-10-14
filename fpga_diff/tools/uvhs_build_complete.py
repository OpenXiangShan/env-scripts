#!/usr/bin/env python3
from pathlib import Path
import datetime
import importlib.util
import json
import os
import stat
import subprocess
import sys
import time

from uvhs_build_artifacts import validate_build_logs
from uvhs_runtime_package import digest, export_bundle
from uvhs_runtime_validate import validate_offline


def read_make_result(path, wait_seconds):
    deadline = time.monotonic() + wait_seconds
    while True:
        try:
            descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        except FileNotFoundError:
            if time.monotonic() >= deadline:
                return None
            time.sleep(0.5)
            continue
        with os.fdopen(descriptor) as stream:
            if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode):
                raise RuntimeError('make result is not a regular file')
            result = json.load(stream)
        if not isinstance(result, dict) or type(result.get('make_rc')) is not int or not 0 <= result['make_rc'] <= 255:
            raise RuntimeError('make result has no valid integer return code')
        return result


def validate(root, ssh_rc, output_root=None, offline_settings=None):
    root = Path(root)
    output_root = root if output_root is None else Path(output_root)
    inputs = json.loads((root / 'source-inputs.json').read_text())
    result = {'completed_at': datetime.datetime.now().astimezone().isoformat(),
              'ssh_rc': ssh_rc, 'build_state': 'unknown', 'action': 'inspect_build_failure',
              'project': inputs['project'], 'log': str(root / 'build-node004.log'),
              'notification': 'Bash background completion callback', 'hardware_actions': [],
              'event': 'build_monitor_alert', 'debug_hook_triggered': False,
              'debug_allowed': False, 'repair_required': True}
    try:
        wait = inputs.get('make_result_wait_seconds', 30) if ssh_rc == 0 else 0
        if type(wait) not in (int, float) or not 0 <= wait <= 60:
            raise RuntimeError('make result wait must be between zero and 60 seconds')
        make = read_make_result(root / 'make-result.json', wait)
    except (OSError, ValueError, RuntimeError) as exc:
        result['error'] = 'Invalid atomic make result: ' + str(exc)
        return result
    if make is None:
        result['error'] = 'No atomic make result; remote build state must be checked before any retry'
        return result
    result['make_rc'] = make['make_rc']
    if make['make_rc'] != 0 or ssh_rc != 0:
        result['build_state'] = 'failed' if make['make_rc'] != 0 else 'unknown'
        if make['make_rc'] != 0:
            result['event'] = 'build_failure_repair'
        result['error'] = 'Build or SSH did not complete successfully'
        return result
    try:
        project = Path(inputs['project'])
        for rel, expected in inputs['source_files'].items():
            path = root / 'sources' / rel
            if path.is_symlink() or digest(path) != expected:
                raise RuntimeError('Source changed during build: ' + rel)
        for name, expected in inputs['external_files'].items():
            if digest(Path(name)) != expected:
                raise RuntimeError('External input changed during build: ' + name)
        validate_build_logs(project)
        database = project / 'hw.dat'
        bits = {}
        for fpga in ['F0', 'F1', 'F2']:
            path = database / 'Compile/PnR/B0' / fpga / ('MOD_b0_' + fpga.lower() + '.bin')
            target = path.resolve(strict=True)
            if database not in target.parents or not target.is_file() or not target.stat().st_size:
                raise RuntimeError('Missing internal new bitstream: ' + fpga)
            value = digest(target)
            if value in inputs['old_bitstream_hashes'].values():
                raise RuntimeError('Bitstream equals known failed old design: ' + fpga)
            bits[fpga] = {'path': str(path), 'bytes': target.stat().st_size, 'sha256': value}
        export = output_root / 'runtime-export'
        package = export_bundle(database, export / 'hw.dat', export / 'package-proof.json')
        files = {}
        for path in sorted((export / 'hw.dat').rglob('*')):
            if path.is_symlink():
                raise RuntimeError('Symlink in exported runtime package: ' + str(path))
            if path.is_file():
                files[str(path.relative_to(export / 'hw.dat'))] = digest(path)
            elif not path.is_dir():
                raise RuntimeError('Special file in exported runtime package: ' + str(path))
        if files != package['files']:
            raise RuntimeError('Exported runtime package changed after copy')
        settings = inputs['offline_validation'] if offline_settings is None else offline_settings
        clock_proof = validate_offline(export / 'hw.dat', output_root / 'offline-runtime-check', settings)
        manifest = output_root / 'runtime-manifest.json'
        with manifest.open('x') as stream:
            stream.write(json.dumps(files, indent=2) + '\n')
        result.update(build_state='verified', action='check_board_health',
                      bitstreams=bits, runtime_manifest=str(manifest), runtime_files=len(files),
                      runtime_package_dir=str(export / 'hw.dat'),
                      offline_runtime_validation=clock_proof,
                      event='synthesis_success_debug_hook', debug_hook_triggered=True,
                      repair_required=False)
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.TimeoutExpired) as exc:
        result.update(build_state='invalid_artifacts', event='build_artifact_failure_repair', error=str(exc))
    return result


def finish(root, ssh_rc, output_root=None, offline_settings=None):
    root = Path(root)
    output_root = root if output_root is None else Path(output_root)
    result = validate(root, ssh_rc, output_root, offline_settings)
    if result['build_state'] == 'verified':
        try:
            inputs = json.loads((root / 'source-inputs.json').read_text())
            helper = Path(inputs['health_helper'])
            if digest(helper) != inputs['health_helper_sha256']:
                raise RuntimeError('Health helper changed; independently verify before board actions')
            spec = importlib.util.spec_from_file_location('gbus_completion_health', helper)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            state = module.Remote('root@172.38.11.85', Path.home() / '.ssh/id_rsa').call('board')
            (output_root / 'completion-board-health.json').write_text(json.dumps(state, indent=2) + '\n')
            if state.get('board', {}).get('state') != 'free' or state.get('transport', {}).get('state') != 'healthy':
                result['action'] = 'debug_blocked_board_health'
            else:
                try:
                    module.require_live_transport_contract()
                except RuntimeError as exc:
                    result.update(action='debug_blocked_transport_contract', transport_contract_error=str(exc))
                else:
                    result['action'] = 'begin_manifest_and_health_gated_debug'
                    result['debug_allowed'] = True
            result['board_state'] = state.get('board', {}).get('state', 'unknown')
            result['transport_state'] = state.get('transport', {}).get('state', 'unknown')
        except Exception as exc:
            result.update(action='debug_blocked_unknown_health', health_error=str(exc))
    temp = output_root / 'completion-result.json.tmp'
    temp.write_text(json.dumps(result, indent=2) + '\n')
    os.replace(temp, output_root / 'completion-result.json')
    label = 'SYNTHESIS_SUCCESS_DEBUG_HOOK' if result['debug_hook_triggered'] else 'BUILD_MONITOR_REPAIR_ALERT'
    print(label + ' ' + json.dumps(result), flush=True)
    return 0 if result['build_state'] == 'verified' else 1


if __name__ == '__main__':
    sys.exit(finish(Path(sys.argv[1]), int(sys.argv[2])))
