#/bin/bash

old_release=$1
release=$2
if [ -z "$release" ]; then
       echo "Usage: $0 <old version number> <new version number>"
       exit
fi       

# now update the release version
scriptpath=$(realpath "$0")
scriptdir=$(dirname $scriptpath)
basedir=$(dirname $scriptdir)

echo $release >$basedir/VERSION

# now create a zip of the new release
cd $basedir/..
pwd
zip -r payconiq-api-php.zip payconiq-api-php/src payconiq-api-php/VERSION
mv payconiq-api-php.zip $basedir/dist/

cd $basedir
git add VERSION
git commit -m "release $release" -a
git push
gh release create "v${release}" --generate-notes ./dist/*.zip
