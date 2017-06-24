## NFS
### Installation
At a terminal prompt enter the following command to install the NFS Server:
```
sudo apt install nfs-kernel-server
```
### Configuration
You can configure the directories to be exported by adding them to the `/etc/exports` file. For example:
```
/ubuntu  *(ro,sync,no_root_squash)
/home    *(rw,sync,no_root_squash)
```
To start the NFS server, you can run the following command at a terminal prompt:
```
service nfs-kernel-server restart
```

### NFS Client Configuration
Use the *mount* command to mount a shared NFS directory from another machine, by typing a command line similar to the following at a terminal prompt:
```
sudo mount example.hostname.com:/ubuntu /local/ubuntu
```
The mount point directory `/local/ubuntu` must exist. There should be no files or subdirectories in the `/local/ubuntu` directory.

If you have trouble mounting an NFS share, make sure the *nfs-common* package is installed on your client. To install *nfs-common* enter the following command at the terminal prompt:
```
sudo apt install nfs-common
```

## NBD
The Network Block Device is a Linux-originated lightweight block access
protocol that allows one to export a block device to a client. While the
name of the protocol specifically references the concept of block
devices, there is nothing inherent in the *protocol* which requires that
exports are, in fact, block devices; the protocol only concerns itself
with a range of bytes, and several operations of particular lengths at
particular offsets within that range of bytes.

For matters of clarity, in this document we will refer to an export from
a server as a block device, even though the actual backing on the server
need not be an actual block device; it may be a block device, a regular
file, or a more complex configuration involving several files. That is
an implementation detail of the server.

### Setup
#### NBD Server
**Synopsis**
```
hermes:~# nbd-server port filename [ -r ] [ -c ] [ -C config file ]
```
**Options**
```
port   The port the server should listen to.

filename
       The filename of the file that should be exported. This can be any file, including "real" blockdevices (i.e. a file from /dev).

-r     Export the file read-only. If a client tries to write to a read-only exported file, it will receive an error, but the connection will stay up.

-c     Copy on write. When this option is provided, write-operations are not done to the exported file, but to a separate file.
       This separate file is removed when the connection is closed.

-C     Specify configuration file. The default configuration file, if this parameter is not specified, is /etc/nbd-server/config.
```
**Example**
```
hermes:~# mkdir /exports
hermes:~# dd if=/dev/zero of=/exports/nbd-export bs=1024 count=100000
hermes:~# mke2fs nbd-export
/exports/nbd-export is not a special block device.
Proceed anyway? (y,n) y
hermes:~# nbd-server 5000 /exports/nbd-export
```

#### NBD Client
**Synopsis**
```
nbd-client host [ port ] nbd-device
```
**Options**
```
nbd-device
       The block special file this nbd-client should connect to.
```
**Example**
```
hermes:~# nbd-client server.domain.com 5000 /dev/nbd0
hermes:~# mount /dev/nbd0 /mnt
hermes:~# ls /mnt
lost+found
hermes:~# df
Filesystem     1K-blocks     Used Available Use% Mounted on
[...]
/dev/nbd0          96828       13     91815   1% /mnt
hermes:~# dd if=/dev/zero of=/mnt/text count=8192 bs=1024
```