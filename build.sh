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

info()    { echo -e "${BLUE}🔧${NC} $*"; }
success() { echo -e "${GREEN}✅${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠️${NC}  $*"; }
error()   { echo -e "${RED}❌${NC} $*"; }

# ── Timing helpers ────────────────────────────────────────────────────────────
now_seconds() { date +%s; }

format_elapsed() {
    local seconds=$1
    if (( seconds >= 60 )); then
        printf "%dm %ds" $((seconds / 60)) $((seconds % 60))
    else
        printf "%ds" "$seconds"
    fi
}

# ── Verbose command runner ────────────────────────────────────────────────────
run_cmd() {
    if [[ "$DO_VERBOSE" -eq 1 ]]; then
        echo -e "${YELLOW}  ▶ $*${NC}"
    fi
    "$@"
}

# ── Usage / help ──────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
Usage: ./build.sh [options] [frontend|backend|both]

🧵 Build the Stitches application.

Targets:
  frontend       Build only the React frontend
  backend        Build only the ASP.NET Core backend
  both           Build frontend and backend (default)

Options:
  -c, --clean    Clean before building
  -t, --test     Run tests after building
  -l, --lint     Run linters (ESLint + warnings-as-errors)
  -r, --release  Build in Release configuration
  -a, --all      Shorthand for --lint --test
  --ci           CI mode (implies --clean --lint --test --release)
  -v, --verbose  Show commands being executed
  -h, --help     Show this help message

Examples:
  ./build.sh                      # Build everything (Debug)
  ./build.sh frontend             # Frontend only
  ./build.sh --clean backend      # Clean + build backend
  ./build.sh -a                   # Build all + lint + test
  ./build.sh --ci                 # Full CI pipeline
  ./build.sh backend -r --test    # Release build + tests for backend
EOF
}

# ── Argument parsing ──────────────────────────────────────────────────────────
DO_CLEAN=0
DO_TEST=0
DO_LINT=0
DO_RELEASE=0
DO_CI=0
DO_VERBOSE=0
TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -c|--clean)   DO_CLEAN=1 ;;
        -t|--test)    DO_TEST=1 ;;
        -l|--lint)    DO_LINT=1 ;;
        -r|--release) DO_RELEASE=1 ;;
        -a|--all)     DO_LINT=1; DO_TEST=1 ;;
        --ci)         DO_CI=1; DO_CLEAN=1; DO_LINT=1; DO_TEST=1; DO_RELEASE=1 ;;
        -v|--verbose) DO_VERBOSE=1 ;;
        frontend|backend|both)
            if [[ -n "$TARGET" ]]; then
                error "Multiple targets specified: '$TARGET' and '$1'"
                echo ""
                usage
                exit 1
            fi
            TARGET="$1"
            ;;
        *)
            error "Unrecognized argument: $1"
            echo ""
            usage
            exit 1
            ;;
    esac
    shift
done

TARGET="${TARGET:-both}"

# ── Derived configuration ────────────────────────────────────────────────────
DOTNET_CONFIGURATION="Debug"
if [[ "$DO_RELEASE" -eq 1 ]]; then
    DOTNET_CONFIGURATION="Release"
fi

NPM_INSTALL_CMD="npm install"
if [[ "$DO_CI" -eq 1 ]]; then
    NPM_INSTALL_CMD="npm ci"
fi

# ── Clean steps ───────────────────────────────────────────────────────────────
clean_frontend() {
    info "🧹 Cleaning frontend..."
    local cleaned=0

    if [[ -d "$SCRIPT_DIR/frontend/node_modules" ]]; then
        run_cmd rm -rf "$SCRIPT_DIR/frontend/node_modules"
        info "Removed frontend/node_modules"
        cleaned=1
    else
        warn "frontend/node_modules already clean"
    fi

    if [[ -d "$SCRIPT_DIR/frontend/dist" ]]; then
        run_cmd rm -rf "$SCRIPT_DIR/frontend/dist"
        info "Removed frontend/dist"
        cleaned=1
    else
        warn "frontend/dist already clean"
    fi

    if [[ "$cleaned" -eq 1 ]]; then
        success "Frontend clean completed"
    fi
}

clean_backend() {
    info "🧹 Cleaning backend..."
    cd "$SCRIPT_DIR/backend"
    if ! run_cmd dotnet clean -c "$DOTNET_CONFIGURATION" --verbosity quiet; then
        error "Backend: dotnet clean failed"
        exit 1
    fi
    success "Backend clean completed"
    cd "$SCRIPT_DIR"
}

# ── Build steps ───────────────────────────────────────────────────────────────
build_frontend() {
    info "⚛️  Building frontend..."
    local start
    start=$(now_seconds)

    cd "$SCRIPT_DIR/frontend"

    info "📦 Installing npm dependencies..."
    if ! run_cmd $NPM_INSTALL_CMD; then
        error "Frontend: $NPM_INSTALL_CMD failed"
        exit 1
    fi

    info "🔨 Running production build..."
    if ! run_cmd npm run build; then
        error "Frontend: npm run build failed"
        exit 1
    fi

    local elapsed
    elapsed=$(( $(now_seconds) - start ))
    success "Frontend build completed in $(format_elapsed $elapsed)"
    cd "$SCRIPT_DIR"
}

build_backend() {
    info "🔷 Building backend..."
    local start
    start=$(now_seconds)

    cd "$SCRIPT_DIR/backend"

    info "📦 Restoring NuGet packages..."
    if ! run_cmd dotnet restore; then
        error "Backend: dotnet restore failed"
        exit 1
    fi

    local build_args=(--no-restore -c "$DOTNET_CONFIGURATION")
    if [[ "$DO_LINT" -eq 1 ]]; then
        info "🔍 Lint mode: treating warnings as errors"
        build_args+=(--warnaserror)
    fi

    info "🔨 Compiling solution..."
    if ! run_cmd dotnet build "${build_args[@]}"; then
        error "Backend: dotnet build failed"
        exit 1
    fi

    local elapsed
    elapsed=$(( $(now_seconds) - start ))
    success "Backend build completed in $(format_elapsed $elapsed)"
    cd "$SCRIPT_DIR"
}

# ── Lint steps ────────────────────────────────────────────────────────────────
lint_frontend() {
    info "🔍 Linting frontend..."
    local start
    start=$(now_seconds)

    cd "$SCRIPT_DIR/frontend"

    if ! run_cmd npm run lint; then
        error "Frontend: npm run lint failed"
        exit 1
    fi

    local elapsed
    elapsed=$(( $(now_seconds) - start ))
    success "Frontend lint completed in $(format_elapsed $elapsed)"
    cd "$SCRIPT_DIR"
}

# ── Test steps ────────────────────────────────────────────────────────────────
test_frontend() {
    info "🧪 Testing frontend..."
    local start
    start=$(now_seconds)

    cd "$SCRIPT_DIR/frontend"

    local test_args=(npm test -- --run)
    if [[ "$DO_CI" -eq 1 ]]; then
        test_args=(npm test -- --run --coverage)
    fi

    if ! run_cmd "${test_args[@]}"; then
        error "Frontend: tests failed"
        exit 1
    fi

    local elapsed
    elapsed=$(( $(now_seconds) - start ))
    success "Frontend tests completed in $(format_elapsed $elapsed)"
    cd "$SCRIPT_DIR"
}

test_backend() {
    info "🧪 Testing backend..."
    local start
    start=$(now_seconds)

    cd "$SCRIPT_DIR/backend"

    if ! run_cmd dotnet test --no-build -c "$DOTNET_CONFIGURATION"; then
        error "Backend: tests failed"
        exit 1
    fi

    local elapsed
    elapsed=$(( $(now_seconds) - start ))
    success "Backend tests completed in $(format_elapsed $elapsed)"
    cd "$SCRIPT_DIR"
}

# ── Orchestration ─────────────────────────────────────────────────────────────
run_frontend() {
    if [[ "$DO_CLEAN" -eq 1 ]]; then clean_frontend; fi
    build_frontend
    if [[ "$DO_LINT" -eq 1 ]]; then lint_frontend; fi
    if [[ "$DO_TEST" -eq 1 ]]; then test_frontend; fi
}

run_backend() {
    if [[ "$DO_CLEAN" -eq 1 ]]; then clean_backend; fi
    build_backend
    # Backend lint is integrated into build via --warnaserror (no separate step)
    if [[ "$DO_TEST" -eq 1 ]]; then test_backend; fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo -e "\n🧵 ${BLUE}Stitches Build System${NC}\n"

total_start=$(now_seconds)

case "$TARGET" in
    frontend)
        run_frontend
        ;;
    backend)
        run_backend
        ;;
    both)
        run_frontend
        run_backend
        ;;
esac

total_elapsed=$(( $(now_seconds) - total_start ))
echo ""
success "🏁 All builds finished in $(format_elapsed $total_elapsed)"
