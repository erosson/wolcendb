#!/bin/bash
set -eu
cd "`dirname "$0"`/.."
elm make --optimize scripts/build-ssr/ListPages.elm --output scripts/build-ssr/ListPages.elm.js
elm make --optimize scripts/build-ssr/Render.elm --output scripts/build-ssr/Render.elm.js
rm -rf build-nossr build-ssr

cp -rp build build-ssr
node ./scripts/build-ssr/ssr.exec.js
mv build build-nossr
mv build-ssr build
