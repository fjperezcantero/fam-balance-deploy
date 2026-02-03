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

show_help() {
    echo "Usage: ./deploy.sh [target]"
    echo ""
    echo "Targets:"
    echo "  all       Deploy everything (default)"
    echo "  backend   Deploy only PHP/Laravel backend"
    echo "  frontend  Deploy only Next.js frontend"
    echo "  help      Show this help message"
}

# Check if .env exists
if [ ! -f ".env" ]; then
    log_error ".env file not found. Copy .env.example to .env and configure it."
    exit 1
fi

# Load environment variables
source .env

TARGET="${1:-all}"

case "$TARGET" in
    backend)
        log_info "Deploying backend only..."

        if [ ! -d "../fam-balance" ]; then
            log_error "fam-balance directory not found at ../fam-balance"
            exit 1
        fi

        log_info "Updating fam-balance..."
        cd ../fam-balance
        git pull origin master
        cd "$SCRIPT_DIR"

        log_info "Building and starting PHP container..."
        docker compose build php
        docker compose up -d php nginx

        log_info "Running Laravel migrations..."
        docker compose exec php php artisan migrate --force

        log_info "Clearing Laravel cache..."
        docker compose exec php php artisan config:cache
        docker compose exec php php artisan route:cache
        docker compose exec php php artisan view:cache

        log_info "Backend deployment complete!"
        ;;

    frontend)
        log_info "Deploying frontend only..."

        if [ ! -d "../fam-balance-ui" ]; then
            log_error "fam-balance-ui directory not found at ../fam-balance-ui"
            exit 1
        fi

        log_info "Updating fam-balance-ui..."
        cd ../fam-balance-ui
        git pull origin master
        cd "$SCRIPT_DIR"

        log_info "Building and starting Next.js container..."
        docker compose build nextjs
        docker compose up -d nextjs nginx

        log_info "Frontend deployment complete!"
        ;;

    all)
        log_info "Deploying everything..."

        if [ ! -d "../fam-balance" ]; then
            log_error "fam-balance directory not found at ../fam-balance"
            exit 1
        fi

        if [ ! -d "../fam-balance-ui" ]; then
            log_error "fam-balance-ui directory not found at ../fam-balance-ui"
            exit 1
        fi

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

        log_info "Building and starting containers..."
        docker compose build --no-cache
        docker compose up -d

        log_info "Running Laravel migrations..."
        docker compose exec php php artisan migrate --force

        log_info "Clearing Laravel cache..."
        docker compose exec php php artisan config:cache
        docker compose exec php php artisan route:cache
        docker compose exec php php artisan view:cache

        log_info "Full deployment complete!"
        log_info "Services:"
        log_info "  - Frontend (Next.js): https://fjperezcantero.es"
        log_info "  - API (Laravel): https://api.fjperezcantero.es"
        log_info "  - Legacy Web (Laravel Blade): https://fam-balance.fjperezcantero.es"
        ;;

    help|--help|-h)
        show_help
        exit 0
        ;;

    *)
        log_error "Unknown target: $TARGET"
        show_help
        exit 1
        ;;
esac

# Show container status
docker compose ps
