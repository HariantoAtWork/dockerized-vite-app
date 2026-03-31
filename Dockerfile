# Use Node.js 22 Alpine as base image
FROM node:22-alpine AS base

# Environment variables #1
ENV CI=1
ENV BETTER_AUTH_TELEMETRY=0
ENV BETTER_AUTH_TELEMETRY_DEBUG=0

# Environment variables #2
ENV APP_ROOT="/app"
ENV GITHUB_REPO="/app"
ENV APP_BUILD="${GITHUB_REPO}/.output"
ENV APP_OUTPUT="${APP_ROOT}/.output"
ENV CURRENT_COMMIT_FILE="${APP_ROOT}/.current_commit"
ENV LAST_COMMIT_FILE="${APP_ROOT}/.last_commit"
ENV BUILD_COMPLETE_FLAG="${APP_ROOT}/.build-complete.flag"
ENV PROJECT_BUILD_SCRIPT="${GITHUB_REPO}/scripts/build.sh"

# Install git, wget, supervisor, and rsync
RUN apk add --no-cache git wget supervisor rsync

# Set working directory
WORKDIR ${APP_ROOT}

# Install pnpm
RUN npm install -g bun pnpm nodemon
# > Use PNPM STORAGE CACHE: /root/.local/share/pnpm
# > Use BUN STORAGE CACHE: /root/.bun/install/cache

# --- SCRIPTS ---
FROM base AS scripts

# Copy all scripts
COPY bin/ /usr/local/bin/
# Make all scripts executable
RUN chmod +x /usr/local/bin/*

# Copy supervisord configuration
COPY conf.d/supervisord.conf /etc/supervisord.conf

# Create log directory
RUN mkdir -p /var/log/supervisor

# --- FINAL ---
FROM scripts AS final

# Expose port 3000
EXPOSE 3000

# Start supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
