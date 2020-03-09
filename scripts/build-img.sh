#!/bin/bash
set -eu
cd "`dirname "$0"`/.."
node ./scripts/build-img/png.exec.js
node ./scripts/build-img/version.exec.js
