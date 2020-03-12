#!/bin/bash
set -eu
cd "`dirname "$0"`/.."
rm -rf build*
node ./scripts/build-datamine/revision.exec.js
node ./scripts/build-datamine/lang.exec.js
node ./scripts/build-datamine/datamine.exec.js
bash ./scripts/build-datamine/searchIndex.sh
node ./scripts/build-datamine/sizes.exec.js
if [ -v CI ]; then
  echo "CI build: not building \`/public/datamine\`"
else
  echo "non-CI build: building \`/public/datamine\`"
  node ./scripts/public/datamine.exec.js
fi
