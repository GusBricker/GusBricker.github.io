#!/bin/bash -ex

# Sources
# https://tongueroo.com/articles/how-to-use-any-jekyll-plugins-on-github-pages-with-circleci
# https://stackoverflow.com/questions/28249255/how-do-i-configure-github-to-use-non-supported-jekyll-site-plugins/28252200#28252200

# Setup git so we can use it
git config --global user.email "chris@lapa.com.au"
git config --global user.name "CircleCI Build Script"

git checkout -f

./setup.sh
JEKYLL_ENV=production ./build.sh build

cp circle.yml _site/circle.yml
git rev-parse HEAD > _site/buildhash
touch _site/.nojekyll
mv _site /tmp/

# Make sure that local master matches with remote master
# CircleCI merges made changes to master so need to reset it
git fetch origin master
git checkout -f master
git reset --hard origin/master

# Gets _site/* files and pushes them to master branch
shopt -s extglob
rm -rf !(.git|.|..)
mv -f /tmp/_site/* .
git add -A .
git commit -m "CircleCI: copy _site contents generated from gh-pages-ci branch"
git push origin master
