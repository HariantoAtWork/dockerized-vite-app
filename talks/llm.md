# Building a Self-Updating Nuxt.js Application with Docker and Supervisord

## Project Overview

This project represents an innovative approach to deploying and maintaining a Nuxt.js application with automatic updates and zero-downtime deployments. The system is designed around a containerised architecture that automatically pulls updates from a GitHub repository and rebuilds the application without manual intervention.

## Architecture Highlights

### Core Concept: Self-Updating Container
The application is built as a Docker container that contains not just the application, but also the entire build and deployment pipeline. This creates a truly self-contained system that can:

- Automatically clone and update from a GitHub repository
- Build the Nuxt.js application using modern tooling (Bun, pnpm)
- Monitor for changes and trigger rebuilds
- Maintain zero-downtime during updates

### Technology Stack

**Runtime Environment:**
- Node.js 22 Alpine Linux
- Bun (modern JavaScript runtime)
- pnpm (fast package manager)
- Supervisord (process management)

**Application Framework:**
- Nuxt.js (Vue.js framework)
- Better Auth (authentication system)
- SQLite/PostgreSQL database support
- SMTP email integration
- Social authentication (Google, GitHub)

**Infrastructure:**
- Docker containerisation
- Docker Compose orchestration
- External volume caching for dependencies
- Health checks and automatic restarts

## System Architecture

### Three-Phase Process Management

The system operates through three distinct phases managed by Supervisord:

#### 1. Build Phase (`docker-build.sh`)
- **Purpose**: Initial setup and application building
- **Process**: 
  - Clones the GitHub repository using provided credentials
  - Handles repository recovery for corrupted or incomplete clones
  - Implements force-pull functionality for handling `git push -f` scenarios
  - Runs `bun run ci` for dependency installation
  - Waits for build completion and signals readiness

#### 2. Run Phase (`docker-run.sh`)
- **Purpose**: Application execution
- **Process**:
  - Waits for build completion signal
  - Starts the Nuxt.js server using nodemon for development
  - Monitors the `.output` directory for changes
  - Provides hot-reload capabilities

#### 3. Watch Phase (`docker-watch.sh`)
- **Purpose**: Continuous monitoring and updates
- **Process**:
  - Monitors the repository for new commits every minute
  - Triggers rebuilds when updates are detected
  - Manages graceful restarts of the application
  - Handles the complete update cycle automatically

### Smart Repository Management

The system includes sophisticated repository handling:

**Repository Recovery:**
```bash
# Handles cases where folder exists but .git is missing
if [ -d "${GITHUB_REPO}" ] && [ ! -d "${GITHUB_REPO}/.git" ]; then
    # Clone to temporary directory, move .git, clean up
    TEMP_REPO="${GITHUB_REPO}_temp"
    git clone "$GITHUB_REPO_URL" ${TEMP_REPO}
    mv ${TEMP_REPO}/.git ${GITHUB_REPO}/.git
    rm -rf ${TEMP_REPO}
fi
```

**Force Push Handling:**
```bash
# Handles git push -f scenarios
force_pull() {
    git fetch origin
    git reset --hard origin/main
    git clean -fdx
}
```

## Configuration and Environment

### Environment Variables
The system supports comprehensive configuration through environment variables:

- **Authentication**: Better Auth secret and telemetry settings
- **Database**: SQLite or PostgreSQL configuration
- **Email**: SMTP settings for notifications
- **Social Auth**: Google and GitHub OAuth credentials
- **Docker**: Platform and image registry settings
- **GitHub**: Repository access with personal access tokens

### Docker Compose Configuration

**Development Mode:**
- Builds from local Dockerfile
- Uses development environment variables
- Includes volume mounts for persistent data

**Production Mode:**
- Uses pre-built Docker Hub images
- Optimised for production deployment
- Includes health checks and restart policies

## Key Features

### 1. Zero-Downtime Updates
The system ensures continuous availability by:
- Building new versions in parallel
- Using supervisorctl to manage process restarts
- Implementing health checks to verify service availability

### 2. Intelligent Caching
External Docker volumes are used for:
- pnpm package cache (`pnpm-store`)
- Bun installation cache (`bun-cache`)
- Significantly faster rebuild times

### 3. Robust Error Handling
- Repository corruption recovery
- Merge conflict detection
- Build failure handling
- Process monitoring and restart capabilities

### 4. Development-Friendly
- Hot reload with nodemon
- Real-time logging with prefixed messages
- Comprehensive debugging information
- Flexible environment configuration

## Deployment Workflow

### Initial Setup
1. Configure environment variables in `.env.app`
2. Set up GitHub repository with personal access token
3. Create external Docker volumes for caching
4. Run `docker-compose up` for development or production

### Automatic Update Cycle
1. **Detection**: Watch script detects new commits
2. **Build**: Triggers rebuild process
3. **Deploy**: Restarts application with new version
4. **Verify**: Health checks ensure successful deployment

## Security Considerations

- GitHub personal access tokens for repository access
- Environment variable isolation
- Container-based security boundaries
- Supervisord process isolation
- Health check endpoints for monitoring

## Performance Optimisations

- **Bun Runtime**: Faster JavaScript execution
- **pnpm**: Efficient package management
- **Volume Caching**: Persistent dependency caches
- **Alpine Linux**: Minimal container footprint
- **Multi-stage Docker Build**: Optimised image layers

## Monitoring and Logging

The system provides comprehensive logging through Supervisord:
- Build process logs (`/var/log/supervisor/build.log`)
- Application logs (`/var/log/supervisor/app.log`)
- Watch process logs (`/var/log/supervisor/watcher.log`)
- Prefixed log messages for easy filtering

## Use Cases

This architecture is particularly suitable for:

- **Development Environments**: Automatic updates from feature branches
- **Staging Servers**: Continuous deployment from main branch
- **Production Applications**: Controlled updates with monitoring
- **Microservices**: Self-contained service deployment
- **Edge Computing**: Autonomous update capabilities

## Future Enhancements

Potential improvements could include:
- Webhook-based updates instead of polling
- Blue-green deployment strategies
- Database migration handling
- Rollback capabilities
- Metrics and monitoring integration

## Conclusion

This project demonstrates a sophisticated approach to containerised application deployment that prioritises automation, reliability, and developer experience. By combining modern JavaScript tooling with robust process management, it creates a system that can maintain itself with minimal human intervention while providing the flexibility needed for both development and production environments.

The architecture showcases how Docker, Supervisord, and modern JavaScript runtimes can be combined to create truly autonomous deployment systems that adapt to the needs of modern web applications.
