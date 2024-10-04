#!/bin/bash

# Hard-coded repository URL
REPO_URL="https://github.com/djzaxh/vero.git"

# Step 1: Backup current directory
BACKUP_DIR="$(pwd)_backup"
echo "Backing up current directory to ${BACKUP_DIR}..."
cp -r "$(pwd)" "${BACKUP_DIR}"

# Step 2: Check if it's a Git repository
if [ ! -d .git ]; then
    echo "This directory is not a Git repository. Initializing..."
    git init
fi

# Step 3: Remove existing remote if it exists
if git remote get-url origin > /dev/null 2>&1; then
    echo "Removing existing remote origin..."
    git remote remove origin
fi

# Step 4: Add the existing remote repository
echo "Adding existing remote repository at ${REPO_URL}..."
git remote add origin "${REPO_URL}"

# Step 5: Check if remote repository has any branches
echo "Checking if any branches exist on the remote repository..."
if git ls-remote --heads origin | grep -q 'refs/heads/'; then
    # Branches exist, now pull
    echo "Branches found on remote. Pulling latest changes from 'main' or 'master' branch..."

    # Check if main or master branch exists
    BRANCH="main"
    if ! git ls-remote --exit-code --heads origin main; then
        if git ls-remote --exit-code --heads origin master; then
            BRANCH="master"
            echo "Using 'master' branch."
        else
            echo "Neither 'main' nor 'master' branch found on remote."
            exit 1
        fi
    else
        echo "Using 'main' branch."
    fi

    # Pull latest changes
    if ! git pull origin "$BRANCH" --allow-unrelated-histories; then
        echo "Error during pull. Restoring from backup..."

        # Remove conflicting directories before restoring the backup
        echo "Removing existing conflicting directories..."
        rm -rf .git
        rm -rf venv

        mv "${BACKUP_DIR}"/* "$(pwd)"
        rm -rf "${BACKUP_DIR}"
        exit 1
    fi
else
    # No branches exist on the remote
    echo "No branches found on remote. Creating an initial commit locally..."

    # Create an initial commit if there is no commit yet
    git add .
    git commit -m "Initial commit"
    BRANCH="main"
    git branch -M "$BRANCH"
fi

# Step 6: Handle versioning using VERSION.txt
VERSION_FILE="VERSION.txt"
if [ ! -f "$VERSION_FILE" ]; then
    echo "VERSION.txt not found. Creating a new one with version 1.0.1..."
    echo "1.0.1" > "$VERSION_FILE"
fi

# Read the current version and increment the patch version (Z)
CURRENT_VERSION=$(cat "$VERSION_FILE")
IFS='.' read -r -a version_parts <<< "$CURRENT_VERSION"

# Increment the patch version (Z)
new_patch_version=$((version_parts[2] + 1))

# Update the version to X.Y.Z format
NEW_VERSION="${version_parts[0]}.${version_parts[1]}.$new_patch_version"
echo "Updating version to $NEW_VERSION..."
echo "$NEW_VERSION" > "$VERSION_FILE"

# Step 7: Add all files and commit
echo "Adding files to the repository..."
git add .

# Use version as part of the commit message
COMMIT_MSG="Update to version $NEW_VERSION"
echo "Committing files with message: ${COMMIT_MSG}"
git commit -m "${COMMIT_MSG}"

# Step 8: Push to the remote repository
echo "Pushing code to GitHub..."
if ! git push -u origin "$BRANCH"; then
    echo "Error during push. Restoring from backup..."

    # Remove conflicting directories before restoring the backup
    echo "Removing existing conflicting directories..."
    rm -rf .git
    rm -rf venv

    mv "${BACKUP_DIR}"/* "$(pwd)"
    rm -rf "${BACKUP_DIR}"
    exit 1
fi

# If everything went well, delete the backup
echo "Setup complete! Your code has been pushed to ${REPO_URL}."
echo "Deleting backup directory..."
rm -rf "${BACKUP_DIR}"

echo "Backup deleted successfully."