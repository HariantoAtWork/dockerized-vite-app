#!/bin/sh

# Check if verbose logging is enabled (default: true)
VERBOSE_LOGGING=${VERBOSE_LOGGING:-true}

# Logging function
log_info() {
    if [ "$VERBOSE_LOGGING" = "true" ]; then
        echo "[WATCH] $1"
    fi
}

log_error() {
    echo "[WATCH] ERROR: $1" >&2
}

log_info "=== WATCH PHASE STARTED ==="

# Wait for supervisord to be ready by checking if supervisorctl works
log_info "Waiting for supervisord to be ready..."
while ! supervisorctl version >/dev/null 2>&1; do
    sleep 1
done

log_info "Supervisord is ready. Proceeding with watch phase..."

# Wait for initial build to complete
log_info "Waiting for initial build to complete..."
while [ ! -f "${BUILD_COMPLETE_FLAG}" ]; do
    sleep 5
done

log_info "Starting update watcher..."

# Function to restart the app process
restart_app() {
    # Check if app is already running
    APP_STATUS=$(supervisorctl status app 2>/dev/null | awk '{print $2}')

    if [ "$APP_STATUS" = "RUNNING" ]; then
        log_info "Application is already running. Skipping restart."
        return 0
    elif [ "$APP_STATUS" = "STOPPED" ] || [ "$APP_STATUS" = "EXITED" ]; then
        log_info "Application is stopped. Starting..."
        supervisorctl start app
    else
        log_info "Application status unknown ($APP_STATUS). Restarting..."
        supervisorctl restart app
    fi
}

# Main watch loop
while true; do
    log_info "Checking for updates..."

    # Check if repository exists
    if [ -d "${GITHUB_REPO}" ] && [ -d "${GITHUB_REPO}/.git" ]; then
        cd ${GITHUB_REPO}

        git reset --hard HEAD

        # Get current commit hash
        CURRENT_COMMIT=$(git rev-parse HEAD)
        log_info "Current commit: $CURRENT_COMMIT"
        echo "[WATCH] $CURRENT_COMMIT" >${CURRENT_COMMIT_FILE}

        # Fetch latest changes
        git fetch origin

        # Get latest commit hash
        LATEST_COMMIT=$(git rev-parse origin/main)
        log_info "Latest commit: $LATEST_COMMIT"
        echo "[WATCH] $LATEST_COMMIT" >${LAST_COMMIT_FILE}

        # Check if there are new commits
        if [ "$CURRENT_COMMIT" != "$LATEST_COMMIT" ]; then
            log_info "New commits found! Triggering rebuild..."

            echo "[WATCH] Resetting existing build..."
            # git reset --hard HEAD

            # Pull latest changes
            # git pull origin main

            # -----
            log_info "Repository updated successfully. Rebuilding..."
            # rm -rf ${BUILD_COMPLETE_FLAG}

            # Stop the app
            # supervisorctl stop app

            # Trigger rebuild
            log_info "Restarting build..."
            supervisorctl restart build

            # Wait for build to complete
            log_info "Waiting for build to complete..."
            while [ ! -f "${BUILD_COMPLETE_FLAG}" ]; do
                sleep 2
            done

            # Start the app
            restart_app

            log_info "--- Application restarted with latest changes!"

            #-----

            # Check for merge conflicts
            # if git status --porcelain | grep -q "^UU\|^AA\|^DD"; then
            #     echo "[WATCH] Warning: Merge conflicts detected. Skipping update."
            # else
            #     echo "[WATCH] Repository updated successfully. Rebuilding..."
            #     rm -rf ${BUILD_COMPLETE_FLAG}

            #     # Stop the app
            #     # supervisorctl stop app

            #     # Trigger rebuild
            #     supervisorctl restart build

            #     # Wait for build to complete
            #     echo "[WATCH] Waiting for build to complete..."
            #     while [ ! -f "${BUILD_COMPLETE_FLAG}" ]; do
            #         sleep 2
            #     done

            #     # Start the app
            #     # supervisorctl start app

            #     echo "[WATCH] --- Application restarted with latest changes!"
            # fi
        else
            log_info "No updates available."
        fi
    else
        log_error "Repository not found. Skipping update check."
    fi

    # Wait 5 minutes before next check
    log_info "Waiting 1 minute before next check..."
    sleep 60
done
