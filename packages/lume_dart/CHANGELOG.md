## 1.0.6

- Fix: Mock process stdout and stderr streams in unit tests to prevent Null subtype errors on VM execution.

## 1.0.5

- Docs: Translate README.md to English and add comprehensive usage examples.

## 1.0.4

- Fix: Automatically consume or forward stdout/stderr streams of the run process to prevent pipe buffer hangs.

## 1.0.3

- Fix: Extract only the JSON array substring from Lume output before decoding, filtering out any log messages.

## 1.0.2

- Fix: Auto-resolve lume executable path from common directories (e.g. ~/.local/bin/lume) if not available in PATH environment.

## 1.0.1

- Fix: Relax Dart SDK version constraints to allow newer Dart SDK versions.

## 1.0.0

- Initial version.
