# Iperf

## TCP Measurements
Measures TCP Achievable Bandwidth

## Example Iperf TCP Invocation
Server (receiver):
```
$ iperf -s
------------------------------------------------------------
Server listening on TCP port 5001
TCP window size: 85.3 KByte (default)
------------------------------------------------------------
[  4] local 147.8.177.50 port 5001 connected with 147.8.179.243 port 42440
[ ID] Interval       Transfer     Bandwidth
[  4]  0.0-10.1 sec   113 MBytes  93.9 Mbits/sec
```

Client (sender):
```
$ iperf -c 147.8.177.50
------------------------------------------------------------
Client connecting to 147.8.177.50, TCP port 5001
TCP window size: 85.0 KByte (default)
------------------------------------------------------------
[  3] local 147.8.179.243 port 42440 connected with 147.8.177.50 port 5001
[ ID] Interval       Transfer     Bandwidth
[  3]  0.0-10.0 sec   113 MBytes  94.8 Mbits/sec
```