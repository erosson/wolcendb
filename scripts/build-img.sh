#!/bin/bash
set -eu
cd "`dirname "$0"`/.."
./scripts/build-img/png.exec.js
./scripts/build-img/version.exec.js
