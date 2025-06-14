#!/bin/bash

# File to store repositories and last checked timestamps
CONFIG_DIR="$(pwd)"
REPO_FILE="$CONFIG_DIR/repositories.txt"
TIMESTAMP_FILE="$CONFIG_DIR/timestamps.txt"


# Create config directory if it doesn't exist
#mkdir -p "$CONFIG_DIR"

# Initialize files if they don't exist
touch "$REPO_FILE" "$TIMESTAMP_FILE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display menu
show_menu() {
    echo -e "\n${BLUE}=== GitHub Issue Monitor ===${NC}"
    echo "1. Check for new issues"
    echo "2. Add repository"
    echo "3. Remove repository"
    echo "4. List monitored repositories"
    echo "5. Exit"
    echo -n "Select option: "
}

# Function to add repository
add_repository() {
    echo -n "Enter repository (format: owner/repo): "
    read repo
    
    # Validate format
    if [[ ! "$repo" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Invalid format! Use: owner/repo${NC}"
        return 1
    fi
    
    # Check if already exists
    if grep -q "^$repo$" "$REPO_FILE" 2>/dev/null; then
        echo -e "${YELLOW}Repository already in list${NC}"
        return 1
    fi
    
    # Add to file
    echo "$repo" >> "$REPO_FILE"
    echo -e "${GREEN}Repository added successfully${NC}"
    
    # Initialize timestamp
    echo "$repo:$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$TIMESTAMP_FILE"
}

# Function to remove repository
remove_repository() {
    if [ ! -s "$REPO_FILE" ]; then
        echo -e "${RED}No repositories to remove${NC}"
        return 1
    fi
    
    echo -e "\n${BLUE}Current repositories:${NC}"
    nl -b a "$REPO_FILE"
    
    echo -n "Enter line number to remove (0 to cancel): "
    read line_num
    
    if [[ "$line_num" == "0" ]]; then
        return 0
    fi
    
    if [[ ! "$line_num" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid input${NC}"
        return 1
    fi
    
    repo=$(sed -n "${line_num}p" "$REPO_FILE")
    if [ -z "$repo" ]; then
        echo -e "${RED}Invalid line number${NC}"
        return 1
    fi
    
    # Remove from both files
    sed -i.bak "${line_num}d" "$REPO_FILE"
    sed -i.bak "/^$repo:/d" "$TIMESTAMP_FILE"
    
    echo -e "${GREEN}Repository removed successfully${NC}"
}

# Function to list repositories
list_repositories() {
    if [ ! -s "$REPO_FILE" ]; then
        echo -e "${YELLOW}No repositories being monitored${NC}"
        return 1
    fi
    
    echo -e "\n${BLUE}Monitored repositories:${NC}"
    cat "$REPO_FILE" | while read repo; do
        echo "  - $repo"
    done
}

# Function to get last check timestamp for a repo
get_last_timestamp() {
    local repo=$1
    grep "^$repo:" "$TIMESTAMP_FILE" 2>/dev/null | cut -d: -f2- | tail -1 || echo "1970-01-01T00:00:00Z"
}

# Function to update timestamp for a repo
update_timestamp() {
    local repo=$1
    local new_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Remove old timestamp and add new one
    
    sed -i.bak "\|^$repo:|d" "$TIMESTAMP_FILE"
    echo "$repo:$new_time" >> "$TIMESTAMP_FILE"
}

# Function to check for new issues
check_new_issues() {
    if [ ! -s "$REPO_FILE" ]; then
        echo -e "${YELLOW}No repositories to check${NC}"
        return 1
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed${NC}"
        echo "Install with: sudo apt-get install jq (Ubuntu) or brew install jq (Mac)"
        return 1
    fi
    
    echo -e "\n${BLUE}Checking for new issues...${NC}\n"
    
    local found_new=false
    
    while IFS= read -r repo; do
        [ -z "$repo" ] && continue
        
        echo -e "${YELLOW}Checking $repo...${NC}"
        
        last_check=$(get_last_timestamp "$repo")
        last_check_encoded=$(echo "$last_check" | sed 's/:/%3A/g')
        
        # GitHub API URL for issues
        api_url="https://api.github.com/repos/$repo/issues?state=open&sort=created&direction=desc&since=$last_check_encoded"
        
        # Fetch issues (using authentication if available)
        if [ -n "$GITHUB_TOKEN" ]; then
            response=$(curl -L -s \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: Bearer $GITHUB_TOKEN" \
                -H "X-GitHub-Api-Version: 2022-11-28" \
                -H "User-Agent: github-issue-monitor/1.0" \
                "$api_url")
        else
            response=$(curl -L -s \
                -H "Accept: application/vnd.github+json" \
                -H "X-GitHub-Api-Version: 2022-11-28" \
                -H "User-Agent: github-issue-monitor/1.0" \
                "$api_url")
        fi

        # # Add debug information
        # echo "  Debug: API URL: $api_url"
        # echo "  Debug: Response length: ${#response}"
        # echo "  Debug: First 200 chars: ${response:0:200}"
        
        # Check for API errors
        if echo "$response" | jq -e '.message' >/dev/null 2>&1; then
            error_msg=$(echo "$response" | jq -r '.message')
            echo -e "${RED}  Error: $error_msg${NC}"
            
            if [[ "$error_msg" == *"rate limit"* ]]; then
                echo -e "${YELLOW}  Set GITHUB_TOKEN environment variable to increase rate limit${NC}"
            fi
            continue
        fi
        
        # Parse and display new issues
        issue_count=$(echo "$response" | jq 'length')

        # Validate that issue_count is actually a number
        if ! [[ "$issue_count" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}  Error: Invalid API response - cannot determine issue count${NC}"
            echo -e "${YELLOW}  Response preview: ${response:0:200}...${NC}"
            continue
        fi
        
        if [ "$issue_count" -gt 0 ]; then
            found_new=true
            echo -e "${GREEN}  Found $issue_count new issue(s):${NC}"
            
            echo "$response" | jq -r '.[] | 
                select(.pull_request == null) | 
                "    [#\(.number)] \(.title)\n      URL: \(.html_url)\n      Created: \(.created_at)\n"'
        else
            echo "  No new issues"
        fi
        
        # Update timestamp
        update_timestamp "$repo"
        
        echo ""
        
        # Small delay to avoid rate limiting
        sleep 1
        
    done < "$REPO_FILE"
    
    if [ "$found_new" = false ]; then
        echo -e "${BLUE}No new issues found in any repository${NC}"
    fi
}

# Main loop
while true; do
    show_menu
    read choice
    
    case $choice in
        1)
            check_new_issues
            ;;
        2)
            add_repository
            ;;
        3)
            remove_repository
            ;;
        4)
            list_repositories
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