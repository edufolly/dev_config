#! /bin/bash

set -e

code=0

###########
# git tag #
###########
git fetch --tags --depth=1 origin &> /dev/null

branch=$(git rev-parse --abbrev-ref HEAD)

suffix=""

case $branch in
  alpha) suffix="A" ;;
  beta) suffix="B" ;;
  dev) branch="main" ;;
esac

version=$(grep 'version:' pubspec.yaml | cut -c 10- | cut -f 1 -d '+')$suffix

echo ""
if git rev-parse "v$version^{tag}" >/dev/null 2>&1
then
  echo "[ERROR] Tag v$version already deployed."
  code=20
else
  echo "Tag v$version is ready to deploy."
fi
echo ""

exit $code
