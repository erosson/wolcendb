#!/bin/bash
set -eu
cd "`dirname "$0"`/../.."
aws s3 sync s3://img-wolcendb.erosson.org/datamine ./build-img/datamine/

bash ./scripts/public/buildRevisions.sh
