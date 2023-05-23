'''Downloads a specific version of a package using a YAML file.'''
import argparse


def main() -> None:
    '''The main entrypoint of the script.'''
    args = parse_args()


def parse_args() -> argparse.Namespace:
    '''Parse command line arguments.'''
    parser = argparse.ArgumentParser(description='Downloads and verifies a package.')
    required = parser.add_argument_group('required arguments')
    required.add_argument('-f', '--file',
                          help='package file to use for downloading the package.',
                          required=True,
                          type=str)
    args = parser.parse_args()
    return args


if __name__ == '__main__':
    main()
