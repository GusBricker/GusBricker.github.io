#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LESS_DIR="${DIR}/less"
CSS_DIR="${DIR}/css"

echo "[less] Building"
lessc "${LESS_DIR}/clean-blog.less" > "${CSS_DIR}/clean-blog.css"

echo "[jekyll] Working"
jekyll serve --watch
