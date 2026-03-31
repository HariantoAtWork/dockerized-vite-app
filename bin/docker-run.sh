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

log_info "Waiting for generated output folder to be created..."
while [ ! -d "${APP_OUTPUT}" ]; do
    sleep 2
done

# Change to repository directory (where dependencies are properly installed)
cd ${APP_ROOT}

# Start the Node.js server from the .output directory
log_info "Starting NODEMON for Node.js server..."
exec nodemon --watch ${APP_OUTPUT} --cwd ${APP_ROOT} .output/server/index.mjs
# Alternative: exec bun --watch "${APP_OUTPUT}/server/index.mjs"
# Alternative: exec node ${APP_ROOT}/.output/server/index.mjs
