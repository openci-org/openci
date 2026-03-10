WIP: CI/CD Made Easy

# macOS Worker setup

### 1. Install Homebrew & setup PATH

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
echo 'export PATH="$PATH":"$HOME/.local/bin"' >> ~/.zshrc
source ~/.zshrc
```

### 2. Install Lume & pull VM image

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trycua/cua/main/libs/lume/scripts/install.sh)"
lume pull tahoe-base:v1.0.0 --organization open-ci-io
```

### 3. Install Worker CLI

```bash
brew tap open-ci-io/openci
brew install openci-worker
```

### 4. Setup service account & start worker

Place your Firebase service account JSON file (e.g. `service-account.json`) in your home directory, then start the worker:

```bash
openci-worker --service-account ~/service-account.json --worker-id worker-1
```
