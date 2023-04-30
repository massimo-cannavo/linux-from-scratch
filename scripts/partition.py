'''Partitions a device using a YAML file.'''
from argparse import ArgumentParser, Namespace
from dataclasses import dataclass
import os
from pathlib import Path
import sys

from jsonschema import exceptions, validate
import yaml

PARENT_DIR = Path(__file__).parent.parent
CONFIG_FILE = f'{PARENT_DIR}/partitions.yaml'
SCHEMA_FILE = f'{PARENT_DIR}/partitions-schema.yaml'


@dataclass
class Colors:
    '''Colors used to diplay to the console.'''
    RED = '\033[1;31m'
    RESET = '\033[m'


def parse_args() -> Namespace:
    '''Parse command line arguments.'''
    parser = ArgumentParser(description='Partitions a device from a YAML file.')
    parser.add_argument('-f', '--file',
                        default=CONFIG_FILE,
                        help='reads from FILE instead of the default (partitions.yml)',
                        type=str)
    parser.add_argument('--plan',
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

    with path.open(mode='r', encoding='utf-8') as schema:
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

    with path.open(mode='r', encoding='utf-8') as file:
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


def main() -> None:
    '''The main entrypoint of the script.'''
    args = parse_args()
    if os.geteuid() != 0:
        print(f'{Colors.RED}run as root{Colors.RESET}')
        sys.exit(1)

    config = parse_config(args.file)
    if not config:
        sys.exit(1)


if __name__ == '__main__':
    main()
