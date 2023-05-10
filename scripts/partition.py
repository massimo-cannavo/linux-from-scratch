'''Partitions a device using a YAML file.'''
from argparse import ArgumentParser, Namespace
from dataclasses import dataclass
import math
import os
from pathlib import Path
import subprocess
import sys

from jsonschema import exceptions, validate
import pyudev
import yaml

PARENT_DIR = Path(__file__).parent.parent
CONFIG_FILE = f'{PARENT_DIR}/partitions.yaml'
SCHEMA_FILE = f'{PARENT_DIR}/partitions-schema.yaml'
UTF8 = 'utf-8'
UNIT_SYSTEM = {
    **dict.fromkeys(['B', 'KiB', 'MiB', 'GiB', 'TiB'], 1024),
    **dict.fromkeys(['KB', 'MB', 'GB', 'TB'], 1000)
}


@dataclass
class Colors:
    '''Colors used to diplay to the console.'''
    RED = '\033[1;31m'
    GREEN = '\033[1;32m'
    YELLOW = '\033[1;33m'
    BLUE  = '\033[1;34m'
    RESET = '\033[m'


class InvalidConfigError(Exception):
    '''Exception raised for errors in the config file.'''
    def __init__(self, message: str) -> None:
        super().__init__(message)


class DeviceNotFoundError(Exception):
    '''Exception raised when a device was not found.'''
    def __init__(self, message: str) -> None:
        super().__init__(message)


class InvalidUnitError(Exception):
    '''Exception raised when an invalid unit was specified.'''
    def __init__(self, message: str) -> None:
        super().__init__(message)


def main() -> None:
    '''The main entrypoint of the script.'''
    args = parse_args()
    if os.geteuid() != 0:
        print(f'{Colors.RED}run as root{Colors.RESET}')
        sys.exit(1)

    try:
        config = parse_config(args.file)
        dev = config.get('device')
        dev_path = get_dev_path(dev)
        print(f'found device {Colors.GREEN}{dev}{Colors.RESET}')
        display_partitions(dev_path)
        if args.what_if:
            display_changes(config, dev_path)
            sys.exit()

        partition_dev(config, dev_path)
    except (InvalidConfigError, FileNotFoundError, DeviceNotFoundError, InvalidUnitError) as exc:
        print(exc)
        sys.exit(1)


def parse_args() -> Namespace:
    '''Parse command line arguments.'''
    parser = ArgumentParser(description='Partitions a device from a YAML file.')
    parser.add_argument('-f', '--file',
                        default=CONFIG_FILE,
                        help='reads from FILE instead of the default (partitions.yml)',
                        type=str)
    parser.add_argument('--what-if',
                        action='store_true',
                        help='displays a preview of the operations to perform')
    args = parser.parse_args()
    return args


def parse_config(filename: str) -> dict:
    '''
    Parse YAML file and extract the config needed to partition the device.

    Parameters
        filename: str
            Name of the YAML config file to parse.
    '''
    path = Path(filename)
    if not path.is_file():
        raise FileNotFoundError(f'{Colors.RED}{filename} was not found{Colors.RESET}')

    with path.open(mode='r', encoding=UTF8) as file:
        try:
            config = yaml.safe_load(file)
            validate_config(config)
        except yaml.YAMLError as exc:
            if hasattr(exc, 'problem_mark'):
                error = f'{Colors.RED}{exc.problem}{Colors.RESET}\n' \
                        f'{exc.problem_mark}'
            else:
                error = f'{Colors.RED}{exc}{Colors.RESET}'

            raise InvalidConfigError(error) from exc

    return config


def validate_config(config: dict) -> None:
    '''
    Validates the YAML config file agains a defined schema.

    Parameters
        config: dict
            Contents of the YAML config file to validate.
    '''
    path = Path(SCHEMA_FILE)
    if not path.is_file():
        raise FileNotFoundError(f'{Colors.RED}{SCHEMA_FILE} was not found{Colors.RESET}')

    with path.open(mode='r', encoding=UTF8) as schema:
        try:
            validate(config, yaml.safe_load(schema))
        except exceptions.ValidationError as exc:
            raise InvalidConfigError(f'{CONFIG_FILE}:\n  '
                                     f'{Colors.RED}{exc.message}{Colors.RESET}') from exc


def get_dev_path(serial_id: str) -> str:
    '''
    Looks up the device path given a serial ID.

    Parameters
        serial_id: str
            Serial ID of the device.
    '''
    context = pyudev.Context()
    for device in context.list_devices(subsystem='block', DEVTYPE='disk'):
        if device.get('ID_SERIAL') == serial_id:
            return f'/dev/{device.sys_name}'

    raise DeviceNotFoundError(f'{Colors.RED}{serial_id} not found{Colors.RESET}')


def display_partitions(dev_path: str) -> None:
    '''
    Display partition table of device.

    Parameters
        dev_path: str
            path of device to display partition table.
    '''
    try:
        subprocess.run(['parted', dev_path, 'print'], check=False)
    except FileNotFoundError as exc:
        raise FileNotFoundError(f'{Colors.RED}parted is not installed{Colors.RESET}') from exc


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
    path = Path(f'/sys/block/{dev}/size')
    if not path.is_file():
        raise FileNotFoundError(f'{Colors.RED}unable to get size of {dev}{Colors.RESET}')

    unit = config.get('unit')
    for i, partition in enumerate(config.get('partitions')):
        start = to_bytes(size=partition.get('start'), size_unit=unit)
        end = partition.get('end')
        if end == -1:
            with path.open(mode='r', encoding=UTF8) as file:
                end = 512 * int(file.read())
        else:
            end = to_bytes(size=end, size_unit=unit)

        size, unit = convert_size(size_bytes=end - start, size_unit=unit)
        print(f'Partition {i + 1}\n'
              f'  Name: {Colors.BLUE}{partition.get("name")}{Colors.RESET}\n'
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
    unit = UNIT_SYSTEM.get(size_unit)
    if not unit:
        raise InvalidUnitError(f'invalid unit {size_unit}')

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
    unit = UNIT_SYSTEM.get(size_unit)
    if not unit:
        raise InvalidUnitError(f'invalid unit {size_unit}')

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


def partition_dev(config: dict, dev_path: str):
    '''TODO: add docstring'''
    partition_scheme = config.get('partitionScheme')
    unit = config.get('unit')
    cmd = ['parted', '--script', '--align', 'optimal', dev_path,
           'mklabel', partition_scheme, 'unit', unit]
    for i, partition in enumerate(config.get('partitions')):
        cmd.extend(['mkpart', partition.get('name'), partition.get('filesystem'),
                    partition.get('start')])
        end = partition.get('end')
        if end == -1:
            cmd.append('--')

        cmd.append(end)
        for flag in partition.get('flags', []):
            cmd.extend(['set', i + 1, flag, 'on'])

    # try:
    #     subprocess.run(cmd, check=False)
    # except FileNotFoundError:
    #     print(f'{Colors.RED}parted is not installed{Colors.RESET}')
    #     sys.exit(1)


def unmount_dev(dev_path: str):
    '''TODO: add docstring'''
    try:
        subprocess.run(['umount', 'sd'], check=False)
    except FileNotFoundError:
        print(f'{Colors.RED}umount is not installed{Colors.RESET}')
        sys.exit(1)


if __name__ == '__main__':
    main()
