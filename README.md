# nftables
nftables commands and examples

# Nftables documentation examples
#### Main Page wiki doc
https://wiki.nftables.org/wiki-nftables/index.php/Main_Page#Installing_nftables

# EVERY CHANGE MADE HAS TO BE LOADED
### Method 1 `nft list ruleset > /etc/nftables.conf`
- This works with some distributions that have the config file in etc.
### Method 2 `nft list ruleset > /etc/nftables/main.nft`
- We apply them to main.nft file and then include the file in nft config
- We can also overwrite the config but working with .nft files is better and cleaner

```
$ cat /etc/sysconfig/nftables.conf  
# Uncomment the include statement here to load the default config sample  
# in /etc/nftables for nftables service.  
  
include "/etc/nftables/main.nft"  
  
# To customize, either edit the samples in /etc/nftables, append further  
# commands to the end of this file or overwrite it after first service  
# **start by calling: 'nft list ruleset >/etc/sysconfig/nftables.conf'**.
```




# Dports ( Destination ports ) 
# Allow apache port 
```nginx
nft add element inet nftables_svc allowed_tcp_dports { http }
```
### The same way it can be removed with delete instead of add
```nginx
nft delete element inet nftables_svc allowed_tcp_dports { http }
```
### Removing Pings ICMP protocol
```nginx
nft delete element inet nftables_svc allowed_protocols { icmp }
```

### Adding it back
```nginx
nft add element inet nftables_svc allowed_protocols { icmp }
```

### Add IP at the end of the chain with add

```nginx
nft add rule inet nftables_svc INPUT ip daddr 192.168.1.20 counter drop;
```
#### Example
```nginx
chain INPUT { # handle 2  
type filter hook input priority 20; policy accept;  
jump allow # handle 10  
reject # handle 11  
ip daddr 192.168.1.20 counter packets 0 bytes 0 drop # handle 14
```

### Inserting the IP before the reject point with insert

```nginx
nft insert rule inet nftables_svc INPUT ip daddr 192.168.1.20 counter drop;
```

#### Example
```nginx
chain INPUT { # handle 2  
type filter hook input priority 20; policy accept;  
ip daddr 192.168.1.20 counter packets 0 bytes 0 drop # handle 15  
jump allow # handle 10  
reject # handle 11
```
## Insert/add IP with reject statement adds icmp port-unreachable rule

```nginx
nft insert rule inet nftables_svc INPUT ip daddr 192.168.1.20 counter reject;
```
### Example 
```nginx
chain INPUT { # handle 2  
type filter hook input priority 20; policy accept;  
ip daddr 192.168.1.20 counter packets 0 bytes 0 reject with icmp port-unreachable # handle 16  
ip daddr 192.168.1.20 counter packets 0 bytes 0 drop # handle 15  
jump allow # handle 10  
reject # handle 11  
}
```

`reject with icmpx type port-unreachable`
# Adding table for blocking ip's incoming traffic/input

```bash
nft add table ip block_traffic
```

### Add chain to the table 

```bash
nft 'add chain ip block_traffic input { type filter hook input priority 30 ; policy accept; }'
```

## Adding IP to the chaing blocking all traffic from the source address
```bash
nft add ip block_traffic input ip saddr 192.168.1.20 counter reject;
```
- **it is important to note that if the IP is connected it will disconnect it immediately** 
```bash 
nft add ip block_traffic input ip saddr 192.168.1.3 counter reject;
```
- **This is the result after the Ip was added from the 1.3 machine** 
```nginx
client_loop: send disconnect: Connection reset
```

- **Ping probes also are blocked**
```nginx
> ping 192.168.1.116  
  
Pinging 192.168.1.116 with 32 bytes of data:  
Request timed out.  
Request timed out.  
Reply from 192.168.1.116: Destination port unreachable.  
Reply from 192.168.1.116: Destination port unreachable.  
  
Ping statistics for 192.168.1.116:  
Packets: Sent = 4, Received = 2, Lost = 2 (50% loss),
```
# Now let's Remove the IP

```bash
nft delete rule ip block_traffic input handle 6

```
- Note that the counter element counts the bytes data traffic

```bash
nft delete rule ip block_traffic input handle 7
```

- This is how the chain looked with the IP's


![[nft-table-chain-ip-block.jpg]]

# Adding log levels to the incoming traffic from IP or any source
### Log

|log statement|   |   |   |   |   |
|---|---|---|---|---|---|
|_level [over] <value> <unit> [burst <value> <unit>]_|Log level|log<br>log level emerg<br>log level alert<br>log level crit<br>log level err<br>log level warn<br>log level notice<br>log level info<br>log level debug|

```bash
ip saddr 192.168.1.20 log # handle 15  
ip saddr 192.168.1.20 log level crit # handle 16  
ip saddr 192.168.1.20 log level emerg # handle 17  
ip saddr 192.168.1.20 log level alert # handle 18
```

- Command to add the rules 

```bash
nft add ip block_traffic input ip saddr 192.168.1.20 log level alert;

```
- You can change values for the level either it is alert/info/emerg/crit/ 
- output from a running ping towards the host -tailing /var/log/messages 
```bash
Message from syslogd@vlado-c9 at Apr 22 11:51:46 ...  
kernel:IN=eth0 OUT= MAC=52:54:00:2e:ba:1f:ae:9d:dc:f4:29:19:08:00 SRC=192.168.1.20 DST=192.168.1.116 LEN=44 TOS=0x00 PREC=0x00 TTL=41 ID=35280 PROTO=TCP SPT=60713 DPT=911 WINDOW=1024 RES=0x00 SYN URGP=0  
Apr 22 11:51:46 vlado-c9 kernel: IN=eth0 OUT= MAC=52:54:00:2e:ba:1f:ae:9d:dc:f4:29:19:08:00 SRC=192.168.1.20 DST=192.168.1.116 LEN=44 TOS=0x00 PREC=0x00 TTL=52 ID=8384 PROTO=TCP SPT=60713 DPT=5087 WINDOW=1024 RES=0x00 SYN UR  
GP=0
```

#### Reject

- Without log level it will not show anything against ping probes

- Setup reject statement against icmp/icmpx/icmpv6/ip requests

The default **reject** will be the ICMP type **port-unreachable**. The **icmpx** is only used for inet family support

| reject statement              |     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |     |     |     |
| ----------------------------- | --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- | --- | --- |
| _with <protocol> type <type>_ |     | reject<br>reject with icmp type host-unreachable<br>reject with icmp type net-unreachable<br>reject with icmp type prot-unreachable<br>reject with icmp type port-unreachable<br>reject with icmp type net-prohibited<br>reject with icmp type host-prohibited<br>reject with icmp type admin-prohibited<br>reject with icmpv6 type no-route<br>reject with icmpv6 type admin-prohibited<br>reject with icmpv6 type addr-unreachable<br>reject with icmpv6 type port-unreachable<br>reject with icmpx type host-unreachable<br>reject with icmpx type no-route<br>reject with icmpx type admin-prohibited<br>reject with icmpx type port-unreachable<br>ip protocol tcp reject with tcp reset |     |     |     |
#### Reject command example
```bash
nft add ip block_traffic input ip saddr 192.168.1.20 reject with icmp type host-unreachable;
```

#### Limit

|limit statement|   |   |   |   |   |
|---|---|---|---|---|---|
|_rate [over] <value> <unit> [burst <value> <unit>]_|Rate limit|limit rate 400/minute<br>limit rate 400/hour<br>limit rate over 40/day<br>limit rate over 400/week<br>limit rate over 1023/second burst 10 packets<br>limit rate 1025 kbytes/second<br>limit rate 1023000 mbytes/second<br>limit rate 1025 bytes/second burst 512 bytes<br>limit rate 1025 kbytes/second burst 1023 kbytes<br>limit rate 1025 mbytes/second burst 1025 kbytes<br>limit rate 1025000 mbytes/second burst 1023 mbytes|
```bash
nft add ip block_traffic input ip saddr 192.168.1.20 limit rate 5/minute;
```

### Using sets to block IP's
### Add IP set to the block_traffic table
```nginx
nft add set ip block_traffic blocked_ips { type ipv4_addr\; comment \"drop all packets from these hosts\" \; }
```
- this is how it looks like 
```nginx
table ip block_traffic {  
set blocked_ips {  
type ipv4_addr  
comment "drop all packets from these hosts"
```

- Adding element to the set and then adding the set to a chain with drop rule 
```nginx
nft add element ip block_traffic blocked_ips { 192.168.1.20 }
```

- adding it to the chain now so the traffic can be blocked

```nginx
nft add rule ip block_traffic input ip saddr @blocked_ips drop
```


- Remove element from the set
```nginx
nft delete element ip block_traffic blocked_ips { 192.168.1.20 }
```

- Add set for temporary blocks with timeout/dynamic flags
```nginx
nft add set ip block_traffic temp_blocks { type ipv4_addr\; flags timeout,dynamic\; }

```
```nginx
nft add rule ip block_traffic input set update ip saddr timeout 60s @temp_blocks

```


- Delete set by handle number
- 
```nginx
nft delete set ip block_traffic handle 27
```

- add new set with interval/constant flags
```nginx
nft add set ip block_traffic temp_blocks { type ipv4_addr\; flags constant, interval\; }
```


## nftables.conf syntax Example

When working with nftables.conf, you can define sets in a number of ways. You can then reference those sets later on using `$VARIABLE_NAME` notation.

Here are some examples showing sets defined in one line, spanning multiple lines, and sets referencing other sets. The set is then used in a rule to allow incoming traffic from certain IP ranges.

```
define SIMPLE_SET = { 192.168.1.1, 192.168.1.2 }

define CDN_EDGE = {
    192.168.1.1,
    192.168.1.2,
    192.168.1.3,
    10.0.0.0/8
}

define CDN_MONITORS = {
    192.168.1.10,
    192.168.1.20
}

define CDN = {
    $CDN_EDGE,
    $CDN_MONITORS
}
```

# Blackhole set blocked ip's
- Add element
```nginx
nft add element ip block_traffic blackhole { 192.168.1.20 }

```
- Delete element
```nginx
nft delete element ip block_traffic blackhole { 192.168.1.20 }
```

```nginx
nft delete element ip block_traffic blackhole { 185.199.38.18 }
```

- rules list
```nginx 
table ip block_traffic { # handle 4  
set blocked_ips { # handle 24  
type ipv4_addr  
comment "drop all packets from these hosts"  
}  
  
set blackhole { # handle 34  
type ipv4_addr  
comment "drop all packets from these hosts"  
elements = { 185.199.38.18, 192.168.1.20 }

chain input { # handle 2  
type filter hook input priority 30; policy accept;  
ip saddr @blackhole drop # handle 35
```

- Creating a Set to add elements and setting up the set in a deny rule 
- When adding new element it will automatically be caught by the deny rule in the input chain
## Set families
- ip
- ip6
- inet
- arp
- bridge
- netdev
### How to list only the set rules
```nginx
nft list set ip block_traffic blackhole
```

- List all sets with certain family tipe { ip , netdev,inet etc}
```nginx
nft list sets ip
table ip block_traffic {  
set blocked_ips {  
type ipv4_addr  
comment "drop all packets from these hosts"  
}  
set blackhole {  
type ipv4_addr  
comment "drop all packets from these hosts"  
elements = { 192.168.1.20 }  
}  
}
```
# Expressions
https://wiki.nftables.org/wiki-nftables/index.php/Building_rules_through_expressions

- **eq** which stands for _equal_. Alternatively you can use **==**.
- **ne** which stands for _not equal_. Alternatively you can use **!=**.
- **lt** which stands for _less than_. Alternatively you can use **<**.
- **gt** which stands for _greater than_. Alternatively you can use **>**.
- **le** which stands for _less than or equal to_. Alternatively you can use **<=**.
- **ge** which stands for _greater than or equal to_. Alternatively you can use **>=**.

# interface meta selectors for ethernet interface devices
### # Matching packet metainformation

https://wiki.nftables.org/wiki-nftables/index.php/Matching_packet_metainformation

# Netdev type table
```nginx
nft add chain netdev ddos_prot protection { type filter hook ingress device eth0 priority 0\; }
```
https://www.netdevconf.org/1.1/proceedings/slides/pablo-neira-nft-ingress.pdf
