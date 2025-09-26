# Network Configuration
Generated: Fri Sep 26 08:22:23 EDT 2025

## Docker Networks
```
NETWORK ID     NAME                                         DRIVER    SCOPE
f3e70b64d392   bridge                                       bridge    local
67d4c59a03e5   host                                         host      local
66236ef09bdc   macstudio-optionb_default                    bridge    local
37ada2ba04c1   medinovai-healthllm_medinovai-network        bridge    local
812985b75929   medinovai-researchsuite_medinovai-analysis   bridge    local
51d80910b262   medinovai-restructured-network               bridge    local
d5d4cc20eda1   none                                         null      local
98fd02ac1c08   obsidian-docker_obsidian-network             bridge    local
9e68522a1b76   qualitymanagementsystem_qms-network          bridge    local
```

## Network Details
```
{
  "Name": "bridge",
  "Driver": "bridge",
  "IPAM": {
    "Driver": "default",
    "Options": null,
    "Config": [
      {
        "Subnet": "172.17.0.0/16",
        "Gateway": "172.17.0.1"
      }
    ]
  }
}
{
  "Name": "host",
  "Driver": "host",
  "IPAM": {
    "Driver": "default",
    "Options": null,
    "Config": null
  }
}
{
  "Name": "macstudio-optionb_default",
  "Driver": "bridge",
  "IPAM": {
    "Driver": "default",
    "Options": null,
    "Config": [
      {
        "Subnet": "172.18.0.0/16",
        "Gateway": "172.18.0.1"
      }
    ]
  }
}
{
  "Name": "medinovai-healthllm_medinovai-network",
  "Driver": "bridge",
  "IPAM": {
    "Driver": "default",
    "Options": null,
    "Config": [
      {
        "Subnet": "172.30.0.0/16",
        "Gateway": "172.30.0.1"
      }
    ]
  }
}
{
  "Name": "medinovai-researchsuite_medinovai-analysis",
  "Driver": "bridge",
  "IPAM": {
    "Driver": "default",
    "Options": null,
    "Config": [
      {
        "Subnet": "172.21.0.0/16",
        "Gateway": "172.21.0.1"
      }
    ]
  }
}
{
  "Name": "medinovai-restructured-network",
  "Driver": "bridge",
  "IPAM": {
    "Driver": "default",
    "Options": null,
    "Config": [
      {
        "Subnet": "172.19.0.0/16",
        "Gateway": "172.19.0.1"
      }
    ]
  }
}
{
  "Name": "none",
  "Driver": "null",
  "IPAM": {
    "Driver": "default",
    "Options": null,
    "Config": null
  }
}
{
  "Name": "obsidian-docker_obsidian-network",
  "Driver": "bridge",
  "IPAM": {
    "Driver": "default",
    "Options": null,
    "Config": [
      {
        "Subnet": "172.20.0.0/16",
        "Gateway": "172.20.0.1"
      }
    ]
  }
}
{
  "Name": "qualitymanagementsystem_qms-network",
  "Driver": "bridge",
  "IPAM": {
    "Driver": "default",
    "Options": null,
    "Config": [
      {
        "Subnet": "172.26.0.0/16"
      }
    ]
  }
}
```

## Host Network Interfaces
```
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
	options=1203<RXCSUM,TXCSUM,TXSTATUS,SW_TIMESTAMP>
--
gif0: flags=8010<POINTOPOINT,MULTICAST> mtu 1280
stf0: flags=0<> mtu 1280
anpi2: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
anpi0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
anpi4: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
anpi5: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
anpi1: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
anpi3: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=567<RXCSUM,TXCSUM,VLAN_MTU,TSO4,TSO6,AV,CHANNEL_IO>
--
en8: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
en9: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
en10: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
en11: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
en12: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
en13: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
en2: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1500
	options=460<TSO4,TSO6,CHANNEL_IO>
--
en3: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1500
	options=460<TSO4,TSO6,CHANNEL_IO>
--
en4: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1500
	options=460<TSO4,TSO6,CHANNEL_IO>
--
en5: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1500
	options=460<TSO4,TSO6,CHANNEL_IO>
--
en6: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1500
	options=460<TSO4,TSO6,CHANNEL_IO>
--
en7: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1500
	options=460<TSO4,TSO6,CHANNEL_IO>
--
bridge0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=63<RXCSUM,TXCSUM,TSO4,TSO6>
--
	member: en2 flags=3<LEARNING,DISCOVER>
	        ifmaxaddr 0 port 17 priority 0 path cost 0
	member: en3 flags=3<LEARNING,DISCOVER>
	        ifmaxaddr 0 port 18 priority 0 path cost 0
	member: en4 flags=3<LEARNING,DISCOVER>
	        ifmaxaddr 0 port 19 priority 0 path cost 0
	member: en5 flags=3<LEARNING,DISCOVER>
	        ifmaxaddr 0 port 20 priority 0 path cost 0
	member: en6 flags=3<LEARNING,DISCOVER>
	        ifmaxaddr 0 port 21 priority 0 path cost 0
	member: en7 flags=3<LEARNING,DISCOVER>
	        ifmaxaddr 0 port 22 priority 0 path cost 0
--
utun0: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1500
	inet6 fe80::ad06:bbc7:a516:644%utun0 prefixlen 64 scopeid 0x1a 
--
utun1: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1380
	inet6 fe80::3ef7:1a5a:eb95:6630%utun1 prefixlen 64 scopeid 0x1b 
--
ap1: flags=8822<BROADCAST,SMART,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
en1: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=6460<TSO4,TSO6,CHANNEL_IO,PARTIAL_CSUM,ZEROINVERT_CSUM>
--
awdl0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=6460<TSO4,TSO6,CHANNEL_IO,PARTIAL_CSUM,ZEROINVERT_CSUM>
--
llw0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
--
utun2: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 2000
	inet6 fe80::bae8:b61d:7034:e75c%utun2 prefixlen 64 scopeid 0x1e 
--
utun3: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1000
	inet6 fe80::ce81:b1c:bd2c:69e%utun3 prefixlen 64 scopeid 0x1f 
--
utun4: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1280
	options=6460<TSO4,TSO6,CHANNEL_IO,PARTIAL_CSUM,ZEROINVERT_CSUM>
--
utun5: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1380
	inet6 fe80::ecd2:6379:cb:d53d%utun5 prefixlen 64 scopeid 0x24 
--
vmenet0: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1500
	ether 9a:82:76:fb:5c:17
--
bridge100: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=3<RXCSUM,TXCSUM>
--
	member: vmenet0 flags=3<LEARNING,DISCOVER>
	        ifmaxaddr 0 port 37 priority 0 path cost 0
--
vmenet1: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1500
	ether 5e:c3:e0:e7:7a:25
--
bridge101: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=3<RXCSUM,TXCSUM>
--
	member: vmenet1 flags=3<LEARNING,DISCOVER>
	        ifmaxaddr 0 port 39 priority 0 path cost 0
```

## Routing Table
```
Routing tables

Internet:
Destination        Gateway            Flags               Netif Expire
default            192.168.68.1       UGScg                 en1       
default            link#32            UCSIg               utun4       
default            link#38            UCSIg           bridge100      !
default            link#40            UCSIg           bridge101      !
8.8.4.4            link#32            UHWIig              utun4       
8.8.8.8            link#32            UHWIig              utun4       
10.37.129/24       link#40            UC              bridge101      !
10.211.55/24       link#38            UC              bridge100      !
100.64/10          link#32            UCS                 utun4       
100.87.47.68       100.87.47.68       UH                  utun4       
100.100.100.100/32 link#32            UCS                 utun4       
100.100.100.100    link#32            UHWIi               utun4       
127                127.0.0.1          UCS                   lo0       
127.0.0.1          127.0.0.1          UH                    lo0       
169.254            link#24            UCS                   en1      !
192.168.68/22      link#24            UCS                   en1      !
192.168.68.1/32    link#24            UCS                   en1      !
192.168.68.1       b0:19:21:9:89:ac   UHLWIir               en1   1198
192.168.68.52/32   link#24            UCS                   en1      !
192.168.68.52      e6:1e:1b:7a:1e:52  UHLWI                 lo0       
192.168.68.54      dc:cd:2f:a:89:ed   UHLWI                 en1      !
192.168.68.56      f0:2f:4b:15:16:2b  UHLWI                 en1    244
192.168.68.58      4e:80:c9:19:a9:b4  UHLWI                 en1    850
192.168.68.59      78:2b:64:71:2:f7   UHLWI                 en1   1180
192.168.68.60      98:cd:ac:bd:54:a4  UHLWI                 en1   1122
192.168.68.65      cc:60:23:22:d1:16  UHLWI                 en1      !
192.168.68.66      9e:be:3e:cd:d9:c0  UHLWI                 en1    810
192.168.68.68      48:e1:5c:98:fe:a3  UHLWI                 en1    711
192.168.68.70      94:e6:86:52:40:2c  UHLWI                 en1      !
192.168.68.72      2e:f8:98:1d:3:e2   UHLWIi                en1   1046
192.168.68.73      9a:c7:5e:34:1:e4   UHLWI                 en1   1081
192.168.68.74      e0:e2:e6:32:12:10  UHLWI                 en1   1188
192.168.68.75      38:2c:e5:c:7a:fd   UHLWI                 en1      !
192.168.68.76      38:2c:e5:c:7e:bd   UHLWI                 en1      !
192.168.68.77      38:2c:e5:c:72:70   UHLWI                 en1      !
192.168.68.78      38:2c:e5:c:73:7    UHLWI                 en1      !
192.168.68.80      38:2c:e5:c:7c:14   UHLWI                 en1      !
192.168.68.81      38:2c:e5:c:7b:ae   UHLWI                 en1      !
192.168.68.82      38:2c:e5:c:6a:da   UHLWI                 en1      !
192.168.68.83      38:2c:e5:c:7e:1e   UHLWI                 en1      !
192.168.68.84      50:14:79:1f:81:25  UHLWI                 en1   1199
224.0.0/4          link#24            UmCS                  en1      !
224.0.0/4          link#32            UmCSI               utun4       
224.0.0.251        1:0:5e:0:0:fb      UHmLWI                en1       
239.255.255.250    1:0:5e:7f:ff:fa    UHmLWI                en1       
255.255.255.255/32 link#24            UCS                   en1      !
255.255.255.255/32 link#32            UCSI                utun4       

Internet6:
Destination                             Gateway                                 Flags               Netif Expire
default                                 fe80::%utun0                            UGcIg               utun0       
default                                 fe80::%utun1                            UGcIg               utun1       
default                                 fe80::%utun2                            UGcIg               utun2       
default                                 fe80::%utun3                            UGcIg               utun3       
default                                 fd7a:115c:a1e0::                        UGcIg               utun4       
default                                 fe80::%utun5                            UGcIg               utun5       
::1                                     ::1                                     UHL                   lo0       
fd6b:8dad:ce17:1::/64                   fe80::22be:b8ff:fe23:afd4%en1           UGc                   en1       
fd6b:aa62:c908:1::/64                   fe80::56ef:44ff:fe6d:83af%en1           UGc                   en1       
fd7a:115c:a1e0::/48                     fe80::1e1d:d3ff:fee0:fcfc%utun4         Uc                  utun4       
fd7a:115c:a1e0::53/128                  link#32                                 UCS                 utun4       
fd7a:115c:a1e0::ae01:2f4a               link#32                                 UHL                   lo0       
fd81:af5a:7514:53d7::/64                link#24                                 UC                    en1       
fd81:af5a:7514:53d7:10b1:30a1:70d2:428c e6:1e:1b:7a:1e:52                       UHL                   lo0       
fd81:af5a:7514:53d7:18c2:3796:a649:521f 2e:f8:98:1d:3:e2                        UHLWI                 en1       
fd98:a764:c0bb::/64                     fe80::1074:71d:cec1:b69%en1             UGc                   en1       
fdb2:2c26:f4e4::/64                     link#38                                 UC              bridge100       
fdb2:2c26:f4e4::                        link#38                                 UHLWI           bridge100       
fdb2:2c26:f4e4::1                       1e.1d.d3.e.33.64                        UHL                   lo0       
fdb2:2c26:f4e4:1::/64                   link#40                                 UC              bridge101       
fdb2:2c26:f4e4:1::                      link#40                                 UHLWI           bridge101       
fdb2:2c26:f4e4:1::1                     1e.1d.d3.e.33.65                        UHL                   lo0       
fdcf:d36e:f964:1::/64                   fe80::56ef:44ff:fe6d:7e77%en1           UGc                   en1       
fe80::%lo0/64                           fe80::1%lo0                             UcI                   lo0       
fe80::1%lo0                             link#1                                  UHLI                  lo0       
fe80::%en1/64                           link#24                                 UCI                   en1       
fe80::357f:5fdb:4f23%en1                9e:be:3e:cd:d9:c0                       UHLWI                 en1       
fe80::ef:aae9:1fa3:ebb7%en1             cc:60:23:22:d1:16                       UHLWI                 en1       
fe80::8a0:e205:b7f9:6083%en1            f0:2f:4b:15:16:2b                       UHLWI                 en1       
fe80::c3f:41a:f6ec:38fd%en1             9a:c7:5e:34:1:e4                        UHLWI                 en1       
fe80::c8c:c990:199:ec78%en1             4e:80:c9:19:a9:b4                       UHLWI                 en1       
fe80::1074:71d:cec1:b69%en1             48:e1:5c:98:fe:a3                       UHLWIi                en1       
fe80::1820:c451:e275:7e0d%en1           2e:f8:98:1d:3:e2                        UHLWIi                en1       
fe80::1840:dbbb:5e8:20ac%en1            e6:1e:1b:7a:1e:52                       UHLI                  lo0       
fe80::22be:b8ff:fe23:afd4%en1           20:be:b8:23:af:d4                       UHLWIi                en1       
fe80::56ef:44ff:fe6d:7e77%en1           54:ef:44:6d:7e:77                       UHLWIi                en1       
fe80::56ef:44ff:fe6d:83af%en1           54:ef:44:6d:83:af                       UHLWIi                en1       
fe80::5aa8:e8ff:fea2:d838%en1           58:a8:e8:a2:d8:38                       UHLWI                 en1       
fe80::%utun0/64                         fe80::ad06:bbc7:a516:644%utun0          UcI                 utun0       
fe80::ad06:bbc7:a516:644%utun0          link#26                                 UHLI                  lo0       
fe80::%utun1/64                         fe80::3ef7:1a5a:eb95:6630%utun1         UcI                 utun1       
fe80::3ef7:1a5a:eb95:6630%utun1         link#27                                 UHLI                  lo0       
fe80::a0f3:48ff:fea1:7c03%awdl0         a2:f3:48:a1:7c:3                        UHLI                  lo0       
fe80::a0f3:48ff:fea1:7c03%llw0          a2:f3:48:a1:7c:3                        UHLI                  lo0       
fe80::%utun2/64                         fe80::bae8:b61d:7034:e75c%utun2         UcI                 utun2       
fe80::bae8:b61d:7034:e75c%utun2         link#30                                 UHLI                  lo0       
fe80::%utun3/64                         fe80::ce81:b1c:bd2c:69e%utun3           UcI                 utun3       
fe80::ce81:b1c:bd2c:69e%utun3           link#31                                 UHLI                  lo0       
fe80::%utun4/64                         fe80::1e1d:d3ff:fee0:fcfc%utun4         UcI                 utun4       
fe80::1e1d:d3ff:fee0:fcfc%utun4         link#32                                 UHLI                  lo0       
fe80::%utun5/64                         fe80::ecd2:6379:cb:d53d%utun5           UcI                 utun5       
fe80::ecd2:6379:cb:d53d%utun5           link#36                                 UHLI                  lo0       
fe80::%bridge100/64                     link#38                                 UCI             bridge100       
fe80::1c1d:d3ff:fe0e:3364%bridge100     1e.1d.d3.e.33.64                        UHLI                  lo0       
fe80::%bridge101/64                     link#40                                 UCI             bridge101       
fe80::1c1d:d3ff:fe0e:3365%bridge101     1e.1d.d3.e.33.65                        UHLI                  lo0       
ff00::/8                                ::1                                     UmCI                  lo0       
ff00::/8                                link#10                                 UmCI                  en0       
ff00::/8                                link#24                                 UmCI                  en1       
ff00::/8                                fe80::ad06:bbc7:a516:644%utun0          UmCI                utun0       
ff00::/8                                fe80::3ef7:1a5a:eb95:6630%utun1         UmCI                utun1       
ff00::/8                                link#28                                 UmCI                awdl0       
ff00::/8                                link#29                                 UmCI                 llw0       
ff00::/8                                fe80::bae8:b61d:7034:e75c%utun2         UmCI                utun2       
ff00::/8                                fe80::ce81:b1c:bd2c:69e%utun3           UmCI                utun3       
ff00::/8                                fe80::1e1d:d3ff:fee0:fcfc%utun4         UmCI                utun4       
ff00::/8                                fe80::ecd2:6379:cb:d53d%utun5           UmCI                utun5       
ff00::/8                                link#38                                 UmCI            bridge100       
ff00::/8                                link#40                                 UmCI            bridge101       
ff01::%lo0/32                           ::1                                     UmCI                  lo0       
ff01::%en0/32                           link#10                                 UmCI                  en0       
ff01::%en1/32                           link#24                                 UmCI                  en1       
ff01::%utun0/32                         fe80::ad06:bbc7:a516:644%utun0          UmCI                utun0       
ff01::%utun1/32                         fe80::3ef7:1a5a:eb95:6630%utun1         UmCI                utun1       
ff01::%utun2/32                         fe80::bae8:b61d:7034:e75c%utun2         UmCI                utun2       
ff01::%utun3/32                         fe80::ce81:b1c:bd2c:69e%utun3           UmCI                utun3       
ff01::%utun4/32                         fe80::1e1d:d3ff:fee0:fcfc%utun4         UmCI                utun4       
ff01::%utun5/32                         fe80::ecd2:6379:cb:d53d%utun5           UmCI                utun5       
ff01::%bridge100/32                     link#38                                 UmCI            bridge100       
ff01::%bridge101/32                     link#40                                 UmCI            bridge101       
ff02::%lo0/32                           ::1                                     UmCI                  lo0       
ff02::%en0/32                           link#10                                 UmCI                  en0       
ff02::%en1/32                           link#24                                 UmCI                  en1       
ff02::%utun0/32                         fe80::ad06:bbc7:a516:644%utun0          UmCI                utun0       
ff02::%utun1/32                         fe80::3ef7:1a5a:eb95:6630%utun1         UmCI                utun1       
ff02::%utun2/32                         fe80::bae8:b61d:7034:e75c%utun2         UmCI                utun2       
ff02::%utun3/32                         fe80::ce81:b1c:bd2c:69e%utun3           UmCI                utun3       
ff02::%utun4/32                         fe80::1e1d:d3ff:fee0:fcfc%utun4         UmCI                utun4       
ff02::%utun5/32                         fe80::ecd2:6379:cb:d53d%utun5           UmCI                utun5       
ff02::%bridge100/32                     link#38                                 UmCI            bridge100       
ff02::%bridge101/32                     link#40                                 UmCI            bridge101       
```
