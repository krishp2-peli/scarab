#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_URL="https://storage.googleapis.com/external-traces-v2"
DEST_ROOT="${ROOT_DIR}/traces"

WORKLOAD=""
TRACE_FILE=""

usage() {
  cat <<'EOF'
Usage: ./download_google_trace.sh --workload NAME --trace-file FILE [--dest-root DIR]

Downloads one Google trace zip and the workload aux metadata into:
  <dest-root>/<workload>/
    trace/<trace-file>
    aux/info.textproto
    aux/v2p.textproto

Options:
  --workload NAME     Workload folder in external-traces-v2, e.g. arizona
  --trace-file FILE   Trace zip filename, e.g. 16362031984258116688.1171988.memtrace.zip
  --dest-root DIR     Root output directory (default: ./traces)
  -h, --help          Show this help

Example:
  ./download_google_trace.sh \
    --workload arizona \
    --trace-file 16362031984258116688.1171988.memtrace.zip
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workload)
      WORKLOAD="$2"
      shift 2
      ;;
    --trace-file)
      TRACE_FILE="$2"
      shift 2
      ;;
    --dest-root)
      DEST_ROOT="$2"
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

if [[ -z "${WORKLOAD}" || -z "${TRACE_FILE}" ]]; then
  echo "Error: --workload and --trace-file are required." >&2
  usage
  exit 1
fi

if [[ "${TRACE_FILE}" != *.memtrace.zip ]]; then
  echo "Error: --trace-file must end with .memtrace.zip" >&2
  exit 1
fi

TRACE_DIR="${DEST_ROOT}/${WORKLOAD}/trace"
AUX_DIR="${DEST_ROOT}/${WORKLOAD}/aux"

mkdir -p "${TRACE_DIR}" "${AUX_DIR}"

TRACE_URL="${BASE_URL}/${WORKLOAD}/trace/${TRACE_FILE}"
INFO_URL="${BASE_URL}/${WORKLOAD}/aux/info.textproto"
V2P_URL="${BASE_URL}/${WORKLOAD}/aux/v2p.textproto"

TRACE_OUT="${TRACE_DIR}/${TRACE_FILE}"
INFO_OUT="${AUX_DIR}/info.textproto"
V2P_OUT="${AUX_DIR}/v2p.textproto"

echo "Downloading trace:"
echo "  ${TRACE_URL}"
curl -L --fail -o "${TRACE_OUT}" "${TRACE_URL}"

echo "Downloading aux metadata:"
echo "  ${INFO_URL}"
curl -L --fail -o "${INFO_OUT}" "${INFO_URL}"

echo "  ${V2P_URL}"
curl -L --fail -o "${V2P_OUT}" "${V2P_URL}"

echo
echo "Downloaded files:"
ls -lh "${TRACE_OUT}" "${INFO_OUT}" "${V2P_OUT}"
