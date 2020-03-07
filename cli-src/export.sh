#!/bin/bash
set -eux
echo 'deleting datamine.tmp in 3...'
sleep 3
rm -rf datamine* build*

cd third-party/WolcenExtractor
GAMEPATH="`cat ../../GAMEPATH`"
echo $GAMEPATH
for file in `ls $GAMEPATH/localization`; do
  echo $file
  dest=../../datamine.tmp/lang/$file
  mkdir -p $dest
  ruby src/main.rb extract --source "$GAMEPATH" --dest $dest --only ../../datamine.tmp --trace
  unzip $GAMEPATH/localization/$file -d $dest
done
# ruby src/main.rb extract --source "$GAMEPATH" --dest ../../datamine.tmp --only english_xml.pak
ruby src/main.rb extract --source "$GAMEPATH" --dest ../../datamine.tmp --only english_xml.pak,umbra.pak,Libs_UI_
cd -

cp "$GAMEPATH"/revision.txt datamine.tmp/revision.txt
yarn export:cp

set +x
echo
echo
echo "Done! Don't forget to run \`yarn deploy:img:datamine\` with the right credentials."
