#!/bin/bash

MODE="$1"
set -euf -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LESS_DIR="${DIR}/less"
CSS_DIR="${DIR}/css"
JS_DIR="${DIR}/js"
UGLIFYJS_BIN="${DIR}/node_modules/uglify-js/bin/uglifyjs"
LESSC_BIN="${DIR}/node_modules/less/bin/lessc"

echo "[uglifyjs] Compressing clean-blog.js"
CLEAN_BLOG_JS="${JS_DIR}/clean-blog.js"
CLEAN_BLOG_MIN_JS="${JS_DIR}/clean-blog.min.js"
${UGLIFYJS_BIN} "${CLEAN_BLOG_JS}" -c -o "${CLEAN_BLOG_MIN_JS}"

echo "[less] Building"
${LESSC_BIN} "${LESS_DIR}/clean-blog.less" > "${CSS_DIR}/clean-blog.css"

if [[ "x${MODE}" == "x" ]] || [[ "x${MODE}" == "xserve" ]]
then
    echo "[jekyll] Serving site"
    jekyll serve --watch
elif [[ "x${MODE}" == "xbuild" ]]
then
    echo "[jekyll] Building site"
    jekyll build
fi
