'''Partitions a device using a YAML file.'''
from argparse import ArgumentParser
from dataclasses import dataclass
import os
import sys

@dataclass
class Colors:
    '''Colors used to diplay to the console.'''
    RED = '\033[1;31m'
    RESET = '\033[m'


def parse_args():
    '''Parse command line arguments.'''
    parser = ArgumentParser(description='Partitions a device from a YAML file.')
    parser.add_argument('-f', '--file',
                        default='../partitions.yaml',
                        help='reads from FILE instead of the default (partitions.yml)',
                        type=str)
    parser.add_argument('--plan',
                        action='store_true',
                        help='displays a preview of the operations to perform')

    args = parser.parse_args()
    return args


def main():
    '''The main entrypoint of the script.'''
    args = parse_args()
    if os.geteuid() != 0:
        print(f'{Colors.RED}run as root{Colors.RESET}')
        sys.exit(1)


if __name__ == '__main__':
    main()
