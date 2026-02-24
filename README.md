# Releasing Soon

WIP: CI/CD Made Easy

# macOS Worker setup

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc && \
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc && \
source ~/.zshrc && \
brew install cirruslabs/cli/tart && \
brew tap dart-lang/dart && \
brew install dart && \
tart clone ghcr.io/open-ci-io/sequoia:1.0.2 sequoia-base && \
dart pub global activate openci_worker_cli
```
