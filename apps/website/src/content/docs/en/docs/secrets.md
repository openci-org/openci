---
title: Secrets
description: Manage API tokens and configuration files for your team and prepare them for use in workflows.
---

## Check your team

Secret commands operate on the team selected in the CLI.

```sh
openci status
openci switch team
```

## Register a secret

Enter a name and value in the interactive prompt. The value is hidden as you type.

```sh
openci register secret
```

Registering a secret with an existing name updates its value.

## List secret names

View registered names without displaying their values.

```sh
openci list secrets
```

## Register a file

Register a file as a Base64-encoded secret.

```sh
openci register secretFile
```

Select a file in the interactive prompt. The secret name is generated from the filename: for example, `google-services.json` becomes `GOOGLE_SERVICES_JSON_BASE64`.

> A matching existing name updates that secret. Check the selected team and file before running the command.

## Sync definitions

Update the secret definitions in your workflow project.

```sh
openci sync --secrets
```

Definitions are saved to `openci/generated/secrets.g.dart`. Secret values are not stored in this file; they are read from environment variables when the workflow runs. Running `openci sync` also generates workspace paths.

Sync again as needed after switching teams. See the [CLI reference](/en/docs/cli/) for installation and login.
