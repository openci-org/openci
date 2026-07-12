## 1.0.9

- Fix: Await the `Future.then` chain instead of the original process future to prevent unhandled async errors in tests when startup fails.

## 1.0.8

- Fix: Register stream listeners immediately using `Future.then` to avoid microtask execution delay that can cause pipe buffer hangs on startup.

## 1.0.7

- Fix: Correct formatting of `run_test.dart` to satisfy monorepo lint rules.

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
