---
layout:        post_colorful
title:         "Goto Modules"
subtitle:      "Python Logging"
date:           2017-09-15
title_style:    "color:#a8b7a9"
subtitle_style: "color:#a8b7a9"
author_style:   "color:#a7b2a8"
header-img: "img/code-bg-03.jpg"
---

Every developer has a set of modules they always use in some mutated form or another. I'm starting this series of posts to document all my Goto Modules. Starting off with my goto Python Logging module. I currently have two main variants of this module which I use regularly.


## Console and File

This variant allows configurable level logging to the console and to a file. It sets up a rotating file handler that will keep 20 previous files and
rotate them when they reach 10MB.

{% highlight python %}
import logging
import logging.handlers
import logging.config
import os
import os.path

def setup(name, path, level):
    if not os.path.exists(path):
        os.makedirs(path)

    path = os.path.join(path, name)
    lconfig = dict(
        version = 1,
        formatters = {
            'f': { 'format': '%(asctime)s %(funcName)-12s %(lineno)d %(levelname)-5s %(message)s' }
            },
        handlers = {
            'c': { 'class': 'logging.StreamHandler',
                   'formatter': 'f',
                   'level': level },
            'r': { 'class': 'logging.handlers.RotatingFileHandler',
                   'formatter': 'f',
                   'level': level,
                   'filename': path,
                   'maxBytes': 10 * 1024 * 1024,
                   'backupCount': 20 }
            },
        root = {
            'handlers': [ 'c', 'r' ],
            'level': logging.DEBUG,
            }
        )

    logging.config.dictConfig(lconfig)

def get(name):
    return logging.getLogger(name)

{% endhighlight %}


## Console & Errors to Bugsnag

Similar to the last one, however its more orientated to container work where you don't need/want a log file. It also includes
error logging to [BugSnag](https://www.bugsnag.com).

{% highlight python %}

import logging
import logging.handlers
import logging.config
import bugsnag
from bugsnag.handlers import BugsnagHandler

def setup(name, app_path, api_key, level):
    bugsnag.configure(
      api_key = api_key,
      project_root = app_path
    )

    lconfig = dict(
        version = 1,
        formatters = {
            'f': { 'format': '%(asctime)s %(funcName)-12s %(lineno)d %(levelname)-5s %(message)s' }
            },
        handlers = {
            'c': { 'class': 'logging.StreamHandler',
                   'formatter': 'f',
                   'level': level },
            'b': { 'class': 'bugsnag.handlers.BugsnagHandler',
                   'formatter': 'f',
                   'level': logging.ERROR }
            },
        root = {
            'handlers': [ 'c', 'b' ],
            'level': logging.DEBUG,
            }
        )

    logging.config.dictConfig(lconfig)

def get(name):
    logger = logging.getLogger(name)
    return logger

{% endhighlight %}


### Notes

Most logging platforms in modern languages generally encourage loading log configuration from a separate file. I am not a fan of this of this approach
for small to medium projects. My reasoning is I always try keep the number of files I ship to a minimum to keep things simple.
I almost always think if you are going to give the end user the option to adjust their log settings then they should do so from a UI or a command line
switch.
