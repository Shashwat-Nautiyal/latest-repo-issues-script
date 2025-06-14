# GitHub Issue Monitor

A lightweight, command-line tool to monitor multiple GitHub repositories for new issues with desktop notifications.

## 🚀 Features

- **Multi-Repo Monitoring**: Track issues across multiple GitHub repositories
- **Smart Issue Detection**: Only shows issues created since your last check
- **Desktop Notifications**: Get instant notifications when new issues are found
- **OG UX**: Easy-to-use menu system for managing repositories
- **Cross-Platform**: Works on Linux, macOS, and Windows (WSL)
- **GitHub API Integration**: Supports authenticated requests for higher rate limits
- **Persistent State**: Remembers last check time for each repository

---

## 📁 Directory Structure
```
github-issue-1.sh                   # Main script with interactive menu
github-issue-notifier.sh            # Notification handler (can run standalone)
repo_config/
    └── repositories.txt            # List of repos you're watching
    └── timestamps.txt              # Last-check time for each repo
notification_config/
    └── notifications.log           # History of all sent notifications
    └── notification_queue.txt      # Temp queue for pending notifications

```
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

## 🏃 Quickstart

```bash
git clone https://github.com/yourname/github-issue-monitor.git
cd github-issue-monitor
chmod +x github-issue-monitor.sh github-issue-notifier.sh
./github-issue-monitor.sh

```
Congrats! You're now officially stalking Facebook's React repo. Don't make it weird.

## General CLI Interface

```
=== GitHub Issue Monitor ===
1. Check for new issues
2. Add repository
3. Remove repository
4. List monitored repositories
5. Test notifications
6. Exit
Select option:
```
## Notification Interface

```
=== GitHub Issue Notifier ===
1. Process pending notifications
2. Test notification system
3. View notification log
4. Clear notification log
5. Exit
Select option:
```

## 🎯 Usage Guide

### Adding Your First Repo

Fire up the monitor and hit 2:

```
Select option: 2
Enter repository (format: owner/repo): facebook/react
Repository added successfully
```
_Congrats! You're now officially stalking Facebook. Pff... How the table turns..._

### Checking for New Issues

Just hit 1 from the main menu:
```
Select option: 1
Checking for new issues...

Checking facebook/react...
Found 3 new issue(s):
    [#28439] Bug: useEffect cleanup not firing
      URL: https://github.com/facebook/react/issues/28439
      Created: 2024-02-20T14:23:45Z

    [#28440] Feature: Better error boundaries
      URL: https://github.com/facebook/react/issues/28440
      Created: 2024-02-20T15:10:22Z
```
_And boom! 💥 You'll get a desktop notification for each repo with new issues. No more constant tab refreshing!_

### Managing Your Repo List
See what you're tracking:

```
Select option: 4

Monitored repositories:
  - facebook/react
  - vercel/next.js
  - microsoft/typescript
Remove a repo (because maybe TypeScript issues are giving you nightmares):
```
#### Remove Repo
```
Select option: 3

Current repositories:
     1  facebook/react
     2  Shashwat-Nautiyal/Distributed_Systems
     3  Shashwat-Nautiyal/p2p_chat_cli

Enter line number to remove (0 to cancel): 3
Repository removed successfully
```
