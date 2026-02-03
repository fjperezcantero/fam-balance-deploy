#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env exists
if [ ! -f ".env" ]; then
    log_error ".env file not found. Copy .env.example to .env and configure it."
    exit 1
fi

# Load environment variables
source .env

# Verify required directories exist
if [ ! -d "../fam-balance" ]; then
    log_error "fam-balance directory not found at ../fam-balance"
    exit 1
fi

if [ ! -d "../fam-balance-ui" ]; then
    log_error "fam-balance-ui directory not found at ../fam-balance-ui"
    exit 1
fi

# Pull latest changes from all repos
log_info "Pulling latest changes..."

log_info "Updating fam-balance..."
cd ../fam-balance
git pull origin master

log_info "Updating fam-balance-ui..."
cd ../fam-balance-ui
git pull origin master

log_info "Updating fam-balance-deploy..."
cd "$SCRIPT_DIR"
git pull origin master

# Build and deploy
log_info "Building and starting containers..."
docker compose build --no-cache
docker compose up -d

# Run Laravel migrations
log_info "Running Laravel migrations..."
docker compose exec php php artisan migrate --force

# Clear Laravel cache
log_info "Clearing Laravel cache..."
docker compose exec php php artisan config:cache
docker compose exec php php artisan route:cache
docker compose exec php php artisan view:cache

log_info "Deployment complete!"
log_info "Services:"
log_info "  - Frontend (Next.js): https://fjperezcantero.es"
log_info "  - API (Laravel): https://api.fjperezcantero.es"
log_info "  - Legacy Web (Laravel Blade): https://fam-balance.fjperezcantero.es"

# Show container status
docker compose ps
