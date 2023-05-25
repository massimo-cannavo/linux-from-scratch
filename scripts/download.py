'''Downloads a specific version of a package using a YAML file.'''
import argparse
import hashlib
from pathlib import Path
import sys

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

            sha512 = download_pkg(url=pkg.get('source'), download_path=args.out)
            if not sha512:
                sys.exit()
            if sha512 != pkg.get('checksum'):
                handle_error(error=f'checksum verification failed for {pkg.get("name")}')
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
    except requests.exceptions.RequestException as exc:
        handle_error(error=exc)


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


def download_pkg(url: str, download_path: str) -> str:
    '''
    Downloads and verifies the integrity of a package.

    Parameters
        url: str
            URL used to download the package.
        download_path: str
            The path on the filesystem to download the package.
    '''
    pkg_file = url.split("/")[-1]
    pkg_path = f'{download_path}/{pkg_file}'
    if Path(pkg_path).exists():
        print(f'{pkg_file} exists, skipping download')
        return None

    print(f'downloading {pkg_file} -> {download_path}')
    with requests.get(url, timeout=5, stream=True) as response:
        response.raise_for_status()
        sha512 = hashlib.sha512()
        with open(pkg_path, mode='wb') as file:
            for chunk in response.iter_content(chunk_size=100 * 1024**2):
                sha512.update(chunk)
                file.write(chunk)

    return sha512.hexdigest()

if __name__ == '__main__':
    main()
