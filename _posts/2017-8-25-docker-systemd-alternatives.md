---
layout:         post_colorful
title:          "Working around Systemd on Docker"
subtitle:       "Systemd + Docker = Bad Times"
date:           2017-08-25
title_style:    "color:#80bfff"
subtitle_style: "color:#0066cc"
author_style:   "color:#0059b3"
header-img: "img/docker-ascii.png"
---


It's very tempting to want to use SystemD with Docker. However when you go
down that rabbit hole you quickly realise how difficult and hacky it becomes.

Instead a great alternative is to use [Supervisord](http://supervisord.org). Supervisord makes it really easy
to get off the ground running and daemonise processes. It will also do fancy things restart the process if it
quits unexpectedly.


## Example - Running an SSH Server

Here is a simple example that runs a basic SSH server in a Ubuntu 16.04 container.

<!-- language: bash-->
    FROM ubuntu:16.04

    EXPOSE 22

    RUN apt-get update

    RUN apt-get -y install openssh-server
    RUN mkdir -p /var/run/sshd
    RUN echo 'root:password' | chpasswd
    RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

    RUN apt-get -y install supervisor && \
            mkdir -p /var/log/supervisor

    RUN mkdir -p /etc/supervisor/conf.d/

    RUN echo "[supervisord] \n\
    nodaemon=true \n\
    [include] \n\
    files = /etc/supervisor/conf.d/*.conf" > /etc/supervisor.conf

    RUN echo "[program:ssh] \n\
    command=/usr/sbin/sshd -D \n\
    autorestart=true \n\
    autostart=true \n\
    redirect_stderr=true" > /etc/supervisor/conf.d/ssh.conf

    CMD ["supervisord", "-c", "/etc/supervisor.conf"]


- Build: `docker build -t ssh_server .`
- Run:   `docker run -p 127.0.0.1:22:22 -i -t ssh_server`
- Login: `ssh root@127.0.0.1`


This will bind the SSH server to the localhost interface on the host machine. If you are running a SSH server on your host then you may want to change the port the container binds to on the host.


### Notes:
- Additional config files can be added to the `/etc/supervisor/conf.d` directory
- Supervisord is designed to work with processes that run in the forground, hence the `-D` switch tells SSH Daemon to run in the foreground.
- If a given process won't run in the foreground, then a [process proxy will be required](https://serverfault.com/a/608073).

