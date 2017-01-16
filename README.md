## QEMU microcheckpointing (Ubuntu 14.04.1)

### Summary
This is an implementation of Micro Checkpointing for memory and cpu state.

### The Micro-Checkpointing Process
#### Basic Algorithm 
Micro-Checkpoints (MC) work against the existing live migration path in QEMU, and can effectively be understood as a "live migration that never ends". As such, iteration rounds happen at the granularity of 10s of milliseconds and perform the following steps:
```
1. After N milliseconds, stop the VM.
3. Generate a MC by invoking the live migration software path to identify and copy dirty memory into a local staging area inside QEMU. (downtime)
4. Resume the VM immediately so that it can make forward progress.
5. Transmit the checkpoint to the destination.
6. If downtime > freq_ms, then wait_time = 0, dive right back into the next checkpoint as soon as the previous transmission completed. Otherwise, sleep for (freq_ms - downtime) and repeat.
```

### Optimizations
#### Memory Management
MCs are typically only a few MB when idle. However, they can easily be very large during heavy workloads. In the \*extreme\* worst-case, QEMU will need double the amount of main memory than that of what was originally allocated to the virtual machine.

To support this variability during transient periods, a MC consists of a linked list of slabs, each of identical size. Because MCs occur several times per second (a frequency of 10s of milliseconds), slabs allow MCs to grow and shrink without constantly re-allocating all memory in place during each checkpoint. During steady-state, the 'head' slab is permanently allocated and never goes away, so when the VM is idle, there is no memory allocation at all.

Regardless, the current strategy taken will be:
```
1. If the checkpoint size increases, then grow the number of slabs to support it.
2. If the next checkpoint size is smaller than the last one, then that's a "strike".
3. After N strikes, cut the size of the slab cache in half (to a minimum of 1 slab as described before).
```

MC serializes the actual RAM page contents in such a way that the actual pages are separated from the meta-data (all the QEMUFile stuff).

This is done strictly for the purposes of being able to use RDMA and to replace memcpy() on the local machine for hardware with very fast RAM memory speeds.

This serialization requires recording the page descriptions and then pushing them into slabs after the checkpoint has been captured (minus the page data).

Enable the following in checkpoint.c to enter debug mode
```
//#define DEBUG_MC_VERBOSE
//#define DEBUG_MC_REALLY_VERBOSE
```
Primary:
```
mc: iov # 0, len: 32768
mc: Copying to 0x7fd832bf7020 from 0x7fd94c4a6630, size 32768
mc: put: 32768 len: 0 total 32768 size: 32768 slab 0
mc: iov # 0, len: 32768
mc: Copying to 0x7fd832bff020 from 0x7fd94c4a6630, size 32768
mc: put: 32768 len: 0 total 65536 size: 65536 slab 0
mc: iov # 0, len: 32768
mc: Copying to 0x7fd832c07020 from 0x7fd94c4a6630, size 32768
mc: put: 32768 len: 0 total 98304 size: 98304 slab 0
mc: iov # 0, len: 32768
mc: Copying to 0x7fd832c0f020 from 0x7fd94c4a6630, size 32768
mc: put: 32768 len: 0 total 131072 size: 131072 slab 0
mc: iov # 0, len: 32768
mc: Copying to 0x7fd832c17020 from 0x7fd94c4a6630, size 32768
mc: put: 32768 len: 0 total 163840 size: 163840 slab 0
mc: iov # 0, len: 32768
mc: Copying to 0x7fd832c1f020 from 0x7fd94c4a6630, size 32768
mc: put: 32768 len: 0 total 196608 size: 196608 slab 0
mc: iov # 0, len: 32768
mc: Copying to 0x7fd832c27020 from 0x7fd94c4a6630, size 32768
mc: put: 32768 len: 0 total 229376 size: 229376 slab 0
mc: iov # 0, len: 4488
mc: Copying to 0x7fd832c2f020 from 0x7fd94c4a6630, size 4488
mc: put: 4488 len: 0 total 233864 size: 233864 slab 0
mc: Copyset identifiers complete. Copying memory from 1 copysets...
mc: Adding to existing slab: 2 slabs total, 10 MB
mc: Found copyset slab @ idx 1
mc: copyset 0 copies: 66 total: 66
mc: Copying to 0x7fd8326f6010 from 0x7fd835c00000, size 4096
mc: put: 4096 len: 0 total 237960 size: 4096 slab 1
mc: Success copyset 0 index 0
mc: Copying to 0x7fd8326f7010 from 0x7fd835c01000, size 4096
mc: put: 4096 len: 0 total 242056 size: 8192 slab 1
mc: Success copyset 0 index 1
mc: Copying to 0x7fd8326f8010 from 0x7fd835c04000, size 4096
mc: put: 4096 len: 0 total 246152 size: 12288 slab 1
mc: Success copyset 0 index 2
...
mc: Copying to 0x7fd832737010 from 0x7fd933f8d000, size 4096
mc: put: 4096 len: 0 total 504200 size: 270336 slab 1
mc: Success copyset 0 index 65
mc: Copy complete: 66 pages
mc: transaction: sent: START (301)
mc: Sending checkpoint size 504200 copyset start: 1 nb slab 2 used slabs 2
mc: Transaction commit
mc: Attempting write to slab #0: 0x7fd832bf7020 total size: 233864 / 5242880
mc: transaction: sent: COMMIT (302)
mc: Sent idx 0 slab size 233864 all 504200
mc: Attempting write to slab #1: 0x7fd8326f6010 total size: 270336 / 5242880
mc: Sent idx 1 slab size 270336 all 504200
mc: Waiting for commit ACK
mc: transaction: recv: ACK (304)
mc: Memory transfer complete.
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

First, compile QEMU with '--enable-mc' and ensure that the corresponding libraries for netlink (libnl3) are available.
```
HP-Compaq-Elite-8300-SFF:~$ git clone http://github.com/hinesmr/qemu.git
HP-Compaq-Elite-8300-SFF:~$ git checkout 'mc'
HP-Compaq-Elite-8300-SFF:~$ ./configure --enable-mc [other options, like --disable-werror]
```

Create a virtual machine
```
hkucs-poweredge-r430-1:~$ sudo ubuntu-vm-builder kvm precise --domain newvm --dest newvm --hostname hostnameformyvm --arch amd64 --mem 2048 --cpus 4 --user cheng --pass cheng --components main,universe --addpkg acpid --addpkg openssh-server --addpkg=linux-image-generic --libvirt qemu:///system ;
```

NFS
```
hkucs-PowerEdge-R430-1:~$ vi /etc/exports
#
/ubuntu  *(rw,sync,no_root_squash)
#
hkucs-PowerEdge-R430-1:~$ service nfs-kernel-server restart

HP-Compaq-Elite-8300-SFF:~$ sudo mount 202.45.128.160:/ubuntu /local/ubuntu
```

Next, start the VM that you want to protect using your standard procedures.
```
cheng@cheng-HP-Compaq-Elite-8300-SFF:~$ sudo qemu/x86_64-softmmu/qemu-system-x86_64 /local/ubuntu/tmpOchCrp.qcow2 -m 2048 -smp 4 --enable-kvm -netdev tap,id=net0,script=no,ifname=tap0,script=/etc/qemu-ifup,downscript=no -device e1000,netdev=net0,mac=18:66:da:03:15:b1
```

Enable MC like this:  
QEMU Monitor Command:
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
wang@wang-HP-Compaq-Elite-8300-SFF:~$ sudo qemu/x86_64-softmmu/qemu-system-x86_64 /local/ubuntu/tmpOchCrp.qcow2 -m 2048 -smp 4 --enable-kvm -netdev tap,id=net0,script=no,ifname=tap0,script=/etc/qemu-ifup,downscript=no -device e1000,netdev=net0,mac=18:66:da:03:15:b1 -incoming tcp:0:6666
```

MC can be initiated with exactly the same command as standard live migration:  
QEMU Monitor Command:
```
migrate tcp:147.8.179.243:6666
```
