#!/bin/bash
set -eux
cd "`dirname "$0"`/.."
elm make --optimize scripts/build-ssr/ListPages.elm --output scripts/build-ssr/ListPages.elm.js
elm make --optimize scripts/build-ssr/Render.elm --output scripts/build-ssr/Render.elm.js
cp -rp build build-ssr
./scripts/build-ssr/ssr.exec.js
