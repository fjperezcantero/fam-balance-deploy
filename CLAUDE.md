# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Docker Compose deployment configuration** for the Fam Balance full-stack application. It orchestrates three separate repositories into a single deployment stack:

- **fam-balance/** - Laravel backend (API + legacy Blade views)
- **fam-balance-ui/** - Next.js frontend
- **fam-balance-deploy/** - This repository (infrastructure config)

## Architecture

```
nginx-proxy (SSL termination)
    ↓
nginx (request routing)
    ├── fjperezcantero.es → Next.js (port 3000)
    ├── api.fjperezcantero.es → Laravel API (php-fpm:9000)
    └── fam-balance.fjperezcantero.es → Laravel web (php-fpm:9000)
        ↓
    MySQL 8.0
```

## Commands

### Development
```bash
docker compose -f docker-compose.dev.yml up -d    # Start dev stack (localhost:8080)
docker compose -f docker-compose.dev.yml down     # Stop dev stack
```

### Production
```bash
./deploy.sh                                       # Full deployment (pull, build, migrate)
docker compose up -d                              # Start production stack
docker compose down                               # Stop production stack
```

### Service Management
```bash
docker compose logs -f [service]                  # View logs (php, nextjs, nginx, mysql)
docker compose build [service]                    # Rebuild specific service
docker compose exec php php artisan [cmd]         # Run Laravel Artisan commands
docker compose exec mysql mysql -u root -p        # Access MySQL shell
```

## Key Configuration Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Production config with SSL and multi-domain routing |
| `docker-compose.dev.yml` | Local development config on localhost:8080 |
| `deploy.sh` | Automated deployment script |
| `nginx/default.conf` | Production nginx routing rules |
| `nginx/default.dev.conf` | Development nginx routing rules |
| `php/Dockerfile` | PHP 8.4-FPM with Laravel extensions |
| `nextjs/Dockerfile` | Multi-stage Next.js build |

## Environment Variables

Required in `.env`:
- `DOMAINS` - Comma-separated domain list for nginx-proxy
- `LETSENCRYPT_EMAIL` - SSL certificate registration email
- `DB_*` - MySQL credentials (ROOT_PASSWORD, DATABASE, USERNAME, PASSWORD)
- `NEXT_PUBLIC_API_URL` - API URL passed to Next.js at build time

## Docker Networks

- `web` - External network connecting to nginx-proxy for SSL
- `internal` - Internal service communication network

## Nginx Routing Logic

The nginx config routes requests based on path:
- `/api/*`, `/storage/*`, `/sanctum/*` → Laravel backend
- Everything else → Next.js frontend
- API subdomain receives all traffic to Laravel
- Legacy domain serves Laravel Blade views with static asset caching
