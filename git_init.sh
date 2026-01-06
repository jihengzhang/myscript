
#!/usr/bin/env bash
# Git initialization and GitHub push script
# Usage: ./git_init.sh <github_url> [commit_message]

set -euo pipefail

GITHUB_URL="${1:-}"
COMMIT_MSG="${2:-Initial commit}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { printf '\n[%s] %s\n' "$(date +'%H:%M:%S')" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*"; }
info() { printf "${YELLOW}[INFO]${NC} %s\n" "$*"; }

show_help() {
	cat <<'EOF'
Git Repository Initialization Script

Usage: ./git_init.sh <github_url> [commit_message]

Arguments:
  github_url        GitHub repository URL (HTTPS or SSH)
  commit_message    Commit message (default: "Initial commit")

Examples:
  ./git_init.sh https://github.com/jihengzhang/myscript.git
  ./git_init.sh git@github.com:jihengzhang/myscript.git
  ./git_init.sh https://github.com/jihengzhang/myscript.git "Add initial files"

Features:
  - Initializes git repository
  - Configures user identity
  - Adds all files
  - Creates initial commit
  - Configures GitHub remote
  - Pushes to GitHub (supports both HTTPS and SSH)

Requirements:
  - git must be installed
  - GitHub account with created repository
  - Network access to GitHub
EOF
}

# Check if git is installed
if ! command -v git &> /dev/null; then
	error "Git is not installed. Please install git first."
	return  1
fi

# Show help if no arguments or -h
if [[ -z "$GITHUB_URL" ]] || [[ "$GITHUB_URL" == "-h" ]] || [[ "$GITHUB_URL" == "--help" ]]; then
	show_help
	return  0
fi

# Validate GitHub URL format and detect protocol
if [[ "$GITHUB_URL" =~ ^https://github\.com/.+/.+\.git$ ]]; then
	USE_SSH=false
	info "Using HTTPS protocol"
elif [[ "$GITHUB_URL" =~ ^git@github\.com:.+/.+\.git$ ]]; then
	USE_SSH=true
	info "Using SSH protocol"
else
	error "Invalid GitHub URL format."
	error "Expected: https://github.com/user/repo.git (HTTPS)"
	error "       or git@github.com:user/repo.git (SSH)"
	error "Got: $GITHUB_URL"
	return  1
fi

log "Initializing Git repository..."

# Step 1: Initialize git repository if not already done
if [[ ! -d ".git" ]]; then
	git init
	success "Git repository initialized"
else
	info "Git repository already exists"
fi

# Step 2: Configure git user if not already configured globally
if ! git config --global user.email &>/dev/null; then
	log "Configuring git user identity..."
	read -p "Enter your email: " email
	read -p "Enter your name: " name
	git config --global user.email "$email"
	git config --global user.name "$name"
	success "Git user configured globally"
else
	info "Git user already configured: $(git config --global user.name) <$(git config --global user.email)>"
fi

# Step 3: Add all files
log "Staging files..."
git add .
success "Files staged"

# Step 4: Create commit
log "Creating commit..."
git commit -m "$COMMIT_MSG" || info "Nothing to commit or commit already exists"
success "Commit created"

# Step 5: Configure remote
log "Configuring GitHub remote..."
if git remote get-url origin &>/dev/null; then
	log "Remote already exists, updating..."
	git remote set-url origin "$GITHUB_URL"
else
	git remote add origin "$GITHUB_URL"
fi
success "Remote configured: $GITHUB_URL"

# Step 6: Enable credential storage for HTTPS only
if [[ "$USE_SSH" == "false" ]]; then
	log "Enabling credential storage for HTTPS..."
	git config --global credential.helper store
	success "Credential helper configured"
else
	log "Verifying SSH authentication..."
	if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
		success "SSH authentication verified"
	else
		error "SSH authentication failed. Please set up SSH keys:"
		error "  ssh-keygen -t ed25519 -C 'your_email@example.com'"
		error "  cat ~/.ssh/id_ed25519.pub  # Add this to GitHub Settings > SSH Keys"
		return 1
	fi
fi

# Step 7: Push to GitHub
log "Pushing to GitHub..."
if git push -u origin main; then
	success "Code pushed to GitHub successfully!"
	info "Repository: $GITHUB_URL"
elif git push -u origin master; then
	success "Code pushed to GitHub successfully (master branch)!"
	info "Repository: $GITHUB_URL"
else
	error "Failed to push to GitHub"
	error "Check your network connection and GitHub repository URL"
	return  1
fi

log "Git initialization complete!"
success "Your repository is now on GitHub"
