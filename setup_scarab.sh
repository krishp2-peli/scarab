#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${ROOT_DIR}/src"
TOOLS_DIR="${ROOT_DIR}/tools"
ENV_FILE="${ROOT_DIR}/scarab_env.sh"

PIN_VERSION="pin-3.5-97503-gac534ca30-gcc-linux"
PIN_TARBALL="${PIN_VERSION}.tar.gz"
PIN_URL="https://software.intel.com/sites/landingpage/pintool/downloads/${PIN_TARBALL}"
PIN_DIR="${TOOLS_DIR}/${PIN_VERSION}"

JOBS="${JOBS:-1}"
DO_BUILD=1

usage() {
  cat <<'EOF'
Usage: ./setup_scarab.sh [--no-build] [--jobs N]

Options:
  --no-build    Prepare dependencies and env only (skip make)
  --jobs N      Build parallelism (default: JOBS env var or 1)
  -h, --help    Show this help
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: missing required command: $1" >&2
    exit 1
  }
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build)
      DO_BUILD=0
      shift
      ;;
    --jobs)
      JOBS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

require_cmd git
require_cmd curl
require_cmd tar
require_cmd make

echo "[1/4] Initializing submodules..."
git -C "${ROOT_DIR}" submodule update --init --recursive

echo "[2/4] Installing Intel Pin locally..."
mkdir -p "${TOOLS_DIR}"
if [[ ! -f "${PIN_DIR}/source/tools/Config/makefile.default.rules" ]]; then
  if [[ ! -f "${TOOLS_DIR}/${PIN_TARBALL}" ]]; then
    curl -L -o "${TOOLS_DIR}/${PIN_TARBALL}" "${PIN_URL}"
  fi
  tar -xzf "${TOOLS_DIR}/${PIN_TARBALL}" -C "${TOOLS_DIR}"
fi

if [[ ! -f "${PIN_DIR}/source/tools/Config/makefile.default.rules" ]]; then
  echo "Error: Pin install is incomplete at ${PIN_DIR}" >&2
  exit 1
fi

echo "[3/4] Writing environment helper: ${ENV_FILE}"
cat > "${ENV_FILE}" <<EOF
#!/usr/bin/env bash
export PIN_ROOT="${PIN_DIR}"
export SCARAB_ENABLE_PT_MEMTRACE=1
EOF
chmod +x "${ENV_FILE}"

if [[ "${DO_BUILD}" -eq 1 ]]; then
  echo "[4/4] Building Scarab..."
  (
    cd "${SRC_DIR}"
    source "${ENV_FILE}"
    make -j"${JOBS}"
  )
else
  echo "[4/4] Skipping build (--no-build)."
fi

cat <<EOF

Done.

Use this in new shells before running/building Scarab:
  source "${ENV_FILE}"

Run Scarab from:
  ${SRC_DIR}
EOF
