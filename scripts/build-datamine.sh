#!/bin/bash
set -eu
cd "`dirname "$0"`/.."
rm -rf build*
node ./scripts/build-datamine/revision.exec.js
node ./scripts/build-datamine/lang.exec.js
node ./scripts/build-datamine/datamine.exec.js
bash ./scripts/build-datamine/searchIndex.sh
node ./scripts/build-datamine/sizes.exec.js
if [ -z "$CI" ]; then
  node ./scripts/public/datamine.exec.js
else
  echo "CI build: not building \`/public/datamine\`"
fi
