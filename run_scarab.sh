#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ROOT_DIR}/scarab_env.sh"
DEFAULT_PARAMS="${ROOT_DIR}/src/PARAMS.sunny_cove"

PROGRAM=""
SIMDIR=""
PARAMS="${DEFAULT_PARAMS}"
SCARAB_ARGS=""
PINTOOL_ARGS=""

usage() {
  cat <<'EOF'
Usage: ./run_scarab.sh --program "/path/to/bin [args]" [options]

Options:
  --program CMD        Program command to run under Scarab (required)
  --simdir DIR         Simulation output directory (default: /tmp/scarab-$USER-<timestamp>)
  --params FILE        PARAMS file to use (default: src/PARAMS.sunny_cove)
  --scarab-args STR    Extra args forwarded to Scarab
  --pintool-args STR   Extra args forwarded to pin_exec pintool
  -h, --help           Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --program) PROGRAM="$2"; shift 2 ;;
    --simdir) SIMDIR="$2"; shift 2 ;;
    --params) PARAMS="$2"; shift 2 ;;
    --scarab-args) SCARAB_ARGS="$2"; shift 2 ;;
    --pintool-args) PINTOOL_ARGS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "${PROGRAM}" ]]; then
  echo "Error: --program is required" >&2
  usage
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Error: ${ENV_FILE} not found. Run ./setup_scarab.sh first." >&2
  exit 1
fi

if [[ -z "${SIMDIR}" ]]; then
  SIMDIR="/tmp/scarab-${USER}-$(date +%Y%m%d-%H%M%S)"
fi

mkdir -p "${SIMDIR}"

source "${ENV_FILE}"

python3 "${ROOT_DIR}/bin/scarab_launch.py" \
  --program "${PROGRAM}" \
  --params "${PARAMS}" \
  --simdir "${SIMDIR}" \
  --scarab_args "${SCARAB_ARGS}" \
  --pintool_args "${PINTOOL_ARGS}"

