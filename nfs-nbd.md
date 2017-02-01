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
### NBD Server
```
sudo apt-get install nbd-server
```

#### SYNOPSIS
```
nbd-server port filename [ -r ] [ -c ] [ -C config file ]
```

#### OPTIONS
```
port   The port the server should listen to.

filename
       The filename of the file that should be exported. This can be any file, including "real" blockdevices (i.e. a file from /dev).

-r     Export the file read-only. If a client tries to write to a read-only exported file, it will receive an error, but the connection will stay up.

-c     Copy on write. When this option is provided, write-operations are not done to the exported file, but to a separate file.
       This separate file is removed when the connection is closed.

-C     Specify configuration file. The default configuration file, if this parameter is not specified, is /etc/nbd-server/config.
```
#### EXAMPLES
```
mkdir /exports
dd if=/dev/zero of=/exports/nbd-export bs=1024 count=100000

mke2fs nbd-export
/exports/nbd-export is not a special block device.
Proceed anyway? (y,n) y

nbd-server 5000 /exports/nbd-export
```

### NBD Client
```
sudo apt-get install nbd-client
```

#### SYNOPSIS
```
nbd-client host [ port ] nbd-device
```

#### OPTIONS
```
nbd-device
       The block special file this nbd-client should connect to.
```

#### EXAMPLES
To connect to a server running on port 5000 at host "server.domain.com", using the client's block special file "/dev/nbd0":
```
nbd-client server.domain.com 5000 /dev/nbd0
```
Then
```
mount /dev/nbd0 /mnt

ls /mnt
lost+found
```