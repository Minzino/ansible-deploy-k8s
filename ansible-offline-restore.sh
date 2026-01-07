#!/usr/bin/env bash
set -euo pipefail
bundle="ansible-offline-20260107.tar.gz"
bundle_dir="bundle"
cat "${bundle_dir}"/${bundle}.part-* > "${bundle}"
sha256sum -c "${bundle_dir}/${bundle}.sha256"
tar -xzf "${bundle}"
echo "OK: restored and extracted ${bundle}"
