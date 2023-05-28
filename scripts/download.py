'''Downloads a specific version of a package using a YAML file.'''
import argparse
import hashlib
from pathlib import Path
import subprocess
import sys

from jsonschema import validate
from jsonschema.exceptions import ValidationError
import requests
import yaml

from partition import UTF8, CommandNotFoundError, handle_error

SOURCE_PATH = '/mnt/lfs/sources'
PARENT_DIR = Path(__file__).parent.parent
SCHEMA_FILE = f'{PARENT_DIR}/package-schema.yaml'


def main() -> None:
    '''The main entrypoint of the script.'''
    args = parse_args()
    try:
        with Path(args.file).open(mode='r', encoding=UTF8) as file:
            pkg = yaml.safe_load(file)
            with Path(SCHEMA_FILE).open(mode='r', encoding=UTF8) as schema:
                validate(pkg, yaml.safe_load(schema))

            url = pkg.get('source')
            pkg_file = url.split('/')[-1]
            sha512 = download_file(url, download_path=args.out)
            if not sha512:
                sys.exit()
            if sha512 != pkg.get('checksum'):
                handle_error(error=f'checksum verification failed for {pkg.get("name")}')

            extract_pkg(pkg_path=f'{args.out}/{pkg_file}', out_path=args.out)
            patches = pkg.get('patches', [])
            for patch in patches:
                download_file(url=patch, download_path=args.out)
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
    except (requests.exceptions.RequestException, CommandNotFoundError) as exc:
        handle_error(error=exc)
    except subprocess.CalledProcessError as exc:
        handle_error()


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


def download_file(url: str, download_path: str) -> str:
    '''
    Downloads and verifies the integrity of a file.

    Parameters
        url: str
            URL used to download the file.
        download_path: str
            The path on the filesystem to download the file.
    '''
    file = url.split('/')[-1]
    file_path = f'{download_path}/{file}'
    if Path(file_path).exists():
        print(f'{file} exists, skipping download')
        return None

    print(f'downloading {file} -> {download_path}')
    with requests.get(url, timeout=5, stream=True) as response:
        response.raise_for_status()
        sha512 = hashlib.sha512()
        with open(file_path, mode='wb') as file:
            for chunk in response.iter_content(chunk_size=100 * 1024**2):
                sha512.update(chunk)
                file.write(chunk)

    return sha512.hexdigest()


def extract_pkg(pkg_path: str, out_path: str) -> None:
    '''
    Extracts package that was downloaded.

    Parameters
        pkg_path: str
            Path of the package to extract.
        out_path: str
            The path on the filesystem to extract the package.
    '''
    try:
        print(f'extracting {pkg_path}')
        subprocess.run(['tar', '-xvf', pkg_path, '-C', out_path], check=True)
    except FileNotFoundError as exc:
        raise CommandNotFoundError(f'command not found: {exc.filename}') from exc


if __name__ == '__main__':
    main()
