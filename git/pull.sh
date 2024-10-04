#!/bin/bash

# Hard-coded repository URL
REPO_URL="https://github.com/djzaxh/Vero.git"

# Change to your project direct
# Check if it's a Git repository
if [ ! -d .git ]; then
    echo "This directory is not a Git repository. Exiting..."
    exit 1
fi

# Ensure you are on the correct branch
git checkout main || { echo "Failed to switch to main branch. Exiting..."; exit 1; }

# Fetch the latest changes
echo "Fetching latest changes from the remote repository..."
git fetch origin

# Reset local changes to match the remote
echo "Resetting local changes to match the remote..."
git reset --hard origin/main  # or origin/master if that's your branch

# Clean untracked files
echo "Cleaning untracked files..."
git clean -fd

echo "Your local directory has been updated with the latest code from ${REPO_URL}."