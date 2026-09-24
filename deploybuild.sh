#!/usr/bin/env bash
set -e

./build.sh
./publish.sh
./uploadrelease.sh
