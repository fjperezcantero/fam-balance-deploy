# Fam Balance Deploy

Deployment configuration for the Fam Balance application stack.

## Architecture

```
                         ┌─────────────────┐
                         │   nginx-proxy   │
                         │  (80/443 + SSL) │
                         └────────┬────────┘
                                  │
                         ┌────────┴────────┐
                         │      nginx      │
                         │ (internal routing)│
                         └────────┬────────┘
                                  │
    ┌─────────────────────────────┼─────────────────────────────┐
    │                             │                             │
    ▼                             ▼                             ▼
fjperezcantero.es          api.fjperezcantero.es      fam-balance.fjperezcantero.es
    │                             │                             │
    ▼                             ▼                             ▼
  nextjs:3000                  php-fpm                       php-fpm
  (New frontend)           (Laravel API)              (Legacy Laravel web)
```

## Prerequisites

- Docker and Docker Compose installed
- The following repositories cloned as siblings:
  ```
  /home/ubuntu/
  ├── fam-balance/         # Backend Laravel
  ├── fam-balance-ui/      # Frontend Next.js
  └── fam-balance-deploy/  # This repo
  ```

## Setup

1. Clone all repositories:
   ```bash
   git clone <fam-balance-repo> fam-balance
   git clone <fam-balance-ui-repo> fam-balance-ui
   git clone <fam-balance-deploy-repo> fam-balance-deploy
   ```

2. Configure environment:
   ```bash
   cd fam-balance-deploy
   cp .env.example .env
   # Edit .env with your values
   ```

3. Configure Laravel `.env` in the `fam-balance` directory

4. Deploy:
   ```bash
   ./deploy.sh
   ```

## Local Development

For local testing without SSL and nginx-proxy:

```bash
# Start local development stack
docker compose -f docker-compose.dev.yml up -d

# Access the application at http://localhost:8080
# - Frontend: http://localhost:8080
# - API: http://localhost:8080/api
# - MySQL: localhost:3307

# Stop local development
docker compose -f docker-compose.dev.yml down
```

## Manual Commands

```bash
# Start all services (production)
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f nginx
docker compose logs -f php
docker compose logs -f nextjs

# Rebuild specific service
docker compose build nextjs
docker compose up -d nextjs

# Run Laravel artisan commands
docker compose exec php php artisan migrate
docker compose exec php php artisan tinker

# Access MySQL
docker compose exec mysql mysql -u root -p
```

## Domains

- `fjperezcantero.es` - New Next.js frontend
- `api.fjperezcantero.es` - Laravel API endpoints
- `fam-balance.fjperezcantero.es` - Legacy Laravel web (Blade views)

## SSL Certificates

SSL certificates are automatically provisioned via Let's Encrypt using the nginx-proxy companion container.

## Troubleshooting

### Containers not starting
Check logs: `docker compose logs`

### SSL not working
- Ensure DNS is properly configured for all domains
- Check Let's Encrypt logs: `docker compose logs letsencrypt`
- Verify the LETSENCRYPT_EMAIL is set correctly

### Database connection issues
- Verify DB credentials in `.env`
- Check if MySQL container is healthy: `docker compose ps`
- Check MySQL logs: `docker compose logs mysql`
