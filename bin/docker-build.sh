#!/bin/sh

set -e

# Check if verbose logging is enabled (default: true)
VERBOSE_LOGGING=${VERBOSE_LOGGING:-true}

# Logging function
log_info() {
    if [ "$VERBOSE_LOGGING" = "true" ]; then
        echo "[BUILD] $1"
    fi
}

log_error() {
    echo "[BUILD] ERROR: $1" >&2
}

log_info "=== BUILD PHASE STARTED ==="

# Remove build complete flag if it exists
[ -f "${BUILD_COMPLETE_FLAG}" ] && rm "${BUILD_COMPLETE_FLAG}"

# Check if GITHUB_REPO_URL is provided
if [ -z "$GITHUB_REPO_URL" ]; then
    log_error "GITHUB_REPO_URL environment variable is required"
    log_error "Format: https://TOKEN@github.com/username/repository.git"
    exit 1
fi

log_info "Repository URL: ${GITHUB_REPO_URL}"

# Function to force pull from remote (handles force pushes)
force_pull() {
    log_info "Force pulling from remote..."
    git fetch origin
    git reset --hard origin/main
    git clean -fd # Remove untracked files
}

# Check if we need to build
BUILD_NEEDED=false

# Check if repository exists
if [ -d "${GITHUB_REPO}" ] && [ -d "${GITHUB_REPO}/.git" ]; then
    echo "[BUILD] Repository exists. Checking for updates..."
    cd ${GITHUB_REPO}

    # Get current commit hash
    CURRENT_COMMIT=$(git rev-parse HEAD)
    echo "[BUILD] --- Current commit: $CURRENT_COMMIT"
    echo "[BUILD] $CURRENT_COMMIT" >${CURRENT_COMMIT_FILE}

    # Fetch latest changes
    git fetch origin

    # Get latest commit hash
    LATEST_COMMIT=$(git rev-parse origin/main)
    echo "[BUILD] ---  Latest commit: $LATEST_COMMIT"
    echo "[BUILD] $LATEST_COMMIT" >${LAST_COMMIT_FILE}

    # Check if there are new commits
    if [ "$CURRENT_COMMIT" != "$LATEST_COMMIT" ]; then

        echo "[BUILD] Resetting existing build..."
        git reset --hard HEAD

        echo "[BUILD] New commits found. Force updating repository..."
        # Handle force pushes by resetting to remote
        force_pull

        # Check if the update was successful
        if git status --porcelain | grep -q "^UU\|^AA\|^DD"; then
            echo "[BUILD] Warning: Merge conflicts detected. Using current version."
        else
            echo "[BUILD] Repository updated successfully."
            BUILD_NEEDED=true
        fi
    else
        echo "[BUILD] Repository is up to date."

        # Check if build exists
        if [ ! -d "${APP_BUILD}" ] || [ ! -f "${APP_BUILD}/server/index.mjs" ]; then
            echo "[BUILD] Build directory missing or incomplete. Rebuild needed."
            BUILD_NEEDED=true
        else
            echo "[BUILD] Build exists and is up to date."
        fi
    fi
else
    echo "[BUILD] Repository not found. Checking if folder exists without .git..."

    # Check if folder exists but without .git
    if [ -d "${GITHUB_REPO}" ] && [ ! -d "${GITHUB_REPO}/.git" ]; then
        echo "[BUILD] Folder exists but .git is missing. Cloning .git only..."

        # Clone to temporary directory
        TEMP_REPO="${GITHUB_REPO}_temp"
        git clone "$GITHUB_REPO_URL" ${TEMP_REPO}

        # Move .git folder to existing directory
        mv ${TEMP_REPO}/.git ${GITHUB_REPO}/.git

        # Remove temporary directory
        rm -rf ${TEMP_REPO}

        # Change to repo directory and reset
        cd ${GITHUB_REPO}
        git reset --hard HEAD
        git clean -fd
    else
        echo "[BUILD] Cloning repository for the first time..."

        # Clone the repository
        git clone "$GITHUB_REPO_URL" ${GITHUB_REPO}
        cd ${GITHUB_REPO}
    fi

    BUILD_NEEDED=true
fi

# Build if needed
if [ "$BUILD_NEEDED" = true ]; then
    echo "[BUILD] Building application..."

    # # Remove build complete flag if it exists
    # [ -f "${BUILD_COMPLETE_FLAG}" ] && rm "${BUILD_COMPLETE_FLAG}"

    # Install bun if not already installed
    if ! command -v bun >/dev/null 2>&1; then
        echo "[BUILD] Installing bun..."
        npm install -g bun
    fi

    echo "[BUILD] --- Running \`bun run ci\`..."
    bun run ci

    echo "[BUILD] Waiting for generated output folder to be created..."
    while [ ! -d "${APP_OUTPUT}" ]; do
        sleep 2
    done
    echo "[BUILD] Generated output folder created."

    echo "[BUILD] Build completed successfully!"
else
    echo "[BUILD] No build needed. Using existing build."
fi

# if [ -d "${GITHUB_REPO}/.data" ]; then
#     rsync -av --ignore-existing ${GITHUB_REPO}/.data/. ${APP_ROOT}/.data
# else
#     echo "[BUILD] \`${GITHUB_REPO}/.data\` directory not found. Skipping..."
# fi

echo "[BUILD] === BUILD PHASE COMPLETED ==="

# Signal that build is complete and app can start
touch ${BUILD_COMPLETE_FLAG}

supervisorctl restart app
