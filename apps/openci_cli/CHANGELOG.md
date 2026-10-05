## Unreleased

- **Breaking:** `genuineci sync` now generates both secrets and workspace paths.
  Use `--secrets` or `--paths` instead of the previous subcommands to generate
  only one file. Generated files now live in `openci/generated/`; update workflow
  imports to use `generated/secrets.g.dart` and `generated/paths.g.dart`.
- Add Bash and Zsh completion for all commands and options with `cli_completion`,
  including language arguments, help targets, and locally saved login values.
  Skip update checks during completion requests and completion setup.

## 0.3.2

- Fix `genuineci sync paths` failing on directory names such as `switch` by
  appending an underscore to reserved getter names while preserving their paths.
- Support `genuineci sync paths` in single-package projects without a `workspace`
  declaration, generating paths relative to the root package.

## 0.3.1

- Fix team and secret-file selection failing during terminal cleanup after
  confirmation or cancellation.

## 0.3.0

- Add `genuineci list teams` to show team names and IDs, mark the selected team,
  and support redirected output with English and Japanese messages.

## 0.2.0

- Check for newer stable releases with `pub_updater` and offer to update with a
  yes/no prompt in interactive terminals.
- Add `genuineci update` and `--no-check-updates`, with English and Japanese
  messages. Skip automatic update prompts in CI, with redirected streams, and
  when update checks fail.

## 0.1.0

- Extend `genuineci status` to fetch and show the active team's current name,
  while retaining the saved profile, server, and team ID display.
- Support English and Japanese status messages, automatic token refresh, and
  guidance for missing teams, authentication failures, and connection errors.

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
