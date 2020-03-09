#!/bin/bash
set -eu
cd "`dirname "$0"`/.."
rm -rf build*
./scripts/build-datamine/revision.exec.js
./scripts/build-datamine/lang.exec.js
./scripts/build-datamine/datamine.exec.js
./scripts/build-datamine/searchIndex.sh
./scripts/build-datamine/sizes.exec.js
