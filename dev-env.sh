#!/bin/bash
source ./utils.sh
check_dependencies tmux nvim lazygit fzf sed find



DEV_FOLDER="$HOME/Documents"
# Check if the development folder exists
if [ ! -d "$DEV_FOLDER" ]; then
    echo "Projects folder not found: ${DEV_FOLDER}"
    exit 1
fi

# List directories inside the development folder
mapfile -t PROJECTS < <(
    find "$DEV_FOLDER" -mindepth 2 -maxdepth 8 -type d -name ".git" \
    | sed "s|/\.git||" | sed "s|$DEV_FOLDER/||"
)
# Check if there are any projects
if [ ${#PROJECTS[@]} -eq 0 ]; then
    echo "No projects found in $DEV_FOLDER"
    exit 1
fi

# Function to let the user select a project
select_project() {
    if command -v fzf >/dev/null 2>&1; then
        # Use fzf if installed
        echo "${PROJECTS[@]}" | tr ' ' '\n' | fzf
    else
        # Fallback to a numbered menu
        echo "Select a project:"
        for i in "${!PROJECTS[@]}"; do
            echo "[$((i + 1))] ${PROJECTS[$i]}"
        done
        read -p "Enter number: " choice
        if [[ $choice =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#PROJECTS[@]}" ]; then
            echo "${PROJECTS[$((choice - 1))]}"
        else
            echo "Invalid selection."
            exit 1
        fi
    fi
}

# Get the selected project
PROJECT_FULL_PATH=$(select_project)

# Ensure a project was selected
if [ -z "$PROJECT_FULL_PATH" ]; then
    echo "No project selected. Exiting."
    exit 1
fi



PARENT=$(basename "$(dirname "$PROJECT_FULL_PATH")")
CHILD=$(basename "$PROJECT_FULL_PATH")
SESH="${PARENT}/${CHILD}"

# Check if the tmux session exists
tmux has-session -t "$SESH" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "Attaching to existing tmux session: $SESH"
else
    echo "Creating new tmux session: $SESH"
    tmux new-session -d -s $SESH -n "editor"

    tmux send-keys -t $SESH:editor "cd ${DEV_FOLDER}/${PROJECT_FULL_PATH}" C-m
    tmux send-keys -t $SESH:editor "nvim ." C-m

    tmux new-window -t $SESH -n "lazygit"
    tmux send-keys -t $SESH:lazygit "cd ${DEV_FOLDER}/${PROJECT_FULL_PATH}" C-m
    tmux send-keys -t $SESH:lazygit "lazygit" C-m

    tmux new-window -t $SESH -n "terminal"
    tmux send-keys -t $SESH:terminal "cd ${DEV_FOLDER}/${PROJECT_FULL_PATH}" C-m
    
    tmux select-window -t $SESH:editor

fi

tmux attach-session -t $SESH
