#!/bin/bash
set -eu
cd "`dirname "$0"`/.."
rm -rf build
bash ./scripts/build-datamine.sh
elm-app build
bash ./scripts/build-ssr.sh
