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
    echo "Usage: ./dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  up        Start development environment (default)"
    echo "  down      Stop development environment"
    echo "  restart   Restart all services"
    echo "  logs      Show logs (follow mode)"
    echo "  build     Rebuild containers"
    echo "  migrate   Run Laravel migrations"
    echo "  shell     Open bash shell in PHP container"
    echo "  status    Show container status"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./dev.sh              # Start dev environment"
    echo "  ./dev.sh logs php     # Show PHP container logs"
    echo "  ./dev.sh shell        # Access PHP container shell"
}

# Verify required directories exist
check_directories() {
    if [ ! -d "../fam-balance" ]; then
        log_error "fam-balance directory not found at ../fam-balance"
        exit 1
    fi

    if [ ! -d "../fam-balance-ui" ]; then
        log_error "fam-balance-ui directory not found at ../fam-balance-ui"
        exit 1
    fi
}

# Create .env if it doesn't exist
ensure_env() {
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            log_warn ".env not found, copying from .env.example"
            cp .env.example .env
        else
            log_warn ".env not found, creating with defaults"
            cat > .env << 'EOF'
# Development environment variables
DB_ROOT_PASSWORD=root
DB_DATABASE=fam_balance
DB_USERNAME=fam_balance
DB_PASSWORD=fam_balance
NEXT_PUBLIC_API_URL=http://fjperezcantero.local:8080/api/v1
EOF
        fi
    fi
}

cmd_up() {
    check_directories
    ensure_env

    log_info "Starting development environment..."
    docker compose -f docker-compose.dev.yml up -d

    log_info "Waiting for services to be ready..."
    sleep 3

    log_info "Development environment started!"
    echo ""
    log_info "Services available at:"
    log_info "  - Web:   http://localhost:8080"
    log_info "  - MySQL: localhost:3307"
    echo ""
    log_info "Run './dev.sh logs' to see container logs"
    log_info "Run './dev.sh migrate' to run Laravel migrations"

    docker compose -f docker-compose.dev.yml ps
}

cmd_down() {
    log_info "Stopping development environment..."
    docker compose -f docker-compose.dev.yml down
    log_info "Development environment stopped."
}

cmd_restart() {
    log_info "Restarting development environment..."
    docker compose -f docker-compose.dev.yml restart
    log_info "Development environment restarted."
}

cmd_logs() {
    shift || true
    docker compose -f docker-compose.dev.yml logs -f "$@"
}

cmd_build() {
    check_directories
    ensure_env

    log_info "Rebuilding containers..."
    docker compose -f docker-compose.dev.yml build "$@"
    log_info "Build complete."
}

cmd_migrate() {
    log_info "Running Laravel migrations..."
    docker compose -f docker-compose.dev.yml exec php php artisan migrate
    log_info "Migrations complete."
}

cmd_shell() {
    docker compose -f docker-compose.dev.yml exec php bash
}

cmd_status() {
    docker compose -f docker-compose.dev.yml ps
}

# Main command handler
case "${1:-up}" in
    up)
        cmd_up
        ;;
    down)
        cmd_down
        ;;
    restart)
        cmd_restart
        ;;
    logs)
        cmd_logs "$@"
        ;;
    build)
        shift || true
        cmd_build "$@"
        ;;
    migrate)
        cmd_migrate
        ;;
    shell)
        cmd_shell
        ;;
    status)
        cmd_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
