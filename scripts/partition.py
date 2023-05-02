'''Partitions a device using a YAML file.'''
from argparse import ArgumentParser, Namespace
from dataclasses import dataclass
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


@dataclass
class Colors:
    '''Colors used to diplay to the console.'''
    RED = '\033[1;31m'
    GREEN = '\033[1;32m'
    YELLOW = '\033[1;33m'
    BLUE  = '\033[1;34m'
    RESET = '\033[m'


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


def validate_config(config: dict) -> bool:
    '''
    Validates the YAML config file agains a defined schema.

    Parameters
        config: Contents of the YAML config file to validate.
    '''
    path = Path(SCHEMA_FILE)
    if not path.is_file():
        print(f'{Colors.RED}{SCHEMA_FILE} was not found{Colors.RESET}')
        return False

    with path.open(mode='r', encoding=UTF8) as schema:
        try:
            validate(config, yaml.safe_load(schema))
        except exceptions.ValidationError as exc:
            print(f'{CONFIG_FILE}:\n  '
                  f'{Colors.RED}{exc.message}{Colors.RESET}')
            return False

    return True


def parse_config(filename: str) -> dict:
    '''
    Parse YAML file and extract the config needed to partition the device.

    Parameters
        filename: Name of the YAML config file to parse.
    '''
    path = Path(filename)
    if not path.is_file():
        print(f'{Colors.RED}{filename} was not found{Colors.RESET}')
        return None

    with path.open(mode='r', encoding=UTF8) as file:
        try:
            config = yaml.safe_load(file)
            if not validate_config(config):
                return None
        except yaml.YAMLError as exc:
            if hasattr(exc, 'problem_mark'):
                print(f'{Colors.RED}{exc.problem}{Colors.RESET}\n'
                      f'{exc.problem_mark}')
            else:
                print(f'{Colors.RED}{exc}{Colors.RESET}')

            return None

    return config


def get_dev_path(serial_id: str) -> str:
    '''
    Looks up the device path given a serial ID.

    Parameters
        serial_id: Serial ID of the device.
    '''
    context = pyudev.Context()
    for device in context.list_devices(subsystem='block', DEVTYPE='disk'):
        if device.get('ID_SERIAL') == serial_id:
            print(f'found device {Colors.GREEN}{serial_id}{Colors.RESET}')
            return f'/dev/{device.sys_name}'

    return None


def display_partitions(dev_path: str) -> None:
    '''
    Display partition table of device.

    Parameters
        dev_path: path of device to display partition table.
    '''
    try:
        subprocess.run(['parted', dev_path, 'print'], check=False)
    except FileNotFoundError:
        print(f'{Colors.RED}parted is not installed{Colors.RESET}')
        sys.exit(1)


def display_changes(config: dict, dev_path: str) -> None:
    '''TODO: add docstring.'''
    print(f'{Colors.YELLOW}Device will be wiped and formatted:{Colors.RESET}\n'
          f'Partition Table: {Colors.BLUE}{config.get("partitionScheme")}{Colors.RESET}')

    dev = dev_path.replace('/dev/', '')
    path = Path(f'/sys/block/{dev}/size')
    if not path:
        print(f'{Colors.RED}unable to get size of {dev_path}{Colors.RESET}')

    size = 0
    with path.open(mode='r', encoding=UTF8) as file:
        size = 512 * file.read()

    for i,partition in enumerate(config.get('partitions')):
        print(f'Partition {i}\n'
              f'  Name: {Colors.BLUE}{partition.get("name")}{Colors.RESET}\n'
              f'  Filesystem: {Colors.BLUE}{partition.get("filesystem")}{Colors.RESET}\n'
              f'  Start: {Colors.BLUE}{partition.get("start")}{Colors.RESET}\n'
              f'  End: {Colors.BLUE}{partition.get("end")}{Colors.RESET}')


def main() -> None:
    '''The main entrypoint of the script.'''
    args = parse_args()
    if os.geteuid() != 0:
        print(f'{Colors.RED}run as root{Colors.RESET}')
        sys.exit(1)

    config = parse_config(args.file)
    if not config:
        sys.exit(1)

    dev = config.get('device')
    dev_path = get_dev_path(dev)
    if not dev_path:
        print(f'{Colors.RED}{dev} not found{Colors.RESET}')
        sys.exit(1)

    display_partitions(dev_path)
    if args.what_if:
        display_changes(config, dev_path)
        sys.exit()


if __name__ == '__main__':
    main()
