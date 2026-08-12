#!/usr/bin/env bash
if [ -z "${BASH_VERSION:-}" ] && command -v bash > /dev/null 2>&1; then
  exec bash "$0" "$@"
fi
set -eu
if [ -n "${BASH_VERSION:-}" ]; then
  set -o pipefail
fi

# Check if openssl is installed
if ! command -v openssl > /dev/null 2>&1; then
  echo "Error: openssl is required but not installed." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
BACKUP_FILE="${ROOT_DIR}/.env.bak"

if [ -f "${ENV_FILE}" ]; then
  echo "Existing .env file found. Backing up to .env.bak..."
  cp "${ENV_FILE}" "${BACKUP_FILE}"
fi

echo "Generating random secrets..."

POSTGRES_PASSWORD=$(openssl rand -hex 16)
GITHUB_WEBHOOK_SECRET=$(openssl rand -hex 20)
INTERNAL_API_KEY=$(openssl rand -hex 32)
# Secret Crypter requires base64 encoded 32 bytes key
SECRET_ENCRYPTION_KEY=$(openssl rand -base64 32)
ORCHARD_SERVICE_ACCOUNT_TOKEN=$(openssl rand -hex 32)

echo "Creating .env file..."

cat <<EOF > "${ENV_FILE}"
# PostgreSQL configurations
POSTGRES_DB=openci
POSTGRES_USER=postgres
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# GitHub Configurations
GITHUB_API_BASE_URL=https://api.github.com
GITHUB_WEBHOOK_SECRET=${GITHUB_WEBHOOK_SECRET}
GITHUB_APP_ID=your-github-app-id-here

INTERNAL_API_KEY=${INTERNAL_API_KEY}

# Secret Encryption Configurations
SECRET_ENCRYPTION_KEY=${SECRET_ENCRYPTION_KEY}

# Orchard Configurations
ORCHARD_API_URL=http://orchard-controller:6120
ORCHARD_SERVICE_ACCOUNT_NAME=openci-api
ORCHARD_SERVICE_ACCOUNT_TOKEN=${ORCHARD_SERVICE_ACCOUNT_TOKEN}

# Sentry configurations
SENTRY_DSN_SERVER=your-sentry-dsn-for-server-here
SENTRY_DSN_JOB_PROCESSOR=your-sentry-dsn-for-job-processor-here
EOF

echo "Successfully created .env!"
echo "Note: Please update GITHUB_APP_ID and Sentry DSNs with your actual configuration if needed."
