#!/usr/bin/env python3
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import stat
import tempfile


def digest(path):
    value = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            value.update(chunk)
    return value.hexdigest()


def publish_directory(source, destination):
    source = Path(source)
    destination = Path(destination)
    destination.mkdir(mode=0o700)
    reservation = destination.lstat()
    descriptor = os.open(destination, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)

    def transfer(directory, target):
        for child in sorted(directory.iterdir(), key=lambda path: (path.suffix == '.json', path.name)):
            mode = child.lstat().st_mode
            if stat.S_ISDIR(mode):
                os.mkdir(child.name, mode=0o700, dir_fd=target)
                nested = os.open(child.name, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=target)
                try:
                    transfer(child, nested)
                finally:
                    os.close(nested)
            elif stat.S_ISREG(mode):
                os.link(child, child.name, dst_dir_fd=target, follow_symlinks=False)
            else:
                raise RuntimeError('runtime publication input is not a regular file: ' + str(child))

    try:
        pinned = os.fstat(descriptor)
        if (pinned.st_dev, pinned.st_ino) != (reservation.st_dev, reservation.st_ino):
            raise RuntimeError('runtime destination reservation changed')
        transfer(source, descriptor)
        current = destination.lstat()
        if ((current.st_dev, current.st_ino) != (reservation.st_dev, reservation.st_ino)
                or not stat.S_ISDIR(current.st_mode)):
            raise RuntimeError('runtime destination reservation changed')
        shutil.rmtree(source)
    except BaseException:
        try:
            current = destination.lstat()
            if ((current.st_dev, current.st_ino) == (reservation.st_dev, reservation.st_ino)
                    and stat.S_ISDIR(current.st_mode)):
                destination.rmdir()
        except OSError:
            pass
        raise
    finally:
        os.close(descriptor)


def runtime_files(source):
    source = Path(source)
    if source.is_symlink() or source.resolve(strict=True) != source or not source.is_dir():
        raise RuntimeError('runtime source must be a canonical directory')
    selected = {}

    def collect(path, relative, ancestors=()):
        target = path.resolve(strict=True)
        if source != target and source not in target.parents:
            raise RuntimeError('runtime input escapes source database: ' + str(path))
        mode = target.stat().st_mode
        if stat.S_ISDIR(mode):
            if target in ancestors:
                raise RuntimeError('runtime directory link cycle: ' + str(path))
            for child in sorted(target.iterdir()):
                collect(child, relative / child.name, ancestors + (target,))
        elif stat.S_ISREG(mode):
            selected[str(relative)] = target
        else:
            raise RuntimeError('runtime input is not a regular file: ' + str(path))

    def optional(relative):
        path = source / relative
        if path.exists() or path.is_symlink():
            collect(path, Path(relative))

    for relative in ['DB/Options', 'DB/Linkage', 'DB/Sys_Design', 'DB/Names']:
        path = source / relative
        if not path.is_dir():
            raise RuntimeError('runtime metadata missing: ' + relative)
        collect(path, Path(relative))
    runtime = source / 'DB/Runtime/uvrtdb'
    for pattern in ['sec.*', 'runtime.*', '.runtime.*', 'uvrtdb.hash', 'mem.*',
                    'debug.*', 'fv', 'rtl2gate.*', 'signal', 'coord', 'rb']:
        for path in sorted(runtime.glob(pattern)):
            collect(path, path.relative_to(source))
    for relative in ['DB/Runtime/nocoord.rtdb', 'DB/Runtime/waveconvdb.dat',
                     'DB/Runtime/.waveconvdb.dat.dir', 'DB/Runtime/.waveconvdb.dat.config',
                     'Synthesis/Dpi/C', 'Synthesis/Hw_mem/Script/runtime_init.tcl',
                     'Synthesis/Hw_mem/Init']:
        optional(relative)
    if (source / 'Log/targetsystem.dcf').exists() or (source / 'Log/targetsystem.dcf').is_symlink():
        collect(source / 'Log/targetsystem.dcf', Path('DB/targetsystem.dcf'))
    bits = []
    for path in sorted((source / 'Compile/PnR').glob('B*/F*/MOD_b*_f*.bin')):
        relative = path.relative_to(source)
        board, fpga = path.parent.parent.name, path.parent.name
        if not re.fullmatch(r'B\d+', board) or not re.fullmatch(r'F\d+', fpga):
            raise RuntimeError('invalid runtime FPGA path: ' + str(relative))
        if path.name != 'MOD_b' + board[1:] + '_f' + fpga[1:] + '.bin':
            raise RuntimeError('bitstream identity does not match FPGA directory: ' + str(relative))
        collect(path, relative)
        target = selected[str(relative)]
        if not target.stat().st_size:
            raise RuntimeError('empty runtime bitstream: ' + str(relative))
        target_relative = target.relative_to(source)
        if target_relative != relative:
            collect(target, target_relative)
        bits.append(str(relative))
        optional(str(path.parent.relative_to(source) / (board + fpga + '.xml')))
    required = ['DB/Runtime/uvrtdb/uvrtdb.hash', 'DB/Runtime/uvrtdb/runtime.dat.zst',
                'DB/Runtime/uvrtdb/sec.dat', 'DB/Runtime/uvrtdb/mem.dat', 'DB/Names/name.db',
                'Compile/PnR/B0/F0/MOD_b0_f0.bin', 'Compile/PnR/B0/F1/MOD_b0_f1.bin',
                'Compile/PnR/B0/F2/MOD_b0_f2.bin']
    for name in required:
        if name not in selected or not selected[name].stat().st_size:
            raise RuntimeError('required runtime file missing or empty: ' + name)
    if len(selected) > 100000 or sum(path.stat().st_size for path in selected.values()) > 4 * 1024**3:
        raise RuntimeError('runtime package exceeds file count or byte limit')
    return selected, bits


def export_runtime(source, destination):
    source, destination = Path(source), Path(destination)
    if destination.exists() or destination.is_symlink():
        raise RuntimeError('runtime destination already exists: ' + str(destination))
    if not destination.is_absolute() or destination.parent.resolve(strict=True) != destination.parent:
        raise RuntimeError('runtime destination parent must be canonical')
    if source == destination or source in destination.parents:
        raise RuntimeError('runtime destination must be outside source database')
    selected, bits = runtime_files(source)
    temp = Path(tempfile.mkdtemp(prefix=destination.name + '.pending-', dir=destination.parent))
    try:
        (temp / 'DB/Names').mkdir(parents=True)
        (temp / 'Synthesis/Hw_mem/Script').mkdir(parents=True)
        hashes = {}
        resolved_inputs = {}
        for relative, target in sorted(selected.items()):
            if target.resolve(strict=True) != target:
                raise RuntimeError('runtime input path changed before copying: ' + relative)
            expected = digest(target)
            output = temp / relative
            output.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(target, output)
            if digest(output) != expected or digest(target) != expected:
                raise RuntimeError('runtime input changed while copying: ' + relative)
            hashes[relative] = expected
            resolved_inputs[relative] = str(target)
        current, current_bits = runtime_files(source)
        if current != selected or current_bits != bits:
            raise RuntimeError('runtime input selection changed while copying')
        for relative, target in current.items():
            if digest(target) != hashes[relative]:
                raise RuntimeError('runtime input changed after copying: ' + relative)
        publish_directory(temp, destination)
        return {'source': str(source), 'destination': str(destination), 'files': hashes,
                'resolved_inputs': resolved_inputs, 'bitstreams': bits,
                'bytes': sum((destination / name).stat().st_size for name in hashes),
                'contract': 'UVHS P4 extract_rtdb runtime/debug metadata including Name DB, selected links materialized internally'}
    except BaseException:
        if temp.exists():
            shutil.rmtree(temp)
        raise


def export_bundle(source, destination, proof):
    source, destination, proof = Path(source), Path(destination), Path(proof)
    bundle = destination.parent
    if (not destination.is_absolute() or proof.parent != bundle
            or proof.name == destination.name):
        raise RuntimeError('runtime proof must be a sibling of the package in a new bundle')
    if bundle.exists() or bundle.is_symlink():
        raise RuntimeError('runtime bundle already exists: ' + str(bundle))
    if bundle.parent.resolve(strict=True) != bundle.parent:
        raise RuntimeError('runtime bundle parent must be canonical')
    if source == bundle or source in bundle.parents:
        raise RuntimeError('runtime bundle must be outside source database')
    temp = Path(tempfile.mkdtemp(prefix=bundle.name + '.pending-', dir=bundle.parent))
    try:
        result = export_runtime(source, temp / destination.name)
        result['destination'] = str(destination)
        with (temp / proof.name).open('x') as stream:
            stream.write(json.dumps(result, indent=2) + '\n')
        publish_directory(temp, bundle)
        return result
    except BaseException:
        if temp.exists():
            shutil.rmtree(temp)
        raise


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--proof', type=Path, required=True)
    args = parser.parse_args()
    result = export_bundle(args.source, args.destination, args.proof)
    print(json.dumps({key: value for key, value in result.items() if key not in ('files', 'resolved_inputs')}))


if __name__ == '__main__':
    main()
