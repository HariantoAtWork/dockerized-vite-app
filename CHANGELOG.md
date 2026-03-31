# Changelog

All notable changes to this project will be documented in this file.

## [2025-09-09T15:45:05+0200]

### Added
- Extended configurable logging system to all three scripts: `docker-build.sh`, `docker-run.sh`, and `docker-watch.sh`
- Implemented consistent `log_info()` and `log_error()` functions across all scripts
- Added unified logging control with single `VERBOSE_LOGGING` environment variable

### Changed
- Updated `docker-run.sh` to use new logging functions for all informational messages
- Updated `docker-watch.sh` to use new logging functions for all informational messages
- Modified error messages in watch script to use `log_error()` function (always visible)
- Updated informational messages in all scripts to use `log_info()` function (conditional)

### Technical Details
- All scripts now use `VERBOSE_LOGGING=${VERBOSE_LOGGING:-true}` with default value
- `log_info()` only outputs when `VERBOSE_LOGGING=true` in all scripts
- `log_error()` always outputs to stderr regardless of verbose setting in all scripts
- Set `VERBOSE_LOGGING=false` in `.env` to disable verbose logging across all scripts (errors only)
- Consistent logging prefixes: `[BUILD]`, `[RUN]`, `[WATCH]` for easy log filtering

## [2025-09-09T15:42:54+0200]

### Added
- Added configurable logging system with `VERBOSE_LOGGING` environment variable
- Implemented `log_info()` and `log_error()` functions for conditional logging
- Added logging configuration documentation to README.md

### Changed
- Updated build script to use new logging functions for better log control
- Modified error messages to use `log_error()` function (always visible)
- Updated informational messages to use `log_info()` function (conditional)

### Technical Details
- Added `VERBOSE_LOGGING=${VERBOSE_LOGGING:-true}` with default value
- `log_info()` only outputs when `VERBOSE_LOGGING=true`
- `log_error()` always outputs to stderr regardless of verbose setting
- Set `VERBOSE_LOGGING=false` in `.env` to disable verbose logging (errors only)

## [2025-09-09T15:11:14+0200]

### Added
- Created comprehensive README.md with complete project documentation
- Added detailed setup instructions for development and production environments
- Documented architecture, process management, and deployment procedures
- Included troubleshooting guide and monitoring instructions
- Added environment variable documentation and configuration examples

### Fixed
- Corrected environment variable configuration to properly distinguish between `.env` (Docker variables) and `.env.app` (application variables)
- Updated documentation to reflect the correct usage of `.env` for Docker environment variables and `.env.app` for application-specific variables

### Changed
- Updated package manager documentation to reflect Bun as primary and pnpm as alternative
- Reordered volume creation commands to prioritise Bun cache
- Updated build process description to clarify Bun as the primary package manager

## [2025-09-08T11:40:48+0200]

### Fixed
- Fixed inconsistent supervisord readiness check in `docker-watch.sh` by using `supervisorctl version` instead of `status`
- Resolved issue where script would wait indefinitely due to exit code 3 from `supervisorctl status`

### Changed
- Updated supervisord readiness check to use `supervisorctl version` which always returns exit code 0 when accessible
- Simplified the check from complex exit code handling to a simple accessibility test
- Removed debug logging as it's no longer needed

### Technical Details
- Discovered that `supervisorctl status` returns exit code 3 when some processes are EXITED/STOPPED (normal state)
- Changed from `while ! supervisorctl status >/dev/null 2>&1` to `while ! supervisorctl version >/dev/null 2>&1`
- `supervisorctl version` only fails (exit code ≠ 0) when supervisord is not accessible, making it perfect for readiness check
- This allows the script to proceed as soon as supervisorctl commands are functional, regardless of individual process states

## [2025-09-07T23:13:15+0200]

### Added
- Added smart repository recovery for cases where folder exists but `.git` directory is missing
- Implemented efficient `.git`-only cloning using temporary directory approach

### Changed
- Updated repository cloning logic to handle corrupted or incomplete git repositories
- Added logging prefixes `[BUILD]` to all build script messages for better log readability
- Changed `bun install` to `bun ci` for faster, more reliable dependency installation
- Commented out rsync operations for build and data copying (can be re-enabled if needed)

### Technical Details
- Added check for `[ -d "${GITHUB_REPO}" ] && [ ! -d "${GITHUB_REPO}/.git" ]` condition
- Implemented temporary clone approach: clone to temp dir, move `.git`, remove temp dir
- Uses `git reset --hard HEAD && git clean -fd` to restore clean working directory
- All build messages now prefixed with `[BUILD]` for better log filtering

## [2025-09-04T21:58:58+0200]

### Added
- Added force pull functionality to handle `git push -f` scenarios in `docker-build.sh`
- Created `force_pull()` function that uses `git fetch origin` and `git reset --hard origin/main`

### Changed
- Updated git pull logic to use force pull when new commits are detected
- Replaced `git pull origin main` with `force_pull()` function for better force push handling

### Technical Details
- Added `force_pull()` function: `git fetch origin && git reset --hard origin/main && git clean -fd`
- This handles scenarios where remote repository has been force pushed (`git push -f`)
- Ensures local repository is always in sync with remote, even after history rewrites

## [2025-09-04T19:52:27+0200]

### Fixed
- Fixed supervisord socket configuration by adding missing `[unix_http_server]` and `[supervisorctl]` sections
- Improved supervisord readiness check in `docker-watch.sh` to use `supervisorctl status` instead of socket file check
- Resolved infinite wait issue for supervisord socket

### Changed
- Added explicit socket configuration in `supervisord.conf`: `file=/run/supervisord.sock`
- Updated watch script to check supervisord readiness with `supervisorctl status` command
- Reverted to nodemon in `docker-run.sh` as per user preference

### Technical Details
- Added `[unix_http_server]` section with `file=/run/supervisord.sock` and `chmod=0700`
- Added `[supervisorctl]` section with `serverurl=unix:///run/supervisord.sock`
- Changed socket wait from file check to functional check: `while ! supervisorctl status >/dev/null 2>&1; do sleep 1; done`

## [2025-09-04T19:22:21+0200]

### Fixed
- Fixed supervisorctl socket issue in `docker-watch.sh` by adding socket wait before using supervisorctl commands
- Updated `docker-run.sh` to use Bun instead of nodemon for better performance and built-in watch functionality

### Changed
- Replaced `nodemon --watch ${APP_OUTPUT} --cwd ${APP_ROOT} .output/server/index.mjs` with `bun --watch ${APP_OUTPUT} --exec "bun ${APP_OUTPUT}/server/index.mjs"`
- Added socket availability check in watch script to prevent "no such file" errors

### Technical Details
- Added `while [ ! -S /run/supervisord.sock ]; do sleep 1; done` to wait for supervisord socket
- Updated server startup to use Bun's built-in watch mode instead of external nodemon
- Maintained backward compatibility with commented alternatives
