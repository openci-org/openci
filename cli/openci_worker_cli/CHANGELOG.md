## 0.4.16 - 2026-02-05

- fix: OpenCI Worker CLI doesn't get the correct workflow

## 0.4.15 - 2026-02-05

- fix

## 0.4.14 - 2026-02-05

- update tart VM base image name

## 0.4.13 - 2026-02-03

- fix: Worker CLI now checkout the assigned commit SHA.

## 0.4.12 - 2026-02-03

- fix: Worker CLI now checkout the assigned commit SHA.

## 0.4.11 - 2026-02-03

- feat: throw exception when command fails

## 0.4.10 - 2026-02-01

- fix: Worker CLI now processes jobs in ascending order (oldest first).

## 0.4.9 - 2026-01-31

- Update build job and run logging to use Firestore subcollections.

## 0.4.8 - 2026-01-31

- Fix missing executable in pubspec.yaml

## 0.4.7

- Reduce polling interval.
- Improve logging.

## 0.4.6

- Add support for multiple commands in a step.

## 0.4.5

- Support dynamic VM cloning and cleanup per job.
- Support custom working directories.

## 0.4.4

- Support multiple commands in a step.

## 0.4.3

- Update README.

## 0.4.2

- Add continuous job polling with atomic job claiming via Firestore transactions and explicit status updates.

## 0.4.1

- Add Firebase Admin SDK support.

## 0.4.0

- Initial version.
