'''Partitions a device using a YAML file.'''
import argparse
import math
import os
from pathlib import Path
import subprocess
import sys
import time

from jsonschema.exceptions import ValidationError
import yaml

from common import (LUKS_PASSPHRASE, PARTITIONS_FILE, PARTITIONS_SCHEMA, UTF8, Colors,
                    CommandNotFoundError, DeviceNotFoundError, get_dev_path, handle_error,
                    parse_yaml)

UNIT_SYSTEM = {
    **dict.fromkeys(['B', 'KiB', 'MiB', 'GiB', 'TiB'], 1024),
    **dict.fromkeys(['KB', 'MB', 'GB', 'TB'], 1000)
}
MKFS_CMD = {
    'ext2': ['mkfs.ext2'],
    'ext3': ['mkfs.ext3'],
    'ext4': ['mkfs.ext4'],
    'xfs': ['mkfs.xfs'],
    'btrfs': ['mkfs.btrfs'],
    'reiserfs': ['mkreiserfs'],
    'fat12': ['mkfs.fat', '-F', '12'],
    'fat16': ['mkfs.fat', '-F', '16'],
    'fat32': ['mkfs.fat', '-F', '32']
}


class InvalidUnitError(Exception):
    '''Exception raised when an invalid unit was specified.'''
    def __init__(self, message: str) -> None:
        super().__init__(message)


def main() -> None:
    '''The main entrypoint of the script.'''
    args = parse_args()
    if os.geteuid() != 0:
        handle_error(error='run as root')

    try:
        config = parse_yaml(args.file, schema=PARTITIONS_SCHEMA)
        dev_path = get_dev_path(config.get('device'))
        display_partitions(dev_path)
        if args.what_if:
            display_changes(config, dev_path)
            sys.exit()

        partition_dev(config, dev_path)
        format_partition(config, dev_path)
    except yaml.YAMLError as exc:
        if hasattr(exc, 'problem_mark'):
            error = f'{exc.problem}\n{exc.problem_mark}'
        else:
            error = exc

        handle_error(error)
    except FileNotFoundError as exc:
        handle_error(error=f'no such file or directory: {exc.filename}')
    except ValidationError as exc:
        handle_error(error=exc.message)
    except (DeviceNotFoundError, CommandNotFoundError, InvalidUnitError, ValueError) as exc:
        handle_error(error=exc)
    except subprocess.CalledProcessError as exc:
        handle_error()


def parse_args() -> argparse.Namespace:
    '''Parse command line arguments.'''
    parser = argparse.ArgumentParser(description='Partitions a device from a YAML file.')
    parser.add_argument('-f', '--file',
                        default=PARTITIONS_FILE,
                        help=f'reads from FILE instead of {os.path.basename(PARTITIONS_FILE)}')
    parser.add_argument('--what-if',
                        action='store_true',
                        help='displays a preview of the operations to perform')
    args = parser.parse_args()
    return args


def display_partitions(dev_path: str) -> None:
    '''
    Display partition table of device.

    Parameters
        dev_path: str
            Path of the device to display the partition table.
    '''
    try:
        subprocess.run(['parted', '--script', dev_path, 'print'], check=True)
    except FileNotFoundError as exc:
        raise CommandNotFoundError(f'command not found: {exc.filename}') from exc


def display_changes(config: dict, dev_path: str) -> None:
    '''
    Display changes that will be performed on the device.

    Parameters
        config: dict
            Config used to partition the device.
        dev_path: str
            Path of the device to partition.
    '''
    print(f'{Colors.YELLOW}Device will be wiped and formatted:{Colors.RESET}\n'
          f'Partition Table: {Colors.BLUE}{config.get("partitionScheme")}{Colors.RESET}')

    dev = dev_path.replace('/dev/', '')
    unit = config.get('unit')
    partitions = config.get('partitions', {})
    for partition_name in partitions:
        partition = partitions.get(partition_name, {})
        start = to_bytes(size=partition.get('start'), size_unit=unit)
        end = partition.get('end')
        if end == -1:
            with Path(f'/sys/block/{dev}/size').open(mode='r', encoding=UTF8) as file:
                end = 512 * int(file.read())
        else:
            end = to_bytes(size=end, size_unit=unit)

        size, unit = convert_size(size_bytes=end - start, size_unit=unit)
        print(f'Partition {partition.get("number")}\n'
              f'  Name: {Colors.BLUE}{partition_name}{Colors.RESET}\n'
              f'  Filesystem: {Colors.BLUE}{partition.get("filesystem")}{Colors.RESET}\n'
              f'  Start: {Colors.BLUE}{partition.get("start")}{Colors.RESET}\n'
              f'  End: {Colors.BLUE}{partition.get("end")}{Colors.RESET}\n'
              f'  Size: {Colors.BLUE}{size} {unit}{Colors.RESET}')


def to_bytes(size: int, size_unit: str) -> int:
    '''
    Converts size to bytes from the specified unit.

    Parameters
        size: int
            The size to convert to bytes.
        size_unit: str
            The unit that the size is being converted from.
    '''
    try:
        unit = UNIT_SYSTEM[size_unit]
    except KeyError as exc:
        raise InvalidUnitError(f'invalid unit {size_unit}') from exc

    units = {
        'B': 1,
        'K': unit,
        'M': unit**2,
        'G': unit**3,
        'T': unit**4
    }

    return size * units.get(size_unit[0])


def convert_size(size_bytes: int, size_unit: str) -> tuple[int, str]:
    '''
    Converts bytes into appropriate unit for readability.

    Parameters
        size_bytes: int
            Size in bytes to convert to the appropriate unit.
        size_unit: str
            The original unit being used to parition the device.
    '''
    try:
        unit = UNIT_SYSTEM[size_unit]
    except KeyError as exc:
        raise InvalidUnitError(f'invalid unit {size_unit}') from exc

    i = int(math.floor(math.log(size_bytes, unit)))
    size = int(round(size_bytes / math.pow(unit, i), 2))
    units = ('B', 'K', 'M', 'G', 'T')
    if i == 0:
        suffix = ''
    elif unit == 1024:
        suffix = 'iB'
    elif unit == 1000:
        suffix = 'B'

    return (size, f'{units[i]}{suffix}')


def partition_dev(config: dict, dev_path: str) -> None:
    '''
    Partitions a device using a config parsed from a YAML file.

    Parameters:
        config: dict
            Config used to partition the device.
        dev_path: str
            Path of the device to partition.
    '''
    unmount_dev(dev_path)
    partition_scheme = config.get('partitionScheme')
    unit = config.get('unit')
    cmd = ['parted', '--script', '--align', 'optimal', dev_path,
           'mklabel', partition_scheme, 'unit', unit]
    partitions = config.get('partitions', {})
    for partition_name in partitions:
        partition = partitions.get(partition_name, {})
        cmd.extend(['mkpart', partition_name, partition.get('filesystem'),
                    str(partition.get('start'))])
        end = partition.get('end')
        if end == -1:
            cmd.append('--')

        cmd.append(str(end))
        for flag in partition.get('flags', []):
            cmd.extend(['set', str(partition.get('number')), flag, 'on'])

    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError as exc:
        raise CommandNotFoundError(f'command not found: {exc.filename}') from exc


def unmount_dev(dev_path: str) -> None:
    '''
    Unmounts all filesystems from a given device.

    Parameters
        dev_path: str
            Path of the device to unmount.
    '''
    try:
        proc = subprocess.run(['lsblk', dev_path, '--noheadings', '--raw',
                               '--output', 'MOUNTPOINT'], check=True, capture_output=True)
        for mount in proc.stdout.decode().strip().splitlines():
            subprocess.run(['umount', mount], check=True)
    except FileNotFoundError as exc:
        raise CommandNotFoundError(f'command not found: {exc.filename}') from exc


def format_partition(config: dict, dev_path: str) -> None:
    '''
    Formats a partition with the specified filesystem.

    Parameters:
        config: dict
            Config used to format the partition.
        dev_path: str
            Path of the device where the partitions exist.
    '''
    partitions = config.get('partitions', {})
    for partition_name in partitions:
        partition = partitions.get(partition_name, {})
        partition_path = f'{dev_path}{partition.get("number")}'
        encrypted = partition.get('encrypted')
        if encrypted:
            encrypt_partition(partition_path, partition_name,
                              passphrase=os.environ.get(LUKS_PASSPHRASE))
            partition_path = f'/dev/mapper/{partition_name}'

        cmd = MKFS_CMD.get(partition.get('filesystem'))
        cmd.append(partition_path)

        try:
            subprocess.run(cmd, check=True)
            if encrypted:
                time.sleep(5)
                subprocess.run(['cryptsetup', 'close', partition_name], check=True)
        except FileNotFoundError as exc:
            raise CommandNotFoundError(f'command not found: {exc.filename}') from exc


def encrypt_partition(partition_path: str, partition_name: str, passphrase: str) -> None:
    '''
    Encrypts a partition using LUKS encryption.

    Parameters
        partition_path: str
            Path of the partition to encrypt.
        passphrase: str
            The passphrase used to encrypt the partition.
    '''
    if not passphrase:
        raise ValueError(f'{LUKS_PASSPHRASE} not set')

    try:
        subprocess.run(['cryptsetup', '--verbose', 'luksFormat', partition_path],
                        check=True, input=passphrase.encode())
        subprocess.run(['cryptsetup', 'open', partition_path, partition_name],
                        check=True, input=passphrase.encode())
    except FileNotFoundError as exc:
        raise CommandNotFoundError(f'command not found: {exc.filename}') from exc


if __name__ == '__main__':
    main()
