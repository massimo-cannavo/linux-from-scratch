'''Downloads a specific version of a package using a YAML file.'''
import argparse
from pathlib import Path

from jsonschema import validate
from jsonschema.exceptions import ValidationError
import requests
import yaml

from partition import UTF8, handle_error

SOURCE_PATH=Path('/mnt/lfs/sources')
PARENT_DIR = Path(__file__).parent.parent
SCHEMA_FILE = f'{PARENT_DIR}/package-schema.yaml'


def main() -> None:
    '''The main entrypoint of the script.'''
    args = parse_args()
    if not SOURCE_PATH.exists():
        handle_error(error=f'no such file or directory: {SOURCE_PATH}')

    try:
        with Path(args.file).open(mode='r', encoding=UTF8) as file:
            pkg = yaml.safe_load(file)
            with Path(SCHEMA_FILE).open(mode='r', encoding=UTF8) as schema:
                validate(pkg, yaml.safe_load(schema))
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


def parse_args() -> argparse.Namespace:
    '''Parse command line arguments.'''
    parser = argparse.ArgumentParser(description='Downloads and verifies a package.')
    parser.add_argument('-f', '--file',
                          help='package file used for downloading the package.',
                          required=True,
                          type=str)
    parser.add_argument('-o', '--out',
                        default=SOURCE_PATH,
                        help=f'downloads packages in OUT insted of {SOURCE_PATH}')
    args = parser.parse_args()
    return args


def download_pkg(url: str, download_path: str) -> None:
    '''TODO: add docstring.'''
    pkg_file = f'{download_path}/{url.split("/")[-1]}'
    with requests.get(url, timeout=5, stream=True) as response:
        response.raise_for_status()
        with open(pkg_file, mode='wb') as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)


if __name__ == '__main__':
    main()
