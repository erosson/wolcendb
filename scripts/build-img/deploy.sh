#!/bin/bash
set -eu
cd "`dirname "$0"`/../.."
# --size-only avoids re-uploading on a timestamp change, and it's accurate enough for images.
aws s3 sync --size-only ./build-img2/game/ s3://img-wolcendb.erosson.org/game --cache-control max-age=86400 "$@"
aws s3 sync ./build-img2/datamine/ s3://img-wolcendb.erosson.org/datamine --cache-control public,max-age=86400 --content-type application/json "$@"

./scripts/public/buildRevisions.sh
