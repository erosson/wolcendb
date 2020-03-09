#!/bin/bash
set -eu
cd "`dirname "$0"`/../.."
aws s3 ls s3://img-wolcendb.erosson.org/datamine/ | node ./scripts/public/buildRevisions.exec.js > ./public/buildRevisions.json
