#!/usr/bin/env bash
set -e

# Resolve paths relative to the script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Color output ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[FAIL]${NC} $*"; }

# ── Child process tracking ────────────────────────────────────────────────────
FRONTEND_PID=""
BACKEND_PID=""

cleanup() {
    echo ""
    warn "Shutting down dev servers..."
    if [[ -n "$FRONTEND_PID" ]] && kill -0 "$FRONTEND_PID" 2>/dev/null; then
        kill "$FRONTEND_PID" 2>/dev/null
        wait "$FRONTEND_PID" 2>/dev/null || true
        info "Frontend server stopped"
    fi
    if [[ -n "$BACKEND_PID" ]] && kill -0 "$BACKEND_PID" 2>/dev/null; then
        kill "$BACKEND_PID" 2>/dev/null
        wait "$BACKEND_PID" 2>/dev/null || true
        info "Backend server stopped"
    fi
    success "All dev servers stopped"
    exit 0
}

# ── Usage / help ──────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
Usage: ./dev.sh [frontend|backend|both]

Start Stitches development servers.

Arguments:
  frontend    Start React dev server only (Vite HMR on localhost:5173)
  backend     Start ASP.NET Core API server only (localhost:5000)
  both        Start frontend and backend concurrently (default)

Options:
  -h, --help  Show this help message

Examples:
  ./dev.sh              # Start both servers
  ./dev.sh frontend     # Start frontend only
  ./dev.sh backend      # Start backend only

URLs:
  Frontend:  http://localhost:5173
  Backend:   http://localhost:5000
  Swagger:   http://localhost:5000/swagger
EOF
}

# ── Dev steps ─────────────────────────────────────────────────────────────────
run_frontend() {
    info "Starting frontend dev server..."
    cd "$SCRIPT_DIR/frontend"

    info "Installing npm dependencies..."
    if ! npm install; then
        error "Frontend: npm install failed"
        return 1
    fi

    success "Frontend dependencies installed"
    info "Starting Vite HMR dev server..."
    echo -e "${GREEN}[OK]${NC}   Frontend available at ${BLUE}http://localhost:5173${NC}"
    npm run dev
}

run_backend() {
    info "Starting backend dev server..."
    cd "$SCRIPT_DIR/backend"

    echo -e "${GREEN}[OK]${NC}   Backend available at ${BLUE}http://localhost:5000${NC}"
    echo -e "${GREEN}[OK]${NC}   Swagger UI at ${BLUE}http://localhost:5000/swagger${NC}"
    dotnet run --project src/Api
}

run_frontend_prefixed() {
    run_frontend 2>&1 | sed "s/^/[frontend] /"
}

run_backend_prefixed() {
    run_backend 2>&1 | sed "s/^/[backend]  /"
}

# ── Main ──────────────────────────────────────────────────────────────────────
TARGET="${1:-both}"

case "$TARGET" in
    -h|--help)
        usage
        exit 0
        ;;
    frontend)
        run_frontend
        ;;
    backend)
        run_backend
        ;;
    both)
        trap cleanup SIGINT SIGTERM

        info "Starting frontend and backend concurrently..."
        echo ""
        echo -e "${BLUE}[INFO]${NC} Frontend: ${BLUE}http://localhost:5173${NC}"
        echo -e "${BLUE}[INFO]${NC} Backend:  ${BLUE}http://localhost:5000${NC}"
        echo -e "${BLUE}[INFO]${NC} Swagger:  ${BLUE}http://localhost:5000/swagger${NC}"
        echo ""
        warn "Press Ctrl+C to stop all servers"
        echo ""

        run_frontend_prefixed &
        FRONTEND_PID=$!

        run_backend_prefixed &
        BACKEND_PID=$!

        # Wait for either process to exit
        wait -n "$FRONTEND_PID" "$BACKEND_PID" 2>/dev/null || true
        EXIT_CODE=$?

        if [[ $EXIT_CODE -ne 0 ]]; then
            error "A dev server exited unexpectedly (exit code: $EXIT_CODE)"
        fi

        # Clean up the other process
        cleanup
        ;;
    *)
        error "Unrecognized argument: $TARGET"
        echo ""
        usage
        exit 1
        ;;
esac
