## QEMU microcheckpointing (Ubuntu 14.04.1)

### Summary
This is an implementation of Micro Checkpointing for memory and cpu state.

### The Micro-Checkpointing Process
Micro-Checkpoints (MC) work against the existing live migration path in QEMU, and can effectively 
be understood as a "live migration that never ends". As such, iteration rounds happen at the 
granularity of 10s of milliseconds and perform the following steps:
```
1. After N milliseconds, stop the VM.
3. Generate a MC by invoking the live migration software path to identify and copy dirty memory into a local staging area inside QEMU.
4. Resume the VM immediately so that it can make forward progress.
5. Transmit the checkpoint to the destination.
6. Repeat
```
### Usage
#### BEFORE Running
Network File System (NFS)
```
cheng@hkucs-PowerEdge-R430-1:~$ vi /etc/exports
#
/ubuntu  *(rw,sync,no_root_squash)
#
cheng@hkucs-PowerEdge-R430-1:~$ service nfs-kernel-server restart
cheng@hkucs-poweredge-r430-2/3:~$ sudo mount 10.22.1.1:/ubuntu /local/ubuntu
```

First, compile QEMU with '--enable-mc' and ensure that the corresponding libraries for netlink (libnl3) are available.
```
cheng@hkucs-poweredge-r430-1/2/3:~$ git clone http://github.com/hinesmr/qemu.git
cheng@hkucs-poweredge-r430-1/2/3:~$ git checkout 'mc'
cheng@hkucs-poweredge-r430-1/2/3:~$ ./configure --enable-mc [other options, like --disable-werror]
```

Create a virtual machine
```
cheng@hkucs-poweredge-r430-1:~$ sudo ubuntu-vm-builder kvm precise --domain newvm --dest newvm --hostname hostnameformyvm --arch amd64 --mem 2048 --cpus 4 --user cheng --pass cheng --bridge br0 --ip 10.22.1.11 --mask 255.255.255.0 --net 10.22.1.0 --bcast 10.22.1.255 --components main,universe --addpkg acpid --addpkg openssh-server --addpkg=linux-image-generic --libvirt qemu:///system ;
```
```
cheng@hkucs-PowerEdge-R430-1:~$ sudo qemu/x86_64-softmmu/qemu-system-x86_64 newvm/tmpa_9xeS.qcow2 -m 2048 -smp 4 -vnc :7 -net nic,model=e1000 -net tap,ifname=tap0,script=/etc/qemu-ifup,downscript=no
cheng@hkucs-PowerEdge-R430-1:~$ ssh 10.22.1.11
cheng@hostnameformyvm:$ cat /etc/apt/apt.conf
Acquire::http::proxy "http://10.22.1.1:3128";
Acquire::https::proxy "http://10.22.1.1:3128";
Acquire::ftp::proxy "http://10.22.1.1:3128";
```

Next, start the VM that you want to protect using your standard procedures.
```
cheng@hkucs-PowerEdge-R430-2:~$ sudo qemu/x86_64-softmmu/qemu-system-x86_64 /local/ubuntu/tmpa_9xeS.qcow2 -m 2048 -smp 4 -vnc :7 -net nic,model=e1000 -net tap,ifname=tap0,script=/etc/qemu-ifup,downscript=no
```

Enable MC like this:  
QEMU Monitor Command (TigerVNC 202.45.128.161:7):
```
migrate_set_capability mc on # disabled by default
```
Currently, only one network interface is supported, \*and\* currently you must ensure that the root 
disk of your VM is booted either directly from iSCSI or NFS, as described previously. This will be 
rectified with future improvements.  
For testing only, you can ignore the aforementioned requirements if you simply want to get an understanding 
of the performance penalties associated with this feature activated.  
Current required until testing is complete. There are some COLO disk replication patches that I am testing, 
but they don't work yet, so you have to explicitly set this:  
QEMU Monitor Command:
```
migrate_set_capability mc-disk-disable on # disk replication activated by default
```
Next, you can optionally disable network-buffering for additional test-only execution. This is useful if you 
want to get a breakdown only of what the cost of checkpointing the memory state is without the cost of checkpointing 
device state.  
QEMU Monitor Command:
```
migrate_set_capability mc-net-disable on # buffering activated by default
```
Additionally, you can tune the checkpoint frequency. By default it is set to checkpoint every 100 milliseconds. You can change that at any time, like this:  
QEMU Monitor Command:
```
migrate-set-mc-delay 100 # checkpoint every 100 milliseconds
```
#### libnl / NETLINK compatibility
Unfortunately, You cannot just install any version of libnl, as we depend on a recently introduced feature from 
Xen Remus into libnl called "Qdisc Plugs" which perform the network buffering functions of micro-checkpointing 
in the host linux kernel.  
As of today, the minimum version you would need from my Ubuntu system would be the following packages
```
libnl-3-200_3.2.16-0ubuntu1_amd64.deb
libnl-3-dev_3.2.16-0ubuntu1_amd64.deb
libnl-cli-3-200_3.2.16-0ubuntu1_amd64.deb
libnl-cli-3-dev_3.2.16-0ubuntu1_amd64.deb
libnl-genl-3-200_3.2.16-0ubuntu1_amd64.deb
libnl-genl-3-dev_3.2.16-0ubuntu1_amd64.deb
libnl-nf-3-200_3.2.16-0ubuntu1_amd64.deb
libnl-nf-3-dev_3.2.16-0ubuntu1_amd64.deb
libnl-route-3-200_3.2.16-0ubuntu1_amd64.deb
libnl-route-3-dev_3.2.16-0ubuntu1_amd64.deb
libnl-utils_3.2.16-0ubuntu1_amd64.deb
```
#### Running
First, make sure the IFB device kernel module is loaded
```
cheng@hkucs-PowerEdge-R430-2:~$ sudo modprobe ifb numifbs=100 # (or some large number)
```
Now, install a Qdisc plug to the tap device using the same naming convention as the tap device created by QEMU (it must be the same, because QEMU needs to interact with the IFB device and the only mechanism we have right now of knowing the name of the IFB devices is to assume that it matches the tap device numbering scheme):
```
cheng@hkucs-PowerEdge-R430-2:~$ sudo ip link set up ifb0 # <= corresponds to tap device 'tap0'
cheng@hkucs-PowerEdge-R430-2:~$ sudo tc qdisc add dev tap0 ingress
cheng@hkucs-PowerEdge-R430-2:~$ sudo tc filter add dev tap0 parent ffff: proto ip pref 10 u32 match u32 0 0 action mirred egress redirect dev ifb0
```
Start the VM on the backup host
```
cheng@hkucs-PowerEdge-R430-3:~$ sudo qemu/x86_64-softmmu/qemu-system-x86_64 /local/ubuntu/tmpa_9xeS.qcow2 -m 2048 -smp 4 -vnc :7 -net nic,model=e1000 -net tap,ifname=tap0,script=/etc/qemu-ifup,downscript=no -incoming tcp:0:6666
```

MC can be initiated with exactly the same command as standard live migration:  
QEMU Monitor Command:
```
migrate tcp:10.22.1.3:6666
```
