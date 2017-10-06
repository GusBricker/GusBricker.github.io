---
layout:        post_colorful
title:         "Working with Network Manager"
subtitle:      "The better way!"
date:           2017-10-06 +1000
title_style:    "color:#9aeae5"
subtitle_style: "color:#9aeae5"
author_style:   "color:#9aeae5"
header-img: "img/networkmanager.png"
---

Network Manager is the go-to tool for managing networks on Linux. It's well documented, relatively easy to use and has a nice
CLI interface called `nmcli`.

The `nmcli` tool is fairly powerful, it includes a terse mode (`-t`) which when combined with the selectable fields (`-f`) makes parsing its output a
breeze. Initially when you start using `nmcli`, the first thing you might Google is: **connecting to wifi networks with nmcli**.
You will probably find a Stack Overflow post that suggests this: `nmcli dev wifi connect <SSID> password <PASSWORD>`. Depending on your use case, this could be the wrong answer.

To understand why this is the wrong answer, first we need to understand how Network Manager works.
Whenever you attempt join a network, `nmcli dev wifi connect` creates an entry in the `/etc/NetworkManager/system-connections/` folder. The key word in the last sentence is **attempt**.
If you enter the wrong password or SSID, `nmcli` will silently create an entry in that folder.
Basically any time `nmcli dev wifi connect` is executed a new entry is added under the SSID name, if that entry exists the entry name is silently numerically incremented (eg: **mywifi** becomes **mywifi 1**).

You may be thinking, who cares? As long as I can join the WiFi whats the big deal? The issue comes when you want to manage the WiFi connection (disconnect/forget/modify).
For example, to disconnect from a WiFi network the command to use is `nmcli con down <ID>`. The ID being the entry in the `/etc/NetworkManager/system-connections/` folder. How can we reliably know what ID to use given that `nmcli dev wifi connect` doesn't neccesarily use the SSID as the ID?

This scenario repeats over and over again, for example to forget a network we use `nmcli con delete <ID>`. To manage the network settings we use `nmcli con modify <ID>`, etc...


## The Solution

The following script ensures the entries in the `/etc/NetworkManager/system-connections/` folder are the actual SSID of the access point by manually creating the network vs using `nmcli dev wifi connect`.

The script works by essentially checking if it has seen the WiFi network previously, if it has then it deletes the network and re-creates it manually using
`nmcli con add` command. There is a fair bit of logic to get this right, but my tests shows it works reliably. In the interest of keeping the script
small, it only handles WPA1/WPA2 networks (you shouldn't be using Open/WEP networks anyway!).

{% highlight python %}
#!/bin/bash

# Usage: ```join.sh <SSID> <INTERFACE> <PASSWORD>```
# Author: Chris Lapa
# https://pipefail.io

SSID=$1
INTERFACE=$2
PASSWORD=$3

if ! nmcli con show "${SSID}" > /dev/null 2>&1
then
    echo "${SSID}: Not seen previously"
    if nmcli con add con-name "${SSID}" ifname "${INTERFACE}" type wifi ssid "${SSID}" > /dev/null
    then
        echo "${SSID}: Setting PSK key"
        if ! nmcli con modify "${SSID}" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "${PASSWORD}" > /dev/null
        then
            nmcli con delete "${SSID}" > /dev/null
            exit 1
        fi
    else
        nmcli con delete "${SSID}" > /dev/null
        exit 1
    fi

    echo "${SSID}: Joining"
    if ! nmcli con up "${SSID}" > /dev/null
    then
        echo "${SSID}: Join failure"
        nmcli con delete "${SSID}" > /dev/null
        exit 1
    else
        echo "${SSID}: Join success"
        exit 0
    fi
else
    echo "${SSID}: Seen previously"

    echo "${SSID}: Joining"
    if ! nmcli con up "${SSID}" > /dev/null
    then
        echo "${SSID}: Join failure, maybe password changed or wrong one stored?"
        nmcli con delete "${SSID}" > /dev/null

        if nmcli con add con-name "${SSID}" ifname "${INTERFACE}" type wifi ssid "${SSID}" > /dev/null
        then
            echo "${SSID}: Setting PSK key"
            if ! nmcli con modify "${SSID}" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "${PASSWORD}" > /dev/null
            then
                nmcli con delete "${SSID}" > /dev/null
                exit 1
            fi
        else
            nmcli con delete "${SSID}" > /dev/null
            exit 1
        fi

        echo "${SSID}: Joining"
        if ! nmcli con up "${SSID}" > /dev/null
        then
            echo "${SSID}: Join failure"
            nmcli con delete "${SSID}" > /dev/null
            exit 1
        else
            echo "${SSID}: Join success"
            exit 0
        fi
    else
        echo "${SSID}: Join success"
        exit 0
    fi
fi

exit  1
{% endhighlight %}

---


## Moarrr Scripts!

### Scan For Networks


{% highlight python %}
#!/bin/bash

# Usage: ```scan.sh```
# Author: Chris Lapa
# https://pipefail.io

nmcli -f SSID,CHAN,SECURITY,BARS,ACTIVE,BSSID dev wifi
{% endhighlight %}

---


### Forget Network


{% highlight python %}
#!/bin/bash

# Usage: ```forget.sh <SSID>```
# Author: Chris Lapa
# https://pipefail.io

SSID=$1

echo "${SSID}: Forgetting"
nmcli con delete "${SSID}" > /dev/null
ret_code=$?

if [ $ret_code -ne 0 ]
then
    echo "${SSID}: Forgetting failure"
else
    echo "${SSID}: Forgetting success"
fi

exit "${ret_code}"
{% endhighlight %}

---


### Check Connected To


{% highlight python %}
#!/bin/bash

# Usage: ```connected_to.sh <SSID>```
# Author: Chris Lapa
# https://pipefail.io

SSID=$1

echo "${SSID}: Checking"
connected=$(nmcli -t -f SSID,ACTIVE d wifi list | grep "${SSID}" | cut -d':' -f2)
ret_code=$?

if [[ "x${connected}" == "xyes" ]]
then
    echo "${SSID}: Connected"
    exit 0
fi

echo "${SSID}: Not connected"
exit 1
{% endhighlight %}

---

### Disconnect


{% highlight python %}
#!/bin/bash

# Usage: ```disconnect.sh <SSID>```
# Author: Chris Lapa
# https://pipefail.io

SSID=$1

echo "${SSID}: Disconnecting"
nmcli con down "${SSID}" > /dev/null
ret_code=$?

if [ $ret_code -ne 0 ]
then
    echo "${SSID}: Disconnect failure"
else
    echo "${SSID}: Disconnect success"
fi

exit "${ret_code}"
{% endhighlight %}

---


#### Sources:
- <https://developer.gnome.org/NetworkManager/stable/>
- <https://forums.kali.org/showthread.php?36275-Help-with-nmcli-and-connecting-to-specific-bssid-(error-53)>
- <https://www.juniper.net/documentation/en_US/junos-space-apps/network-director2.0/topics/concept/wireless-ssid-bssid-essid.html>
