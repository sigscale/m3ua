# [SigScale](http://www.sigscale.org) M3UA Protocol Stack

See the
[developers guide](https://storage.googleapis.com/m3ua.sigscale.org/debian-bookworm/lib/m3ua/doc/index.html)
for detailed information.

This application implements a distributed protocol stack
for the MTP3 user adaptation (M3UA) of the IETF Signaling
Transport (SIGTRAN) protocol suite.

## M3UA
The MTP3 user adaptation (M3UA) defines a protocol for supporting the
transport of any SS7 MTP3-User signalling (e.g. ISUP or SCCP) over IP
using the services of SCTP. This protocol is used to interconnect an SS7
Signaling Gateway (SG) with Application Servers (AS).

![interfaces](https://raw.githubusercontent.com/sigscale/m3ua/master/doc/boundaries.png)

