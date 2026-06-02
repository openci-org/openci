# avf_cli

A CLI tool for managing Apple Virtualization.framework macOS Virtual Machines, powered by `avf_dart`.

## Installation

You can activate this CLI globally using the Dart SDK:

```bash
dart pub global activate avf_cli
```

Make sure your `~/.pub-cache/bin` directory is added to your system's `PATH` environment variable.

## Usage

```bash
avf <command> [arguments]
```

### Subcommands

* **`list`**: List all local virtual machines.
  ```bash
  avf list
  ```

* **`boot`**: Boot a local virtual machine.
  ```bash
  avf boot <vm-name> [options]
  ```
  Options:
  * `-u, --username`: Username for SSH verification (defaults to "admin")
  * `-p, --password`: Password for SSH verification (defaults to "admin")
  * `-i, --private-key`: SSH private key file path for verification
  * `-c, --run-command`: Optional command to run on VM via SSH after successful boot

* **`install`**: Install macOS onto a new VM using an IPSW file.
  ```bash
  avf install <vm-name> --ipsw <ipsw-path>
  ```

* **`delete`**: Delete a local virtual machine.
  ```bash
  avf delete <vm-name>
  ```

* **`clone`**: Clone an existing local virtual machine.
  ```bash
  avf clone <source-vm> <target-vm>
  ```

* **`pull`**: Pull a VM archive from GCS bucket.
  ```bash
  avf pull <vm-name> --bucket <bucket-name>
  ```

* **`push`**: Push a VM archive to GCS bucket.
  ```bash
  avf push <vm-name> --bucket <bucket-name>
  ```

* **`download-ipsw`**: Download the macOS IPSW image.
  ```bash
  avf download-ipsw [options]
  ```
  Options:
  * `--url`: Optional IPSW URL (if omitted, fetches the latest from Apple)
  * `-o, --out`: Optional save path (defaults to standard downloads directory)

* **`fetch-ipsw`**: Fetch the latest supported macOS IPSW URL from Apple.
  ```bash
  avf fetch-ipsw
  ```
