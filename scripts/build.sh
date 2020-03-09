#!/bin/bash
set -eux
cd "`dirname "$0"`/.."
rm -rf build
./scripts/build-datamine.sh
elm-app build
# ./scripts/build-ssr.sh
