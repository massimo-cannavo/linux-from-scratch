'''Partitions a device using a YAML file.'''
import argparse


def parse_args():
    '''Parse command line arguments.'''
    parser = argparse.ArgumentParser(description='Partitions a device from a YAML file.')
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


if __name__ == '__main__':
    main()
