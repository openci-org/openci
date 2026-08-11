#!/usr/bin/env bash
set -euo pipefail

# Check if openssl is installed
if ! command -v openssl > /dev/null 2>&1; then
  echo "openssl is required but not installed."
  if command -v apt-get > /dev/null 2>&1; then
    printf "Would you like to install openssl using apt-get? [y/N]: "
    REPLY=""
    if [ -t 0 ]; then
      read -r REPLY || true
    elif [ -e /dev/tty ]; then
      read -r REPLY < /dev/tty || true
    fi
    case "$REPLY" in
      [yY][eE][sS]|[yY])
        echo "Installing openssl..."
        if [ "$(id -u)" -ne 0 ] && command -v sudo > /dev/null 2>&1; then
          sudo apt-get update && sudo apt-get install -y openssl
        else
          apt-get update && apt-get install -y openssl
        fi
        ;;
      *)
        echo "Error: openssl installation aborted." >&2
        exit 1
        ;;
    esac
  else
    echo "Error: openssl is required but not installed." >&2
    exit 1
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
BACKUP_FILE="${SCRIPT_DIR}/.env.bak"

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
ORCHARD_SERVICE_ACCOUNT_NAME=bootstrap-admin
ORCHARD_SERVICE_ACCOUNT_TOKEN=${ORCHARD_SERVICE_ACCOUNT_TOKEN}

# Sentry configurations
SENTRY_DSN_SERVER=your-sentry-dsn-for-server-here
SENTRY_DSN_JOB_PROCESSOR=your-sentry-dsn-for-job-processor-here
EOF

echo "Successfully created .env!"
echo "Note: Please update GITHUB_APP_ID and Sentry DSNs with your actual configuration if needed."
