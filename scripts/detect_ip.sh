#!/usr/bin/env bash
set -euo pipefail

IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1; i<=NF; i++) if ($i=="src") print $(i+1)}' | head -n 1)"

if [ -z "${IP}" ]; then
  IP="$(hostname -I | awk '{print $1}')"
fi

if [ -z "${IP}" ]; then
  echo "ERROR: cannot detect server IP" >&2
  exit 1
fi

echo "${IP}"
