#!/bin/bash

# github-issue-notifier.sh - Notification handler for GitHub Issue Monitor

# Configuration
CONFIG_DIR="$(pwd)/notification_config"
NOTIFICATION_LOG="$CONFIG_DIR/notifications.log"
NOTIFICATION_QUEUE="$CONFIG_DIR/notification_queue.txt"

mkdir -p "$CONFIG_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Initialize files
touch "$NOTIFICATION_LOG" "$NOTIFICATION_QUEUE"

# Function to display menu
show_notifier_menu() {
    echo -e "\n${BLUE}=== GitHub Issue Notifier ===${NC}"
    echo "1. Process pending notifications"
    echo "2. Test notification system"
    echo "3. View notification log"
    echo "4. Clear notification log"
    echo "5. Exit"
    echo -n "Select option: "
}

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
        echo -e "${YELLOW}No pending notifications${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Processing notifications...${NC}"
    
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
            
            echo -e "${GREEN}✓ Notified: $repo ($count issues)${NC}"
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
    
    echo -e "${GREEN}Processed $total_repos notification(s)${NC}"
}

# Function to test notifications
test_notifications() {
    echo -e "${BLUE}Testing notification system...${NC}"
    
    # Test with sample notification
    local test_message="If you see this notification, the system is working correctly!"
    
    if send_desktop_notification "GitHub Issue Monitor Test" "$test_message" "normal"; then
        echo -e "${GREEN}✓ Notification sent successfully!${NC}"
        echo -e "${GREEN}Check your desktop for the notification.${NC}"
    else
        echo -e "${RED}✗ Failed to send notification${NC}"
        echo -e "${YELLOW}Make sure you have a notification system installed:${NC}"
        echo "  - Linux: notify-send (libnotify-bin package)"
        echo "  - macOS: Built-in (osascript)"
        echo "  - Windows WSL: PowerShell"
    fi
}

# Function to view log
view_notification_log() {
    if [ ! -s "$NOTIFICATION_LOG" ]; then
        echo -e "${YELLOW}No notifications logged yet${NC}"
        return 0
    fi
    
    echo -e "\n${BLUE}=== Notification Log ===${NC}"
    tail -n 50 "$NOTIFICATION_LOG"
    echo -e "${BLUE}=======================>${NC}"
}

# Function to clear log
clear_notification_log() {
    echo -n "Are you sure you want to clear the notification log? (y/N): "
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        > "$NOTIFICATION_LOG"
        echo -e "${GREEN}Notification log cleared${NC}"
    else
        echo -e "${YELLOW}Cancelled${NC}"
    fi
}

# Function to add notification to queue (for internal use)
add_to_queue() {
    local repo=$1
    local count=$2
    local issues=$3
    
    echo "${repo}|${count}|${issues}" >> "$NOTIFICATION_QUEUE"
}

# Main function
main() {
    # If called with arguments (internal use by main script)
    if [ $# -gt 0 ]; then
        case "$1" in
            "--add")
                # Called from main script: --add <repo> <count> <issues>
                if [ $# -ge 3 ]; then
                    add_to_queue "$2" "$3" "${@:4}"
                fi
                ;;
            "--process")
                # Process all queued notifications silently
                process_notification_queue > /dev/null
                ;;
            *)
                echo "Invalid internal command"
                ;;
        esac
    else
        # Interactive mode - show menu
        while true; do
            show_notifier_menu
            read choice
            
            case $choice in
                1)
                    process_notification_queue
                    ;;
                2)
                    test_notifications
                    ;;
                3)
                    view_notification_log
                    ;;
                4)
                    clear_notification_log
                    ;;
                5)
                    echo -e "\n${GREEN}Goodbye!${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Invalid option${NC}"
                    ;;
            esac
            
            echo -n "Press Enter to continue..."
            read
        done
    fi
}

# Run main function
main "$@"