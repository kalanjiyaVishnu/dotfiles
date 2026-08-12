#!/bin/bash

# Function to run a command in the background and store its PID
run_in_background() {
  nohup "$@" > /dev/null 2>&1 &
  echo $! > "$background_pid_file"
}

# Function to kill the background process
kill_background() {
  if [ -f "$background_pid_file" ]; then
    pid=$(cat "$background_pid_file")
    if [ -n "$pid" ]; then
      kill -TERM "$pid" > /dev/null 2>&1
      rm -f "$background_pid_file"
    fi
  fi
}

# Check if the number of arguments is correct
if [ $# -ne 1 ]; then
  echo "Usage: $0 <branch>"
  exit 1
fi

# Store the branch argument
branch="$1"

# Get the directory path from the environment variable $KB_HOME
kb_home="$KB_HOME"

# Check if $KB_HOME is set and not empty
if [ -z "$kb_home" ]; then
  echo "Environment variable \$KB_HOME is not set or empty."
  exit 1
fi

# Extract the directory path and remove the "bin" part
directory=$(dirname "$kb_home")

# Check if the specified directory exists
if [ ! -d "$directory" ]; then
  echo "Directory $directory does not exist."
  exit 1
fi

# Check if the branch argument is valid
valid_branches=("master" "qa" "prod" "preprod")

if [[ ! " ${valid_branches[@]} " =~ " $branch " ]]; then
  echo "Invalid branch. Please specify one of: ${valid_branches[*]}"
  exit 1
fi

# Change to the specified directory
cd "$directory" || exit 1

# Check if it's a Git repository
if [ ! -d ".git" ]; then
  echo "Not a Git repository in $directory."
  exit 1
fi

# Create a temporary file to store the background process PID
background_pid_file="/tmp/background_process_pid_$$.txt"

# Run the kibana.sh script in the background and store its PID
run_in_background "$kb_home/kibana.sh"

# Trap to ensure we kill the background process when the script exits
trap 'kill_background' EXIT

# Change the Git branch
git checkout "$branch" || exit 1

# Optionally, you can switch back to the original branch
# git checkout -

# Add your command here, e.g., to build or run tests
# your_command_here

# Sleep to keep the script running while the background process runs
# Adjust the sleep time as needed or replace with appropriate logic

