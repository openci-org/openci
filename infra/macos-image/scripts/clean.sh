#!/bin/bash
set -euo pipefail

if [[ $(id -un) != admin || $HOME != /Users/admin || $(sysctl -n hw.model) != VirtualMac* ]]; then
  echo 'Image cleanup only runs as admin inside a macOS VM' >&2
  exit 1
fi
test -f /usr/local/share/openci-image/toolchain.json

# The image retains SDK caches, but no build checkout, login history or SSH identity.
rm -rf "$HOME/openci-build" "$HOME/.bash_history" "$HOME/.zsh_history" "$HOME/.zsh_sessions" "$HOME/.bash_sessions"
rm -rf "$HOME/.ssh"
sudo -n rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
sudo -n chown -R root:wheel /usr/local/share/openci-image
sudo -n chmod -R go-w /usr/local/share/openci-image
sync
echo OPENCI_IMAGE_CLEANED
