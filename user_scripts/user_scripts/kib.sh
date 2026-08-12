#!/bin/bash

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

# Change the Git branch
git checkout "$branch" || exit 1

# Execute your desired command here
# For example, let's echo the current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "Switched to branch: $current_branch"

# Add your command here, e.g., to build or run tests
"$KB_HOME/kibana"

# Optionally, you can switch back to the original branch
# git checkout -

exit 0

