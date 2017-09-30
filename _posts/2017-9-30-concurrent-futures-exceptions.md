---
layout:        post_colorful
title:         "Exceptional concurrent.futures"
subtitle:      "raise RuntimeError('DOH')"
date:           2017-09-30
title_style:    "color:#9aeae5"
subtitle_style: "color:#9aeae5"
author_style:   "color:#9aeae5"
header-img: "img/python.png"
---

[Concurrent Futures](https://docs.python.org/3/library/concurrent.futures.html) is a concurrency library present in Python since 2.7. It allows easy management of parallel/background jobs. I had a project
recently where my background threads would appear to die silently. I was expecting to see an Exception somewhere in my logs but found nothing.

It turns out somewhere in `concurrent.futures.ThreadpoolExecutor`, the exception gets gobbled up. The documentation page shows the `Futures` object
actually has an `exception()` method which will return the Exception raised in the background thread. However there is a catch, all we get is the exception
message which might not be all that useful in actually tracking down the bug. What we really want is the traceback, showing which file and line caused
the error.

We can however fix this issue by catching the exception, and re-raising it with more information in the message. Our worker function looks something
like this:

{% highlight python %}
def do_work():
    try:
        print ('Work starting')
        print (2 / 0) # Generate divide by zero exception for testing
        print ('Work done!')
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        message = "Exception: %s in %s on line %d\n" % (exc_type, fname, exc_tb.tb_lineno)
        message += "".join(traceback.format_exception(e.__class__, e, exc_tb))
        raise RuntimeError("Error occurred. Original traceback is\n%s" %(message))
{% endhighlight %}

The above snippet is fairly simple, we get the traceback from `sys.exc_info()`. We can then determine the filename, line number and actual traceback. Its
just a matter of constructing a new message with that information contained within and then raising a `RuntimeError()`.


## Full Example

{% highlight python %}
#!/usr/bin/env python3

import os
import sys
import traceback
from concurrent.futures import ThreadPoolExecutor, wait

def do_work():
    try:
        print ('Work starting')
        print (2 / 0) # Generate divide by zero exception for testing
        print ('Work done!')
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        message = "Exception: %s in %s on line %d\n" % (exc_type, fname, exc_tb.tb_lineno)
        message += "".join(traceback.format_exception(e.__class__, e, exc_tb))
        raise RuntimeError("Error occurred. Original traceback is\n%s" %(message))

def run():
    num_workers = 5
    executor = ThreadPoolExecutor(max_workers=num_workers)
    futures = []

    for index in range(0, num_workers):
        futures.append(executor.submit(do_work))

    wait(futures)

    for f in futures:
        ex = f.exception()
        if ex != None:
            print(ex)

if __name__ == "__main__":
    run()
{% endhighlight %}
