# Vite (Vue) Docker Application

A containerised Vite (Vue) application with automated Git-based deployment, continuous monitoring, and intelligent build management using Docker Compose and Supervisor.

## 🚀 Features

- **Automated Git Deployment**: Automatically clones and updates from GitHub repositories
- **Smart Build Management**: Only rebuilds when new commits are detected
- **Continuous Monitoring**: Watches for repository changes and triggers automatic rebuilds
- **Process Management**: Uses Supervisor to manage multiple processes (build, app, watcher)
- **Persistent Storage**: Maintains application data and build cache across container restarts
- **Health Checks**: Built-in health monitoring for the application
- **Development & Production**: Separate configurations for development and production environments

## 📋 Prerequisites

- Docker and Docker Compose
- Git access to your Vite (Vue) repository
- GitHub Personal Access Token (for private repositories)

## 🛠️ Quick Start

### 1. Environment Setup

Create a `.env` file for Docker environment variables:

```bash
# Docker environment variables
GITHUB_REPO_URL=https://YOUR_TOKEN@github.com/username/repository.git
DOCKER_HUB_IMAGE=your-registry/vite-app:latest

# Logging Configuration
VERBOSE_LOGGING=true  # Set to false to disable verbose logging (only show errors)
```

Create a `.env.app` file for application-specific environment variables:

```bash
# Application environment variables
NODE_ENV=production
# Add your Vite app-specific variables here
# e.g., API_URL, DATABASE_URL, etc.
```

### 2. Create Required Volumes

```bash
# Create external volumes for caching
docker volume create bun-cache
docker volume create pnpm-store
```

### 3. Start the Application

```bash
# Development
docker-compose up -d

# Production
docker-compose -f docker-compose.production.yml up -d
```

The application will be available at `http://localhost:3300`

## 🏗️ Architecture

### Container Structure

The application uses a multi-stage Docker build with the following components:

- **Base Image**: Node.js 22 Alpine
- **Package Managers**: Bun (primary), pnpm (alternative)
- **Process Manager**: Supervisor
- **Preview Server**: `vite preview`

### Process Management

Supervisor manages three main processes:

1. **Build Process** (`docker-build.sh`)
   - Clones/updates the Git repository
   - Installs dependencies using Bun (primary package manager)
   - Builds the Vite application (`bun run build`)
   - Manages build state and completion flags

2. **Application Process** (`docker-run.sh`)
   - Waits for build completion
   - Starts the Vite preview server (`bun run preview`)

3. **Watcher Process** (`docker-watch.sh`)
   - Monitors repository for new commits
   - Triggers automatic rebuilds when changes are detected
   - Manages application restarts

### Directory Structure

```
/app/                    # Application root
├── dist/               # Built application output (Vite)
├── .current_commit     # Current commit hash
├── .last_commit        # Latest commit hash
├── .build-complete.flag # Build completion flag
└── [repository]/      # Cloned Git repository
```

## 🔧 Configuration

### Environment Variables

#### Docker Environment (`.env`)
| Variable | Description | Required |
|----------|-------------|----------|
| `GITHUB_REPO_URL` | GitHub repository URL with token | Yes |
| `DOCKER_HUB_IMAGE` | Docker image for production | Production only |
| `VERBOSE_LOGGING` | Enable verbose logging (true/false) | No (default: true) |

#### Application Environment (`.env.app`)
| Variable | Description | Required |
|----------|-------------|----------|
| `NODE_ENV` | Node.js environment | Yes |
| `API_URL` | API endpoint URL | Optional |
| `DATABASE_URL` | Database connection string | Optional |
| `SECRET_KEY` | Application secret key | Optional |

### Volume Mounts

- `./data/app:/app` - Application data persistence
- `./data/data:/data` - Additional data storage
- `bun-cache:/root/.bun/install/cache` - Bun cache (primary)
- `pnpm-store:/root/.local/share/pnpm` - pnpm cache (alternative)

### Port Configuration

- **Container**: 4173 (internal, Vite preview default)
- **Host**: 3300 (external)

## 📝 Scripts

### Build Script (`docker-build.sh`)

Handles repository cloning, dependency installation, and application building:

- Smart repository recovery for corrupted `.git` directories
- Force pull support for handling `git push -f` scenarios
- Incremental builds (only when new commits detected)
- Build state management with completion flags

### Run Script (`docker-run.sh`)

Manages application startup:

- Waits for build completion
- Starts the Vite preview server on `0.0.0.0:4173` (default)

### Watch Script (`docker-watch.sh`)

Monitors repository changes:

- Checks for new commits every minute
- Triggers automatic rebuilds
- Manages application restarts
- Handles supervisord readiness checks

## 🚀 Deployment

### Development Deployment

```bash
# Start development environment
docker-compose up -d

# View logs
docker-compose logs -f

# Stop environment
docker-compose down
```

### Production Deployment

```bash
# Build and push image
docker build -t your-registry/nuxt-app:latest .
docker push your-registry/nuxt-app:latest

# Deploy using production compose
docker-compose -f docker-compose.production.yml up -d
```

### Health Monitoring

The application includes built-in health checks:

```bash
# Check container health
docker-compose ps

# View health check logs
docker inspect dockerized-vite-app_vite-app_1 | grep -A 10 Health
```

## 🔍 Monitoring & Logs

### Supervisor Logs

```bash
# View all supervisor logs
docker-compose exec vite-app tail -f /var/log/supervisor/supervisord.log

# View specific process logs
docker-compose exec vite-app tail -f /var/log/supervisor/build.log
docker-compose exec vite-app tail -f /var/log/supervisor/app.log
docker-compose exec vite-app tail -f /var/log/supervisor/watcher.log
docker-compose exec vite-app tail -f /var/log/supervisor/build.log /var/log/supervisor/app.log /var/log/supervisor/watcher.log
```

### Process Management

```bash
# Check supervisor status
docker-compose exec vite-app supervisorctl status

# Restart specific process
docker-compose exec vite-app supervisorctl restart app

# Restart all processes
docker-compose exec vite-app supervisorctl restart all
```

## 🛠️ Troubleshooting

### Common Issues

1. **Repository Access Issues**
   ```bash
   # Ensure GITHUB_REPO_URL includes token in .env file
   GITHUB_REPO_URL=https://YOUR_TOKEN@github.com/username/repo.git
   ```

2. **Build Failures**
   ```bash
   # Check build logs
   docker-compose exec vite-app tail -f /var/log/supervisor/build.log
   ```

3. **Application Not Starting**
   ```bash
   # Check if build completed
   docker-compose exec vite-app ls -la /app/.build-complete.flag
   
   # Check app logs
   docker-compose exec vite-app tail -f /var/log/supervisor/app.log
   ```

4. **Watcher Not Working**
   ```bash
   # Check watcher logs
   docker-compose exec vite-app tail -f /var/log/supervisor/watcher.log
   
   # Check supervisor status
   docker-compose exec vite-app supervisorctl status
   ```

### Manual Operations

```bash
# Force rebuild
docker-compose exec vite-app supervisorctl restart build

# Manual repository update
docker-compose exec vite-app sh
cd /app/[repository]
git pull origin main
```

## 📚 Development

### Adding New Features

1. Update your Vite application in the repository
2. Commit and push changes
3. The watcher will automatically detect changes and rebuild
4. Monitor logs to ensure successful deployment

### Custom Build Scripts

The system expects a `scripts/build.sh` file in your repository for custom build processes.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:

- Check the troubleshooting section above
- Review the logs for error messages
- Ensure all prerequisites are met
- Verify environment variables are correctly set

---

**Last Updated**: 2025-09-09T15:11:14+0200
