# Development Setup

This project uses Docker for both development and production environments.

## Prerequisites

- Docker
- Docker Compose

## Quick Start

### Development Environment

```bash
# Start development environment with hot reload
docker compose -f compose.override.yaml up

# Or run in detached mode
docker compose -f compose.override.yaml up -d
```

The development server will be available at:
- Application: http://localhost:5173
- Container name: `rcmd-dev`

### Production Environment

```bash
# Build and run production environment
docker compose up

# Or run in detached mode
docker compose up -d
```

The production server will be available at:
- Application: http://localhost:3000
- Container name: `rcmd`

## Development Workflow

### Interactive Development

```bash
# Enter development container shell
docker compose -f compose.override.yaml run --rm app

# Inside container, you can run:
npm ci                    # Install dependencies
npm run dev -- --host    # Start development server
npm run build            # Build for production
npm run check            # Type checking
```

### Project Creation (Initial Setup)

```bash
# Create new SvelteKit project
docker compose run --rm app npx -y sv create .
```

## Environment Variables

Configure your environment by editing `.env`:

```env
PUID=1000    # User ID for file permissions
PGID=1000    # Group ID for file permissions
```

## Docker Architecture

### Multi-stage Build

- **base**: Common Alpine Linux setup with Node.js
- **dev**: Development environment with Claude Code CLI
- **build**: Production build stage
- **prod**: Optimized production runtime

### Key Features

- **Permission Mapping**: Automatic PUID/PGID handling for file permissions
- **Hot Reload**: Volume mounting for live development
- **Health Checks**: Built-in application monitoring
- **Security**: NPM audit and production optimizations

## Useful Commands

```bash
# View logs
docker compose logs -f

# Stop all containers
docker compose down

# Rebuild containers
docker compose build --no-cache

# Clean up
docker compose down -v --remove-orphans
docker system prune -f
```

## Troubleshooting

### Permission Issues
Ensure PUID/PGID in `.env` match your host user:
```bash
id -u    # Get your user ID
id -g    # Get your group ID
```

### Port Conflicts
If ports 3000 or 5173 are in use, modify the port mappings in `compose.yaml` or `compose.override.yaml`.

### Container Not Starting
Check logs for detailed error information:
```bash
docker compose logs app
```