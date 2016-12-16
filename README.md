## QEMU microcheckpointing

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
Enable MC like this:  
QEMU Monitor Command:
```
$ migrate_set_capability mc on # disabled by default
```
Currently, only one network interface is supported, \*and* currently you must ensure that the root 
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
