# RCMD (Rclone Commander)

> A modern web-based and desktop GUI application for managing Rclone cloud storage operations

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://www.docker.com/)
[![SvelteKit](https://img.shields.io/badge/SvelteKit-2.22-orange?logo=svelte)](https://kit.svelte.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0-blue?logo=typescript)](https://www.typescriptlang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🎯 Overview

RCMD is a comprehensive orchestration platform for managing personal cloud storage services through Rclone. It provides both web-based and desktop interfaces for seamless file operations between local/remote and remote-to-remote transfers.

### Key Features

- **🌐 Dual Platform**: Web service and Electron desktop application
- **☁️ Multi-Cloud**: Support for 101+ cloud storage providers via Rclone
- **📁 File Management**: Intuitive file browser with drag-and-drop support
- **🔄 Transfer Queue**: Real-time transfer monitoring and management
- **🛡️ Security**: Built-in authentication and permission management
- **🐳 Docker Ready**: Containerized for easy deployment

### Target Scale

- **101+** cloud storage remotes
- **~500TB** data processing capacity
- **Multi-user** enterprise support

## 🚀 Quick Start

### Prerequisites

- Docker
- Docker Compose

### Development Environment

```bash
# Start development server with hot reload
# (automatically uses compose.override.yaml for development)
docker compose up

# Access development server
open http://localhost:5173
```

### Production Environment

```bash
# Start production server (only compose.yaml)
COMPOSE_FILE=compose.yaml docker compose up

# Access production server
open http://localhost:3000
```

### Interactive Development

```bash
# Access container shell for development
docker compose run --rm app

# Inside container
npm ci                    # Install dependencies
npm run dev -- --host    # Start development server
npm run build            # Production build
npm run check            # Type checking
```

## 🏗️ Architecture

### Technology Stack

- **Frontend**: SvelteKit 2.22 + TypeScript 5.0
- **Backend**: Node.js 18 + SvelteKit SSR
- **Database**: SQLite (default) / PostgreSQL (enterprise)
- **Desktop**: Electron (planned)
- **Container**: Docker + Alpine Linux

### Database Auto-Detection

```bash
# PostgreSQL (auto-enabled when available)
POSTGRES_URL=postgresql://user:pass@host:5432/dbname

# SQLite (default, no configuration needed)
# Automatically used when PostgreSQL is not configured
```

## 📁 Project Structure

```
rcmd/
├── src/                          # SvelteKit source code
├── static/                       # Static assets
├── claudedocs/                   # Project documentation
│   ├── readme.md                 # Documentation index
│   ├── development-setup.md      # Development guide
│   └── *.md                      # Technical specifications
├── compose.yaml                  # Docker production
├── compose.override.yaml         # Docker development
├── Dockerfile                    # Multi-stage build
├── entrypoint.sh                 # Container entrypoint
├── .env.example                  # Environment template
└── package.json                  # Project configuration
```

## 🛠️ Development

### Environment Configuration

Copy the example environment file and configure your settings:

```bash
cp .env.example .env
```

Edit `.env` with your specific configuration:

```env
# Docker permissions
PUID=1000    # Your user ID (run: id -u)
PGID=1000    # Your group ID (run: id -g)

# Allow external domains for reverse proxy
VITE_ALLOWED_HOSTS=rcmd.example.com,.example.com,.local
```

### Useful Commands

```bash
# Development
docker compose up -d                             # Start dev server (background)
docker compose logs -f                           # View logs

# Production
docker compose up -d                              # Start prod server (background)

# Maintenance
docker compose down                               # Stop containers
docker compose build --no-cache                  # Rebuild images
docker compose down -v --remove-orphans          # Clean reset
```

## 📖 Documentation

Comprehensive documentation is available in the [`claudedocs/`](./claudedocs/) directory:

- **[Development Setup](./claudedocs/development-setup.md)** - Complete environment setup guide
- **[Project Status](./claudedocs/project-current-status.md)** - Current implementation status
- **[Technical Architecture](./claudedocs/technical-architecture-design.md)** - System architecture design
- **[API Specification](./claudedocs/api-specification.md)** - RESTful API documentation
- **[Database Schema](./claudedocs/database-schema-data-model.md)** - Data model specifications

## 🔄 Current Status

### ✅ Infrastructure Complete (100%)

- **Docker Environment**: Development/production containers configured
- **Permission Management**: PUID/PGID automatic mapping
- **Database System**: SQLite/PostgreSQL auto-detection
- **Build System**: Multi-stage Docker builds
- **Security**: NPM audit and optimizations complete

### 🚧 In Progress

- **Phase**: Core functionality implementation
- **Target MVP**: October 15, 2025 (3 weeks)
- **Focus**: Rclone integration, file browser UI, transfer queue system

## 🤝 Contributing

1. **Setup**: Follow the [Development Setup Guide](./claudedocs/development-setup.md)
2. **Architecture**: Review [Technical Architecture](./claudedocs/technical-architecture-design.md)
3. **Development**: Use Docker environment for consistent builds
4. **Documentation**: Update relevant docs in `claudedocs/`

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Rclone**: [https://rclone.org/](https://rclone.org/)
- **SvelteKit**: [https://kit.svelte.dev/](https://kit.svelte.dev/)
- **Docker**: [https://www.docker.com/](https://www.docker.com/)

---

**Author**: Textrix (t3xtrix@gmail.com)
**Last Updated**: 2025-09-28