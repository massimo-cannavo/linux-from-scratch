'''Common module that can be imported in other modules.'''
from dataclasses import dataclass
from pathlib import Path
import sys
from typing import Any

from jsonschema import validate
import pyudev
import yaml

LUKS_PASSPHRASE = 'LUKS_PASSPHRASE'
PARENT_DIR = Path(__file__).parent.parent
PACKAGE_SCHEMA = f'{PARENT_DIR}/package-schema.yaml'
PARTITIONS_FILE = f'{PARENT_DIR}/partitions.yaml'
PARTITIONS_SCHEMA = f'{PARENT_DIR}/partitions-schema.yaml'
UTF8 = 'utf-8'


@dataclass
class Colors:
    '''Colors used to diplay to the console.'''
    RED = '\033[1;31m'
    GREEN = '\033[1;32m'
    YELLOW = '\033[1;33m'
    BLUE  = '\033[1;34m'
    RESET = '\033[m'


class CommandNotFoundError(Exception):
    '''Exception raised when a command was not found.'''
    def __init__(self, message: str) -> None:
        super().__init__(message)


class DeviceNotFoundError(Exception):
    '''Exception raised when a device was not found.'''
    def __init__(self, message: str) -> None:
        super().__init__(message)


def handle_error(error: Any = None) -> None:
    '''
    Error handling that gracefuly terminates the program.

    Parameters
        error: Any
            The error message to print to the console.
    '''
    if error:
        print(f'{Colors.RED}[ ERROR ]{Colors.RESET} {error}', file=sys.stderr)

    sys.exit(1)


def parse_yaml(filename: str, schema: str) -> dict:
    '''
    Parse a YAML file and extract the contents of that file.

    Parameters
        filename: str
            Name of the YAML file to parse.
        schema: str
            Name of the schema file to use for validating the YAML file.
    '''
    with Path(filename).open(mode='r', encoding=UTF8) as yaml_file:
        data = yaml.safe_load(yaml_file)
        with Path(schema).open(mode='r', encoding=UTF8) as schema_file:
            validate(data, yaml.safe_load(schema_file))

    return data


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

    raise DeviceNotFoundError(f'device not found: {serial_id}')
