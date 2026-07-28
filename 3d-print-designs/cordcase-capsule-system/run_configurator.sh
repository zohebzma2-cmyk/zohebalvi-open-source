#!/usr/bin/env bash
# Start the CordCase configurator and open it.
#   ./run_configurator.sh
set -euo pipefail
cd "$(dirname "$0")"
command -v openscad >/dev/null || { echo "OpenSCAD not found: brew install --cask openscad"; exit 1; }
python3 configurator.py &
sleep 2
open "http://127.0.0.1:8770/"
wait
