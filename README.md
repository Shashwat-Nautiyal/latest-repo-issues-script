# GitHub Issue Monitor

A lightweight, command-line tool to monitor multiple GitHub repositories for new issues with desktop notifications.

## 🚀 Features

- **Multi-Repository Monitoring**: Track issues across multiple GitHub repositories
- **Smart Issue Detection**: Only shows issues created since your last check
- **Desktop Notifications**: Get instant notifications when new issues are found
- **Interactive Interface**: Easy-to-use menu system for managing repositories
- **Cross-Platform**: Works on Linux, macOS, and Windows (WSL)
- **GitHub API Integration**: Supports authenticated requests for higher rate limits
- **Persistent State**: Remembers last check time for each repository

---

## 🖥️ Requirements

| Dependency | Purpose | Install (Ubuntu) | Install (macOS) |
|------------|---------|------------------|-----------------|
| `bash`     | shell   | _pre-installed_  | _pre-installed_ |
| `curl`     | HTTP    | `sudo apt install curl` | `brew install curl` |
| `jq`       | JSON    | `sudo apt install jq`   | `brew install jq` |
| `notify-send` | desktop notif (Linux) | `sudo apt install libnotify-bin` | — |
| `osascript`  | desktop notif (macOS)  | — (built-in) | — |
| PowerShell (WSL) | desktop notif (Windows) |  _pre-installed in Windows_ | — |

---

## Quickstart

git clone https://github.com/yourname/github-issue-monitor.git
cd github-issue-monitor
chmod +x github-issue-monitor.sh github-issue-notifier.sh
./github-issue-monitor.sh