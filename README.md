WIP: CI/CD Made Easy

# macOS Worker setup

### 1. Place service account JSON on the build machine

```bash
scp ~/path/to/service-account.json admin@<ip>:~/service-account.json
```

### 2. SSH into the build machine and run setup

```bash
curl -fsSL https://raw.githubusercontent.com/open-ci-io/openci/develop/setup.sh | bash
```

This will install all dependencies, pull the VM image, and start workers automatically.
Runs inside tmux so SSH disconnects won't interrupt the process.

### Restart workers

```bash
~/.openci/start-workers.sh        # 2 workers (default)
~/.openci/start-workers.sh 4      # 4 workers
```

### tmux controls

| Action             | Key                             |
| ------------------ | ------------------------------- |
| Switch pane        | `Ctrl+b` → Arrow keys           |
| Scroll             | `Ctrl+b` → `[` → Arrow/PgUp     |
| Detach             | `Ctrl+b` → `d`                  |
| Reattach (setup)   | `tmux attach -t openci-setup`   |
| Reattach (workers) | `tmux attach -t openci-workers` |
