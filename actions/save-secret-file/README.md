# Save Secret File

Save a secret to a file during CI. Supports both base64-encoded secrets and raw plaintext secrets such as JSON service account keys.

This action is maintained in the OpenCI monorepo. Workflows in this repository should reference it with `uses: ./actions/save-secret-file`.

From another public repository, use the subdirectory action path and pin an OpenCI commit SHA:

```yaml
- uses: openci-org/openci/actions/save-secret-file@<commit-sha>
  with:
    secret: ${{ secrets.FIREBASE_OPTIONS }}
    path: "lib/firebase_options.dart"
```

## Usage

### Base64-encoded secret

```yaml
- uses: ./actions/save-secret-file
  with:
    secret: ${{ secrets.FIREBASE_OPTIONS }}
    path: "lib/firebase_options.dart"
```

### Raw content

```yaml
- uses: ./actions/save-secret-file
  with:
    secret: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
    path: "firebase/service-account.json"
    encoding: raw
```

## Inputs

| Input      | Default  | Description                                                                  |
| ---------- | -------- | ---------------------------------------------------------------------------- |
| `secret`   | required | Secret content. Base64-encoded by default, or raw when `encoding` is `raw`.   |
| `path`     | required | File path to save the content to.                                             |
| `encoding` | `base64` | `base64` decodes the secret before writing. `raw` writes the value as-is.     |

## Behavior

1. Creates the parent directory when it does not already exist.
2. Writes the secret without adding a trailing newline.
3. Fails when `encoding` is not `base64` or `raw`.
