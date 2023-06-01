'''Parses a YAML file and extracts the specified attributes.'''
import argparse

from common import PACKAGE_SCHEMA, parse_yaml


def main() -> None:
    '''The main entrypoint of the script.'''
    args = parse_args()
    data = parse_yaml(args.file, args.schema)
    if args.query:
        extract_yaml(data, args.query)


def parse_args() -> argparse.Namespace:
    '''Parse command line arguments.'''
    formatter = lambda prog: argparse.HelpFormatter(prog, max_help_position=30)  # pylint: disable=C3001
    parser = argparse.ArgumentParser(description='Reads a YAML file.', formatter_class=formatter)
    parser.add_argument('-f', '--file',
                        required=True,
                        help='name of the YAML file to read')
    parser.add_argument('-s', '--schema',
                        default=PACKAGE_SCHEMA,
                        help='name of the schema file to use for validation')
    parser.add_argument('-q', '--query',
                        help='query used to get specifc attributes')
    args = parser.parse_args()
    return args


def extract_yaml(data: dict, query: str) -> None:
    '''
    Extracts the specified attribute from YAML data given a query.

    Parameters
        data: dict
            The YAML data to parse and extract the attributes.
        query: str
            The query used to specify the attributes to extract.
    '''
    if query == 'package':
        print(data.get('source').split('/')[-1])
        return

    selector = query.split('.')[1:]
    selector_num = len(selector)
    for element in selector:
        data = data.get(element)
        if selector_num > 1:
            continue

        if isinstance(data, list):
            for item in data:
                print(item)
        elif isinstance(data, str):
            print(data)


if __name__ == '__main__':
    main()
