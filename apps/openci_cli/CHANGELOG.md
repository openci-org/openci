## 0.0.3

- Add `genuineci status` to show the saved active profile, server, and selected
  team ID without connecting to the server.

## 0.0.2

- Use the hosted `dart_console_plus` package for console support.
- Remove the bundled dart_console source and native tests from the CLI.

## 0.0.1

- Initial pub.dev release as `genuineci_cli`, providing the `genuineci` command for OpenCI.
- Log in to remote and local servers and switch teams interactively.
- List, register, and sync secrets, including Base64-encoded secret files.
- Generate typed workflow paths from Dart workspace packages.
- Start and stop the local OpenCI development services and Orchard worker.
- Support English and Japanese command messages.
- Include the dart_console PR #16 terminal fixes while awaiting an upstream
  hosted release.
