---
layout:     post
title:      "Seting up a Debian Archive Mirror"
subtitle:   "Mirror mirror on the wall whose the prettiest Debian Archive Mirror of them all?"
date:       2017-01-14
header-img: "img/download-bg-01.jpg"
---

Waiting for packages to download is the worst, especially when you are doing lots of Root File System development.
Theres a relatively easy solution to this: setup your own Debian Archive Mirror. I have successfully used the following steps on a ARM board and an Intel NUC.

I like to learn by example, so I will use example parameters listed below for the steps.

### Parameters:

- Mirror name: ```Your Company Package Mirror```
- Hostname: ```yourcompany.com```
- Install directory: ```/opt/ftpsync```
- Architectures Synced: ```armhf source amd64 i386 al```
- Admin email: ```admin@yourcompany.com```
- Email smtp: ```yourcompany.com:465```
- Debian repo dir: ```/var/www/packages/debian```
- Username on server: ```user1```
- Ftpsync install dir: ```/opt/ftpsync```


### Setup:

1. Download the latest version of ftpsync: ```https://ftp-master.debian.org/ftpsync.tar.gz```

2. Extract to: ```/opt/ftpsync```

3. Dependancies: ```heirloom-mailx ssmtp apache2 rsync```

4. Setup SSMTP configuration file: ```/etc/ssmtp/ssmtp.conf```

    <!-- language: bash -->

        # Config file for sSMTP sendmail
        #
        # The person who gets all mail for userids < 1000
        # Make this empty to disable rewriting.
        root=admin@yourcompany.com

        # The place where the mail goes. The actual machine name is required no 
        # MX records are consulted. Commonly mailhosts are named mail.domain.com

        # Where will the mail seem to come from?
        rewriteDomain=yourcompany.com

        # The full hostname
        hostname=yourcompany.com

        # Are users allowed to set their own From: address?
        # YES - Allow the user to specify their own From: address
        # NO - Use the system generated From: address
        FromLineOverride=Yes
        AuthUser=admin@yourcompany.com
        AuthPass=****
        mailhub=yourcompany.com:465
        UseTLS=Yes

5. Setup SSMTP revaliases: ```/etc/ssmtp/revaliases```

    <!-- language: bash -->

        roott:admin@yourcompany.com:yourcompany.com:465
        user1:admin@yourcompany.com:yourcompany.com:465

6. Test SSMTP settings: ```echo "Helloworld" | mailx -s "This is a test" "admin@yourcomany.com"```

7. Setup apache2: ```/etc/apache2/sites-available/000-default.conf```

    <!-- language: bash -->

        <VirtualHost *:80>
            # The ServerName directive sets the request scheme, hostname and port that
            # the server uses to identify itself. This is used when creating
            # redirection URLs. In the context of virtual hosts, the ServerName
            # specifies what hostname must appear in the request's Host: header to
            # match this virtual host. For the default virtual host (this file) this
            # value is not decisive as it is used as a last resort host regardless.
            # However, you must set it for any further virtual host explicitly.
            ServerName yourcompany.com

            ServerAdmin admin@yourcompany.com
            DocumentRoot /var/www/packages

            # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
            # error, crit, alert, emerg.
            # It is also possible to configure the loglevel for particular
            # modules, e.g.
            #LogLevel info ssl:warn

            ErrorLog ${APACHE_LOG_DIR}/error.log
            CustomLog ${APACHE_LOG_DIR}/access.log combined

            # For most configuration files from conf-available/, which are
            # enabled or disabled at a global level, it is possible to
            # include a line for only one particular virtual host. For example the
            # following line enables the CGI configuration for this host only
            # after it has been globally disabled with "a2disconf".
            #Include conf-available/serve-cgi-bin.conf
        </VirtualHost>

        <Directory "/var/www/packages”>
            Options +Indexes +SymlinksIfOwnerMatch
        </Directory>

8. Setup the ServerName globally: 
    1. ```echo "ServerName yourcompany.com" | sudo tee /etc/apache2/conf-available/fqdn.conf```
    2. ```sudo a2enconf fqdn```
    3. ```sudo service apache2 reload```
    4. ```sudo apache2ctl configtest```

9. Setup ftpsync config: /opt/ftpsync/etc/ftpsync.conf.
    The config is relatively straight forward. Picking a fast mirror is important. For me, the primary Australian Debian mirror (ftp.au.debian.org) was the slowest. I would suggest using a tool such as netselect-apt to find the fastest mirror nearby. The fastest mirror for me was the Monash University mirror, however I could not use it as not all mirrors contain all the packages you want. For example I needed the armhf architectures which it did not contain.

    You can also use check the RSYNC_HOST is set correctly by using rsync directly: ```rsync debian.mirror.digitalpacific.com.au::```. The two colons on the end are not a typo. Normally you would put the rsync module after the colons so leaving it empty is essentially a wildcard telling the server to list all the modules. You shouldn’t include the colons when you set RSYNC_HOST in the config.

    I would also suggest uncommenting the LOCK variable so that ftpsync tool is protected from concurrent instances running. You also shouldn't neeed to edit anything below the BE VERY CAREFUL lines.

    Example config using our parameters above:

    <!-- language: bash -->

        ## Mirrorname. This is used for things like the trace file name and should always
        ## be the full hostname of the mirror.
        MIRRORNAME=Your Company Package Mirror

        ## Destination of the mirrored files. Should be an empty directory.
        ## CAREFUL, this directory will contain the mirror. Everything else
        ## that might have happened to be in there WILL BE GONE after the mirror sync!
        TO="/var/www/packages/debian"

        ## The upstream name of the rsync share.
        ##
        ## You can find out what share names your upstream mirror supports by running
        ## rsync YOURUPSTREAMSERVER::
        ## (You might have to export RSYNC_USER/RSYNC_PASSWORD for this to work)
        RSYNC_PATH="debian"

        ## The host we mirror from
        RSYNC_HOST="debian.mirror.digitalpacific.com.au"

        ## In case we need a user to access the rsync share at our upstream host
        #RSYNC_USER=

        ## If we need a user we also need a password
        #RSYNC_PASSWORD=

        ## Set to "true" to tunnel your rsync through stunnel.
        ##
        ## ftpsync will then use rsync's -e option to wrap the connection
        ## with bin/rsync-ssl-tunnel which sets up an stunnel to connect to
        ## RSYNC_SSL_PORT on the remote site.  (This requires server
        ##  support, obviously.)
        ##
        ## ftpsync can use either stunnel4, stunnel4-old, or socat to set up the
        ## encrypted tunnel.
        ##  o stunnel4 requires at least stunnel4 version 5.15 built aginst openssl
        ##    1.0.2 or later such that the stunnel build supports the checkHost
        ##    service-level option.  This will cause stunnel to verify both the
        ##    peer certificate's validity and that it's actually for the host we wish
        ##    to connect to.
        ##  o stunnel4-old will skip the checkHost check.  As such it will connect
        ##    to any peer that is able to present a valid certificate, regardless of
        ##    which name it is made out to.
        ##  o socat will verify the peer certificate name only starting with version
        ##    1.7.3 (Debian 9.0).
        ## To test if things work, you can run
        ##  RSYNC_SSL_PORT=1873 RSYNC_SSL_CAPATH=/etc/ssl/certs RSYNC_SSL_METHOD=socat rsync -e 'bin/rsync-ssl-tunnel' <server>::
        #RSYNC_SSL=false
        #RSYNC_SSL_PORT=1873
        #RSYNC_SSL_CAPATH=/etc/ssl/certs
        #RSYNC_SSL_METHOD=stunnel4

        ## In which directory should logfiles end up
        ## Note that BASEDIR defaults to $HOME, but can be set before calling the
        ## ftpsync script to any value you want (for example using pam_env)
        LOGDIR="${BASEDIR}/log"

        ## Name of our own logfile.
        ## Note that ${NAME} is set by the ftpsync script depending on the way it
        ## is called. See README for a description of the multi-archive capability
        ## and better always include ${NAME} in this path.
        LOG="${LOGDIR}/${NAME}.log"

        ## The script can send logs (or error messages) to a mail address.
        ## If this is unset it will default to the local root user unless it is run
        ## on a .debian.org machine where it will default to the mirroradm people.
        MAILTO="admin@yourcompany.com"

        ## If you do want a mail about every single sync, set this to false
        ## Everything else will only send mails if a mirror sync fails
        ERRORSONLY="false"

        ## If you want the logs to also include output of rsync, set this to true.
        ## Careful, the logs can get pretty big, especially if it is the first mirror
        ## run
        FULLLOGS="false"

        ## If you do want to exclude files from the mirror run, put --exclude statements here.
        ## See rsync(1) for the exact syntax, these are passed to rsync as written here.
        ## DO NOT TRY TO EXCLUDE ARCHITECTURES OR SUITES WITH THIS, IT WILL NOT WORK!
        #EXCLUDE=""

        ## If you do want to exclude an architecture, this is for you.
        ## Use as space seperated list.
        ## Possible values are:
        ## alpha amd64 arm arm64 armel armhf hppa hurd-i386 i386 ia64 kfreebsd-amd64
        ## kfreebsd-i386 m68k mipsel mips powerpc ppc64el s390 s390x sh sparc source
        ## eg. ARCH_EXCLUDE="alpha arm arm64 armel mipsel mips s390 sparc"
        ## An unset value will mirror all architectures (default!)
        ## Mutually exclusive with ARCH_INCLUDE.
        ## Notice: source must not be excluded on an official/public mirror
        #ARCH_EXCLUDE=""

        ## If you do want to include only a set of architectures, this is for you.
        ## Use as space seperated list.
        ## Possible values are:
        ## alpha amd64 arm arm64 armel armhf hppa hurd-i386 i386 ia64 kfreebsd-amd64
        ## kfreebsd-i386 m68k mipsel mips powerpc ppc64el s390 s390x sh sparc source
        ## eg. ARCH_INCLUDE="amd64 i386 source"
        ## An unset value will mirror all architectures (default!)
        ## Arch all will be included automatically if one binary arch is included.
        ## Mutually exclusive with ARCH_EXCLUDE.
        ## Notice: source needs to be included on an official/public mirror
        ARCH_INCLUDE="armhf source amd64 i386 all"

        ## Do we have leaf mirror to signal we are done and they should sync?
        ## If so set it to true and make sure you configure runmirrors.mirrors
        ## and runmirrors.conf for your need.
        #HUB=false

        ## We do create three logfiles for every run. To save space we rotate them, this
        ## defines how many we keep
        LOGROTATE=14

        ## Our own lockfile (only one sync should run at any time)
        LOCK="${TO}/Archive-Update-in-Progress-${MIRRORNAME}"

        # Timeout for the lockfile, in case we have bash older than v4 (and no /proc)
        # LOCKTIMEOUT=${LOCKTIMEOUT:-3600}

        ## The following file is used to make sure we will end up with a correctly
        ## synced mirror even if we get multiple pushes in a short timeframe
        #UPDATEREQUIRED="${TO}/Archive-Update-Required-${MIRRORNAME}"

        ## Number of seconds to sleep before retrying to sync whenever upstream
        ## is found to be updating while our update is running
        #UIPSLEEP=1200

        ## Number of times the update operation will be retried when upstream
        ## is found to be updating while our update is running.
        ## Note that these are retries, so: 1st attempt + retries = total attempts
        #UIPRETRIES=3

        ## The trace file is used by a mirror check tool to see when we last
        ## had a successful mirror sync. Make sure that it always ends up in
        ## project/trace and always shows the full hostname.
        ## This is *relative* to ${TO}
        #TRACE="project/trace/${MIRRORNAME}"

        ## The trace file can have different format/contents. Here you can select
        ## what it will be.
        ## Possible values are
        ## "full"  - all information
        ## "terse" - partial, ftpsync version and local hostname
        ## "date"  - basic, timestamp only (date -u)
        ## "touch" - just touch the file in existance
        ## "none"  - no tracefile at all
        ##
        ## Default and required value for Debian mirrors is full.
        #EXTENDEDTRACE="full"

        ## The local hostname to be written to the trace file.
        #TRACEHOST="$(hostname -f)"

        ## We sync our mirror using rsync (everything else would be insane), so
        ## we need a few options set.
        ## The rsync program
        #RSYNC=rsync

        ## Extra rsync options as defined by the local admin.
        ## There is no default by ftpsync.
        ##
        ## Please note that these options are added to EVERY rsync call.
        ## Also note that these are added at the beginning of the rsync call, as
        ## the very first set of options.
        ## Please ensure you do not add a conflict with the usual rsync options as
        ## shown below.
        #RSYNC_EXTRA="-vvv"

        ## limit I/O bandwidth. Value is KBytes per second, unset or 0 means unlimited
        #RSYNC_BW=""

        ## BE VERY CAREFUL WHEN YOU CHANGE THE RSYNC_OPTIONS! BETTER DON'T!
11. Setup a cron job. You should aim to synchronise your modules 4 times a day. However if the upstream server you are using is in the middle of a sync then the update will fail. 

    <!-- language: bash -->

        $ crontab -e
        00 03 * * * /opt/ftpsync/bin/ftpsync sync:all
        00 06 * * * /opt/ftpsync/bin/ftpsync sync:all
        00 12 * * * /opt/ftpsync/bin/ftpsync sync:all
        00 21 * * * /opt/ftpsync/bin/ftpsync sync:all
12. Wait for your first sync to finish!
