#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
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

log_cmd() {
    echo -e "${CYAN}[CMD]${NC} $1"
}

show_help() {
    echo "Usage: ./cleanup.sh [options]"
    echo ""
    echo "Cleans up unused Docker images and build cache on the remote server."
    echo ""
    echo "Options:"
    echo "  -a, --all       Remove all unused images, not just dangling ones"
    echo "  -f, --force     Skip confirmation prompts"
    echo "  -d, --dry-run   Show what would be deleted without actually deleting"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Required .env variables:"
    echo "  SSH_HOST        Remote server hostname or IP"
    echo "  SSH_USER        SSH username"
    echo ""
    echo "Authentication (one of):"
    echo "  SSH_KEY         Path to SSH private key"
    echo "  SSH_PASS_FILE   Path to file containing SSH password (requires sshpass)"
}

# Check if .env exists
if [ ! -f ".env" ]; then
    log_error ".env file not found. Copy .env.example to .env and configure it."
    exit 1
fi

# Load environment variables
source .env

# Validate SSH configuration
if [ -z "$SSH_HOST" ]; then
    log_error "SSH_HOST not configured in .env"
    exit 1
fi

if [ -z "$SSH_USER" ]; then
    log_error "SSH_USER not configured in .env"
    exit 1
fi

# Build SSH command
SSH_OPTS="-o StrictHostKeyChecking=accept-new"
if [ -n "$SSH_KEY" ]; then
    SSH_CMD="ssh $SSH_OPTS -i $SSH_KEY $SSH_USER@$SSH_HOST"
elif [ -n "$SSH_PASS_FILE" ]; then
    if ! command -v sshpass &> /dev/null; then
        log_error "sshpass is required for password authentication. Install with: sudo apt install sshpass"
        exit 1
    fi
    if [ ! -f "$SSH_PASS_FILE" ]; then
        log_error "SSH password file not found: $SSH_PASS_FILE"
        exit 1
    fi
    SSH_CMD="sshpass -f $SSH_PASS_FILE ssh $SSH_OPTS $SSH_USER@$SSH_HOST"
else
    SSH_CMD="ssh $SSH_OPTS $SSH_USER@$SSH_HOST"
fi

# Parse arguments
ALL_IMAGES=false
FORCE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            ALL_IMAGES=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Test SSH connection
log_info "Testing SSH connection to $SSH_USER@$SSH_HOST..."
if ! $SSH_CMD "echo 'Connection successful'" > /dev/null 2>&1; then
    log_error "Failed to connect to $SSH_USER@$SSH_HOST"
    exit 1
fi
log_info "SSH connection OK"

# Show current disk usage
log_info "Current disk usage on server:"
$SSH_CMD "df -h / | tail -1"

echo ""

# Show Docker disk usage before cleanup
log_info "Docker disk usage before cleanup:"
$SSH_CMD "docker system df"

echo ""

if [ "$DRY_RUN" = true ]; then
    log_warn "DRY RUN MODE - No changes will be made"
    echo ""
fi

# Confirmation prompt
if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}This will remove:${NC}"
    echo "  - Stopped containers"
    echo "  - Unused networks"
    echo "  - Dangling images"
    if [ "$ALL_IMAGES" = true ]; then
        echo "  - ALL unused images (not just dangling)"
    fi
    echo "  - Build cache"
    echo ""
    read -p "Continue? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled"
        exit 0
    fi
fi

# Build prune commands
PRUNE_FLAGS=""
if [ "$FORCE" = true ]; then
    PRUNE_FLAGS="-f"
fi

IMAGE_PRUNE_FLAGS="$PRUNE_FLAGS"
if [ "$ALL_IMAGES" = true ]; then
    IMAGE_PRUNE_FLAGS="$IMAGE_PRUNE_FLAGS -a"
fi

if [ "$DRY_RUN" = true ]; then
    # Dry run - just show what would be removed
    log_info "Images that would be removed:"
    log_cmd "docker image ls --filter 'dangling=true'"
    $SSH_CMD "docker image ls --filter 'dangling=true'" || true

    if [ "$ALL_IMAGES" = true ]; then
        echo ""
        log_info "All unused images:"
        log_cmd "docker image ls"
        $SSH_CMD "docker image ls" || true
    fi

    echo ""
    log_info "Containers that would be removed:"
    log_cmd "docker container ls -a --filter 'status=exited'"
    $SSH_CMD "docker container ls -a --filter 'status=exited'" || true

    echo ""
    log_info "Build cache:"
    log_cmd "docker builder du"
    $SSH_CMD "docker builder du" || true
else
    # Actual cleanup
    log_info "Removing stopped containers..."
    log_cmd "docker container prune $PRUNE_FLAGS"
    $SSH_CMD "docker container prune $PRUNE_FLAGS" || true

    echo ""
    log_info "Removing unused networks..."
    log_cmd "docker network prune $PRUNE_FLAGS"
    $SSH_CMD "docker network prune $PRUNE_FLAGS" || true

    echo ""
    log_info "Removing unused images..."
    log_cmd "docker image prune $IMAGE_PRUNE_FLAGS"
    $SSH_CMD "docker image prune $IMAGE_PRUNE_FLAGS" || true

    echo ""
    log_info "Removing build cache..."
    log_cmd "docker builder prune $PRUNE_FLAGS"
    $SSH_CMD "docker builder prune $PRUNE_FLAGS" || true

    echo ""
    log_info "Docker disk usage after cleanup:"
    $SSH_CMD "docker system df"

    echo ""
    log_info "Current disk usage on server:"
    $SSH_CMD "df -h / | tail -1"

    echo ""
    log_info "Cleanup complete!"
fi