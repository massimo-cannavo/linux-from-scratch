'''Mounts the partitions defined in the partitions.yaml file.'''
import argparse
import os
from pathlib import Path
import subprocess
import yaml

from partition import (CONFIG_FILE, LUKS_PASSPHRASE, CommandNotFoundError, DeviceNotFoundError,
                       get_dev_path, handle_error, parse_config, ValidationError)

LFS_PATH = Path('/mnt/lfs')


class PartitionNotFoundError(Exception):
    '''Exception raised when a partition was not found.'''
    def __init__(self, message: str) -> None:
        super().__init__(message)


def main() -> None:
    '''The main entrypoint of the script.'''
    args = parse_args()
    if os.geteuid() != 0:
        handle_error(error='run as root')

    try:
        config = parse_config(args.file)
        dev_path = get_dev_path(config.get('device'))
        mount_dev(config, dev_path)
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
    except (DeviceNotFoundError, PartitionNotFoundError, CommandNotFoundError) as exc:
        handle_error(error=exc)


def parse_args() -> argparse.Namespace:
    '''Parse command line arguments.'''
    parser = argparse.ArgumentParser(description='Mounts partitions from a YAML file.')
    parser.add_argument('-f', '--file',
                        default=CONFIG_FILE,
                        help=f'reads from FILE instead of {os.path.basename(CONFIG_FILE)}',
                        type=str)
    args = parser.parse_args()
    return args


def mount_dev(config: dict, dev_path: str) -> None:
    '''
    Mounts partitions using a dictionary parsed from a YAML config file.

    Parameters
        config: dict
            Config used to mount the partitions.
        dev_path: str
            Path of the device where the partitions reside.
    '''
    partitions = config.get('partitions', {})
    root = partitions.get('root')
    if not root:
        raise PartitionNotFoundError('root partition was not found')

    partitions.pop('root')
    root_path = partition_path = f'{dev_path}{root.get("number")}'
    try:
        if root.get('encrypted'):
            root_path = '/dev/mapper/root'
            status = subprocess.run(['cryptsetup', 'status', 'root'], check=False,
                                    capture_output=True)
            if status.returncode == 4:
                subprocess.run(['cryptsetup', '-v', 'open', partition_path, 'root'],
                                check=True, input=os.environ.get(LUKS_PASSPHRASE).encode())
            if not LFS_PATH.exists():
                LFS_PATH.mkdir()
                print(f'created directory {str(LFS_PATH)}')

            subprocess.run(['mount', root_path, str(LFS_PATH)], check=True)
            print(f'{root_path} mounted on {str(LFS_PATH)}')

            for partition_name in partitions:
                mount_path = Path(f'{str(LFS_PATH)}/{partition_name}')
                if not mount_path.exists():
                    mount_path.mkdir()
                    print(f'created directory {str(mount_path)}')

                partition_path = f'{dev_path}{partitions.get(partition_name).get("number")}'
                subprocess.run(['mount', partition_path, str(mount_path)], check=True)
                print(f'{partition_path} mounted on {str(mount_path)}')
    except FileNotFoundError as exc:
        raise CommandNotFoundError(f'command not found: {exc.filename}') from exc


if __name__ == '__main__':
    main()
