#!/bin/bash

set -euf -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LESS_DIR="${DIR}/less"
CSS_DIR="${DIR}/css"
JS_DIR="${DIR}/js"
UGLIFYJS_BIN="${DIR}/node_modules/uglify-js/bin/uglifyjs"

echo "[uglifyjs] Compressing clean-blog.js"
CLEAN_BLOG_JS="${JS_DIR}/clean-blog.js"
CLEAN_BLOG_MIN_JS="${JS_DIR}/clean-blog.min.js"
${UGLIFYJS_BIN} "${CLEAN_BLOG_JS}" -c -o "${CLEAN_BLOG_MIN_JS}"

echo "[less] Building"
lessc "${LESS_DIR}/clean-blog.less" > "${CSS_DIR}/clean-blog.css"

echo "[jekyll] Working"
jekyll serve --watch
