'''Gets the serial ID of the device from a YAML config file.'''
import yaml

from partition import CONFIG_FILE, DeviceNotFoundError, get_dev_path, handle_error, parse_config

try:
    config = parse_config(filename=CONFIG_FILE)
    device = get_dev_path(serial_id=config.get('device'))
    for i, partition in enumerate(config.get('partitions')):
        if partition.get('name') == 'root':
            root = f'{device}{i + 1}'
            encrypted = partition.get('encrypted')

    print(device)
    print(root)
    print(encrypted)
except yaml.YAMLError as exc:
    if hasattr(exc, 'problem_mark'):
        error = f'{exc.problem}\n{exc.problem_mark}'
    else:
        error = exc

    handle_error(error)
except FileNotFoundError as exc:
    handle_error(error=f'no such file or directory: {exc.filename}')
except DeviceNotFoundError as exc:
    handle_error(error=exc)
