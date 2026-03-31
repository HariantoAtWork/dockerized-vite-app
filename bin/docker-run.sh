#!/bin/sh

# Check if verbose logging is enabled (default: true)
VERBOSE_LOGGING=${VERBOSE_LOGGING:-true}

# Logging function
log_info() {
    if [ "$VERBOSE_LOGGING" = "true" ]; then
        echo "[RUN] $1"
    fi
}

log_error() {
    echo "[RUN] ERROR: $1" >&2
}

log_info "=== RUN PHASE STARTED ==="

# Wait for build to complete
log_info "Waiting for build to complete..."
while [ ! -f "${BUILD_COMPLETE_FLAG}" ]; do
    sleep 2
done

log_info "Build complete. Starting application..."

log_info "Waiting for Vite dist output to be created..."
while [ ! -d "${APP_DIST}" ]; do
    sleep 2
done

# Change to repository directory (where scripts/deps are installed)
cd ${GITHUB_REPO}

# Start the Vite preview server (defaults to port 4173)
log_info "Starting Vite preview server on 0.0.0.0 (default port)..."
exec bun run preview -- --host 0.0.0.0
