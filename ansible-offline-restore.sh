#!/usr/bin/env bash
set -euo pipefail
bundle="ansible-offline-20260107.tar.gz"
cat ${bundle}.part-* > "${bundle}"
sha256sum -c "${bundle}.sha256"
tar -xzf "${bundle}"
echo "OK: restored and extracted ${bundle}"
