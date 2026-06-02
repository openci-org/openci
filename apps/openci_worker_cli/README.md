# OpenCI Worker CLI

The worker agent that polls and executes CI/CD build jobs for [OpenCI](https://openci.org).

## Installation

```bash
dart pub global activate openci_worker_cli
```

## Usage

```bash
openci_worker --service-account <path-to-service-account-json> --worker-id <id>
```

### Options

| Flag                | Short | Description                                         |
| ------------------- | ----- | --------------------------------------------------- |
| `--service-account` |       | Path to service account JSON file (required)        |
| `--worker-id`       |       | Unique ID for this worker, e.g. `1`, `2` (required) |
| `--update`          | `-u`  | Update to the latest version                        |
| `--version`         |       | Print the current version                           |
| `--help`            | `-h`  | Print usage information                             |

### Running multiple workers on the same machine

Each worker must have a unique `--worker-id` to avoid VM conflicts:

```bash
# Terminal 1
openci_worker --service-account ./sa.json --worker-id 1

# Terminal 2
openci_worker --service-account ./sa.json --worker-id 2
```

### Self-update

```bash
openci_worker -u
```
