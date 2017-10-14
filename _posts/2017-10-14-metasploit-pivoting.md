---
layout:        post_colorful
title:         "Metasploit Pivoting through Victims"
subtitle:      "PIVOTTT!"
date:           2017-10-14 +1000
title_style:    "color:#FFFFFF"
subtitle_style: "color:#FFFFFF"
author_style:   "color:#FFFFFF"
header-img: "img/pivot.jpg"
---

I'm currently working my way through the [PTPv4 course offered by eLearn Security](https://www.elearnsecurity.com/course/penetration_testing).
One of the labs involves extending our reach to otherwise inaccessible networks by pivoting through a Victim that we already have an active Meterpreter session on.

I'm going to skip the network discovery part and jump straight into the interesting bits! Therefore assume the network map looks like this:

{% mermaid %}
graph LR;
	me["ME: 172.16.5.40"];
	host1["VICTIM 1: 10.32.120.15"];
	host2["VICTIM 2: 10.32.121.23"];
	me ==> host1;
	host1 ==> host2;
{% endmermaid %}


As seen below, we have an existing Meterpreter session active for **Victim 1**. We will be using this session to pivot via **Victim 1** to access **Victim 2**.
{% figure 2017-10-13-metasploit-pivoting/sessions png 'Meterpreter session on Victim 1' %}


---
### Socks Module Setup

We will need to use the Socks4a Metasploit module to setup a proxy from Meterpreter to our system. The Socks proxy is required because Meterpreter uses its own separate routing table vs what the host uses. Meaning only Metasploit can access the routes it sets up unless we use a proxy. 
{% figure 2017-10-13-metasploit-pivoting/socks_setup png 'Socks Proxy Module' %}


---
### Adding Default Routes
Next up we will use the Autoroute module with the **CMD** set to **default** and the **SESSION** set to 14 (see Figure 1). The **SUBNET** setting is
not required when using **default**.
This tells Metasploit to add a default route to its routing table, routing all traffic Metasploit see's through **VICTIM 1**. When combined with the Socks proxy setup previously, it allows access to any system that **VICTIM 1** can access via our machine. 
{% figure 2017-10-13-metasploit-pivoting/autoroute png 'Autoroute Module' %}

---
### Foxyproxy
The final step is to use our proxy outside of Metasploit. In this case, I'm using FoxyProxy in Firefox but another common
route is to use proxychains (which comes installed by default in Kali).
{% figure 2017-10-13-metasploit-pivoting/foxyproxy png 'FoxyProxy Setup' %}


---
### Testing
All thats left to do is to test we can accesss **VICTIM 2** via Firefox, and as seen in Figure 5 it works!
{% figure 2017-10-13-metasploit-pivoting/test png 'Testing' %}


---
### Takeaway's
- Metasploits routing table != system routing table
- Pivoting is a great way to gain access to networks that aren't connected to the internet!


#### Sources:
- <https://github.com/rapid7/metasploit-framework/blob/master/documentation/modules/post/multi/manage/autoroute.md>
