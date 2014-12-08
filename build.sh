#!/bin/bash

LESS_DIR="less"
CSS_DIR="css"

echo "[less] Building"
lessc "${LESS_DIR}/clean-blog.less" > "${CSS_DIR}/clean-blog.css"

echo "[jekyll] Working"
jekyll serve --watch
