---
layout:        post_colorful
title:         "Getting More Container Logs into Cloudwatch"
subtitle:      "Moooaaarrrr Logs"
date:           2017-09-01
title_style:    "color:#80bfff"
subtitle_style: "color:#0066cc"
author_style:   "color:#0059b3"
header-img: "img/docker-ascii.png"
---


Logging container instances stdout running on Amazon ECS is quiet easy if you have a simple application. You can follow [this guide](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html) and the awslogs agent will catch the output and send it to Cloudwatch.

However if you have a slightly more complicated application that outputs multiple log files (maybe separate authentication logs?) then you are out of luck. The
normal awslogs approach above won't do catch anything but the stdout of the process running in the container. 

If we were sending logs from an EC2 instance to Cloudwatch we would simply download and run the aws-cloudwatch agent Python script and run it when the
instance spins up. The same approach should work in a container with a little bit of work.

Some research shows we will need to bring in a few extra dependancies such as python and supervisord. We are going to also use rsyslog
to facilitate a standard application which logs through syslog.


## Cloudwatch Config

#### /etc/cloudwatch-config

<!-- language: bash-->
    [general]
    state_file = /var/awslogs/state/agent-state
     
    [auth]
    file = /var/log/your_apps_error.log
    log_group_name = /var/log/auth.log
    log_stream_name = {hostname}
    datetime_format = %b %d %H:%M:%S

We use `{hostname}` instead of `{instance_id}` because the `{hostname}` will be the unique process name of the container.
Whereas `{instance_id}` comes from the EC2 instance hosting the container.


## Supervisord Configs:

#### /etc/supervisor/conf.d/rsyslogd.conf

<!-- language: bash-->
    [program:rsyslogd]
    command=/usr/sbin/rsyslogd -n
    autorestart=true
    autostart=true
    redirect_stderr=true

#### /etc/supervisor/conf.d/awslogs.conf

<!-- language: bash-->
    [program:awslogs]
    command=/var/awslogs/bin/awslogs-agent-launcher.sh
    autorestart=true
    autostart=true
    redirect_stderr=true

#### /etc/supervisor.conf

<!-- language: bash-->
    [supervisord]
    nodaemon=true

    [include]
    files = /etc/supervisor/conf.d/*.conf


## Dockerfile

<!-- language: bash-->
    FROM ubuntu:16.04

    ENV AWS_ACCESS_KEY_ID=""
    ENV AWS_SECRET_ACCESS_KEY=""

    RUN apt-get update 

    RUN apt-get -y install rsyslog curl python supervisor

    RUN mkdir -p /var/log/supervisor
    RUN mkdir -p /etc/supervisor/conf.d/

    ADD awslogs.conf /etc/supervisor/conf.d
    ADD rsyslogd.conf /etc/supervisor/conf.d
    ADD supervisor.conf /etc/supervisor.conf
    ADD cloudwatch-config /etc/cloudwatch-config

    RUN curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py > /awslogs-agent-setup.py
    RUN chmod +x /awslogs-agent-setup.py
    RUN /awslogs-agent-setup.py -n -r "us-east-2" -c /etc/cloudwatch-config
    RUN rm /awslogs-agent-setup.py

    CMD ["supervisord", "-c", "/etc/supervisor.conf"]


The above example code uses supervisord to run rsyslog and the awslogs agent in the container. The awslogs agent sends any file that we configure off to Cloudwatch. Obviously the host EC2 instance role has to have the correct IAM policy in place to allow it to actually write the Cloudwatch.
