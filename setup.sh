#!/bin/bash

set -e

bundle install

if [[ "$OSTYPE" == "linux-gnu" ]]
then
    sudo apt-get update
    sudo apt-get install -y npm
elif [[ "$OSTYPE" == "darwin"* ]]
then
    brew update
    brew install npm
fi
npm install uglify-js
npm install less
