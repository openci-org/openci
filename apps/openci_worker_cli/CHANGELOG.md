# Changelog

## 0.5.1

- Fix: Avoid ARG_MAX limit by writing files to VM via chunked base64 instead of inline command arguments
- Fix: Compact service account JSON to single line for act's secret file format
- Fix: Pass command arguments as separate list items to `tart exec` for correct process invocation
- Fix: Use login shell (`-l`) when executing act script to load VM environment

## 0.5.0

- Initial act integration for workflow execution
