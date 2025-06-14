#!/bin/bash

# github-issue-notifier.sh - Notification handler for latest GitHub Issues

# Configuration
CONFIG_DIR="$(pwd)"
NOTIFICATION_LOG="$CONFIG_DIR/notifications.log"
NOTIFICATION_QUEUE="$CONFIG_DIR/notification_queue.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Initialize files
touch "$NOTIFICATION_LOG" "$NOTIFICATION_QUEUE"

# Function to send desktop notification
send_desktop_notification() {
    local title=$1
    local message=$2
    local urgency=${3:-normal}
    
    if command -v notify-send &> /dev/null; then
        # Linux
        notify-send -u "$urgency" -i "github" -t 10000 "$title" "$message"
    elif command -v osascript &> /dev/null; then
        # macOS
        osascript -e "display notification \"$message\" with title \"$title\""
    elif command -v powershell.exe &> /dev/null; then
        # Windows WSL
        powershell.exe -Command "
            Add-Type -AssemblyName System.Windows.Forms
            \$notification = New-Object System.Windows.Forms.NotifyIcon
            \$notification.Icon = [System.Drawing.SystemIcons]::Information
            \$notification.Visible = \$true
            \$notification.ShowBalloonTip(10000, '$title', '$message', [System.Windows.Forms.ToolTipIcon]::Info)
        " 2>/dev/null
    else
        echo -e "${YELLOW}No desktop notification system found${NC}"
        return 1
    fi
}

# Function to log notifications
log_notification() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local repo=$1
    local issue_count=$2
    local issues=$3
    
    echo "[$timestamp] $repo: $issue_count new issues" >> "$NOTIFICATION_LOG"
    echo "$issues" >> "$NOTIFICATION_LOG"
    echo "---" >> "$NOTIFICATION_LOG"
}

# Function to process notification queue
process_notification_queue() {
    if [ ! -s "$NOTIFICATION_QUEUE" ]; then
        return 0
    fi
    
    local total_issues=0
    local total_repos=0
    local summary=""
    
    while IFS='|' read -r repo count issues; do
        [ -z "$repo" ] && continue
        
        total_issues=$((total_issues + count))
        total_repos=$((total_repos + 1))
        
        # Send individual notification for each repo
        if [ "$count" -gt 0 ]; then
            local title="New Issues: $repo"
            local message="$count new issue(s) found"
            
            # Get first 3 issues for notification
            local short_issues=$(echo "$issues" | head -n 3 | sed 's/^/• /')
            
            send_desktop_notification "$title" "$short_issues"
            log_notification "$repo" "$count" "$issues"
            
            summary="${summary}$repo ($count), "
        fi
        
        sleep 1  # Prevent notification spam
    done < "$NOTIFICATION_QUEUE"
    
    # Send summary notification if multiple repos
    if [ "$total_repos" -gt 1 ]; then
        summary=${summary%, }  # Remove trailing comma
        send_desktop_notification "GitHub Issues Summary" "Total: $total_issues new issues in $total_repos repositories" "critical"
    fi
    
    # Clear queue after processing
    > "$NOTIFICATION_QUEUE"
}

# Function to add notification to queue
add_to_queue() {
    local repo=$1
    local count=$2
    local issues=$3
    
    echo "${repo}|${count}|${issues}" >> "$NOTIFICATION_QUEUE"
}

# Main function when called with arguments
if [ $# -gt 0 ]; then
    case "$1" in
        "add")
            # Called from main script: add <repo> <count> <issues>
            if [ $# -ge 3 ]; then
                add_to_queue "$2" "$3" "${@:4}"
            fi
            ;;
        "process")
            # Process all queued notifications
            process_notification_queue
            ;;
        "test")
            # Test notification system
            echo -e "${BLUE}Testing notification system...${NC}"
            send_desktop_notification "GitHub Issue Monitor" "Test notification - system is working!" "normal"
            ;;
        *)
            echo "Usage: $0 {add|process|test}"
            echo "  add <repo> <count> <issues>  - Add notification to queue"
            echo "  process                       - Process notification queue"
            echo "  test                         - Test notification system"
            ;;
    esac
else
    # If run without arguments, process the queue
    process_notification_queue
fi