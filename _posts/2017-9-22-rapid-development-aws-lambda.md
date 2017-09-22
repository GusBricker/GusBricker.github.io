---
layout:        post_colorful
title:         "Rapid Development"
subtitle:      "AWS Lambda"
date:           2017-09-22
title_style:    "color:#9aeae5"
subtitle_style: "color:#9aeae5"
author_style:   "color:#9aeae5"
header-img: "img/lambda.png"
---

Serverless is awesome. The ability to run a snippet of code in the cloud in response to various triggers without having to manage
infrastructure is beyond amazing especially if you don't want to take on to much technical debt.

One big gotcha with Serverless offerings such as AWS Lambda is how do you test your code if its running on some magical box in the cloud? 
Whilst there exists projects like [lambda-local](https://github.com/ashiina/lambda-local) to test locally, I prefer to test on the environment in which its going to be deployed.
Testing in the cloud becomes more important if the function depends on some other AWS resources that aren't accessible outside of your VPC.

My workspace for this kind of workflow usually has a few scripts per function, `mkdist.sh` and `run.sh`.

---


## mkdist.sh

This script is dead simple and fairly dependant on the language you are working with. The example I have included is suited for Python 3.6 but should be easily adapted to suit other languages. It zips up the source code and sends it off to AWS using the CLI.

{% highlight bash %}
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "-----------------------------------------------------"
FUNCTION_NAME="<function name>"
ZIP_PATH="${DIR}/${FUNCTION_NAME}.zip"
SRC_PATH="${DIR}/source"
rm "${ZIP_PATH}"

zip -9 "${ZIP_PATH}"

pushd ${SRC_PATH}
zip -r9 ${ZIP_PATH} app.py
popd

pushd ${SRC_PATH}/lib/python3.6/site-packages
zip -r9 ${ZIP_PATH} *
popd

aws lambda update-function-code --publish --function-name "${FUNCTION_NAME}" --zip-file "fileb://${ZIP_PATH}"
{% endhighlight %}
---


## run.sh - via AWS CLI

A simple wrapper around `aws lambda invoke` to make life a little easier. Payload is supplied via the `--payload` switch.

{% highlight bash %}
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

FUNCTION_NAME="<function name>"
REGION="<region>"

aws lambda invoke --function-name "${FUNCTION_NAME}" --invocation-type RequestResponse --log-type None --region "${REGION}" "${@}" "${DIR}/log.txt" && tail -F "${DIR}/log.txt"

{% endhighlight %}
---


## run.sh - via API gateway

Heres the fun stuff, this script depends on the awesome [awslogs](https://github.com/jorgebastida/awslogs) package and that your function
is connected to an API Endpoint via API Gateway. Payload is supplied via the `-d` switch.

{% highlight bash %}
#!/bin/bash

FUNCTION_NAME="<function name>"
REGION="<region>"
API_KEY="<api key>"
API_ENDPOINT="<api endpoint>"
LOG_GROUP_NAME="/aws/lambda/${FUNCTION_NAME}"

echo "Executing ${FUNCTION_NAME} with payload"
echo "${PAYLOAD}"

date=$(date -u '+%Y/%m/%d %H:%M:%S')
curl -X POST -H "Accept: application/json" -H "Content-Type: application/json" -H "x-api-key: ${API_KEY}" -i "${API_ENDPOINT}" "${@}" || exit 1
echo # Empty line

awslogs get "${LOG_GROUP_NAME}" --watch --start="${date}"
{% endhighlight %}
