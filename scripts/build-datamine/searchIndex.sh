#!/bin/bash
set -eu
cd "`dirname "$0"`/../.."
elm make --optimize scripts/build-datamine/SearchIndex.elm --output scripts/build-datamine/SearchIndex.elm.js
node ./scripts/build-datamine/searchIndex.exec.js
