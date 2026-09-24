#!/usr/bin/env bash
set -e

echo "Building plugin artifact..."
python -m jprm plugin build .
