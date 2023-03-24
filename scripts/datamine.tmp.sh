#!/bin/bash
set -euo pipefail
echo 'I extract data from your Wolcen game files into ./datamine.tmp'
echo 'deleting datamine.tmp in 3...'
#sleep 3
rm -rf datamine* build*

cd third-party/WolcenExtractor
# GAMEPATH="`realpath ../../assets-dl/depot`"
# GAMEPATH="`realpath ../../wolcen`"
GAMEPATH="`realpath $(cat ../../GAMEPATH)`"
echo $GAMEPATH
# DEST="`realpath ../../datamine.tmp`"
DEST="..\..\datamine.tmp"
echo $DEST
ruby src/main.rb extract --source "$GAMEPATH" --dest "$DEST" --only english_xml.pak,umbra.pak,Libs_UI_
# ruby src/main.rb extract --source "$GAMEPATH" --dest "$DEST" --only english_xml.pak
# ruby src/main.rb extract --source "$GAMEPATH" --dest "$DEST" --only Libs_UI_5.pak
# ruby src/main.rb extract --source "$GAMEPATH" --dest "$DEST" --only Libs_UI_4.pak
# ruby src/main.rb extract --source "$GAMEPATH" --dest "$DEST" --only Libs_UI_1.pak
# ruby src/main.rb extract --source "$GAMEPATH" --dest "$DEST" --only umbra.pak
for file in `ls $GAMEPATH/localization`; do
  echo $file
  # dest="$DEST/lang/$file"
  dest="$DEST\\lang\\$file"
  mkdir -p $dest
  # ruby src/main.rb extract --source "$GAMEPATH" --dest "$dest" --only "$DEST" --trace
  unzip $GAMEPATH/localization/$file -d $dest
done
cd -

cp "$GAMEPATH"/revision.txt datamine.tmp/revision.txt
yarn export:datamine

set +x
echo
echo
echo "Done! Don't forget to run \`yarn deploy:img\` with the right credentials, to deploy this new version to \`img-wolcendb.erosson.org\`"
