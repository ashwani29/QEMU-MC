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
Network setup
```
apt-get install bridge-utils
vi /etc/network/interfaces
#
auto br0
iface br0 inet dhcp
bridge_ports eth0

auto eth0
iface eth0 inet manual
#
```

Create a virtual machine
```
sudo ubuntu-vm-builder kvm precise --domain newvm --dest newvm --hostname hostnameformyvm --arch amd64 --mem 2048 --cpus 4 --user cheng --pass cheng --components main,universe --addpkg acpid --addpkg openssh-server --addpkg=linux-image-generic --libvirt qemu:///system ;
```

First, compile QEMU with '--enable-mc' and ensure that the corresponding libraries for netlink (libnl3) are available.
```
$ git clone http://github.com/hinesmr/qemu.git
$ git checkout 'mc'
$ ./configure --enable-mc [other options]
```
Next, start the VM that you want to protect using your standard procedures.
```
cheng@cheng-HP-Compaq-Elite-8300-SFF:~$ sudo qemu/x86_64-softmmu/qemu-system-x86_64 ~/newvm/tmpKcGC7l.qcow2 -m 2048 -smp 4 -net nic,macaddr=18:66:da:03:15:b1,model=e1000 -net tap,ifname=tap0,script=/etc/qemu-ifup,downscript=no
```

Enable MC like this:  
QEMU Monitor Command:
```
$ migrate_set_capability mc on # disabled by default
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
$ migrate_set_capability mc-disk-disable on # disk replication activated by default
```
Next, you can optionally disable network-buffering for additional test-only execution. This is useful if you 
want to get a breakdown only of what the cost of checkpointing the memory state is without the cost of checkpointing 
device state.  
QEMU Monitor Command:
```
$ migrate_set_capability mc-net-disable on # buffering activated by default
```
Additionally, you can tune the checkpoint frequency. By default it is set to checkpoint every 100 milliseconds. You can change that at any time, like this:  
QEMU Monitor Command:
```
$ migrate-set-mc-delay 100 # checkpoint every 100 milliseconds
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
cheng@cheng-HP-Compaq-Elite-8300-SFF:~$ sudo modprobe ifb numifbs=100 # (or some large number)
```
Now, install a Qdisc plug to the tap device using the same naming convention as the tap device created by QEMU (it must be the same, because QEMU needs to interact with the IFB device and the only mechanism we have right now of knowing the name of the IFB devices is to assume that it matches the tap device numbering scheme):
```
cheng@cheng-HP-Compaq-Elite-8300-SFF:~$ sudo ip link set up ifb0 # <= corresponds to tap device 'tap0'
cheng@cheng-HP-Compaq-Elite-8300-SFF:~$ sudo tc qdisc add dev tap0 ingress
cheng@cheng-HP-Compaq-Elite-8300-SFF:~$ sudo tc filter add dev tap0 parent ffff: proto ip pref 10 u32 match u32 0 0 action mirred egress redirect dev ifb0
```
Start the VM on the backup host
```
wang@wang-HP-Compaq-Elite-8300-SFF:~$ sudo qemu/x86_64-softmmu/qemu-system-x86_64 ~/newvm/tmpKcGC7l.qcow2 -m 2048 -smp 4 -net nic,model=e1000 -net tap,ifname=tap0,script=/etc/qemu-ifup,downscript=no -incoming tcp:0:6666
```

MC can be initiated with exactly the same command as standard live migration:  
QEMU Monitor Command:
```
$ migrate tcp:147.8.179.243:6666
```
