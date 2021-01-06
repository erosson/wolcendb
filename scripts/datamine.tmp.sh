#!/bin/bash
set -euo pipefail
echo 'I extract data from your Wolcen game files into ./datamine.tmp'
echo 'deleting datamine.tmp in 3...'
#sleep 3
rm -rf datamine* build*

cd third-party/WolcenExtractor
GAMEPATH="`realpath ../../assets-dl/depot`"
echo $GAMEPATH
# ./dist/wolcen_extractor.exe extract --source "$GAMEPATH" --dest ../../datamine.tmp --only english_xml.pak
./dist/wolcen_extractor.exe extract --source "$GAMEPATH" --dest ../../datamine.tmp --only english_xml.pak,umbra.pak,Libs_UI_ --trace
for file in `ls $GAMEPATH/localization`; do
  echo $file
  dest=../../datamine.tmp/lang/$file
  mkdir -p $dest
  ./dist/wolcen_extractor.exe extract --source "$GAMEPATH" --dest $dest --only ../../datamine.tmp --trace
  unzip $GAMEPATH/localization/$file -d $dest
done
cd -

cp "$GAMEPATH"/revision.txt datamine.tmp/revision.txt
yarn export:datamine

set +x
echo
echo
echo "Done! Don't forget to run \`yarn deploy:img\` with the right credentials, to deploy this new version to \`img-datamine.erosson.org\`"
