# NFS
## Installation
At a terminal prompt enter the following command to install the NFS Server:
```
sudo apt install nfs-kernel-server
```
## Configuration
You can configure the directories to be exported by adding them to the `/etc/exports` file. For example:
```
/ubuntu  *(ro,sync,no_root_squash)
/home    *(rw,sync,no_root_squash)
```
To start the NFS server, you can run the following command at a terminal prompt:
```
service nfs-kernel-server restart
```

## NFS Client Configuration
Use the *mount* command to mount a shared NFS directory from another machine, by typing a command line similar to the following at a terminal prompt:
```
sudo mount example.hostname.com:/ubuntu /local/ubuntu
```
The mount point directory `/local/ubuntu` must exist. There should be no files or subdirectories in the `/local/ubuntu` directory.

If you have trouble mounting an NFS share, make sure the *nfs-common* package is installed on your client. To install *nfs-common* enter the following command at the terminal prompt:
```
sudo apt install nfs-common
```
