## Network Configuration
---

### IP Address and Hostnames
`/ect/hosts`
```
172.21.0.6 vcenter
172.21.8.75 node01
172.21.8.76 node02
```

### Firewall configuration
```
[All]#firewall-cmd --permanent --add-service=high-availability
[All]#firewall-cmd --reload
```

### Configure Passwordless SSH authentication between Cluster nodes

Install rsync package, generate SSH keypair and distribute it across cluster nodes
```
[All]# yum -y install rsync
[node01]# ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa
[node01]# mv ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
```

Sync with ourselves to get an ECDSA key fingerprint stored into known_hosts, then sync with other cluster nodes
```
[node01]# rsync -av /root/.ssh/* node01:/root/.ssh/
[node01]# rsync -av /root/.ssh/* node02:/root/.ssh/
```

### Install Pacemaker and Corosync

If using VMware platform, install VMware tools
```
[All]# yum -y install open-vm-tools
```

The pcs will install pacemaker, corosync and resource-agents as dependencies
```
[All]# yum -y isntall pcs
```

Set up a password for the pcs administration account named hacluster
```
[All]# passwd hacluster
```

Start and enable the service
```
[All]# systemctl start pcsd
[All]# systemctl enable pcsd
```

### Configure Corosync

Authenticate as the ha cluster user. Note that authorisation tokens are stored in the file `/var/lib/pcsd/tokens`

```
[node01]# pcs cluster auth node01 node02 -u hacluster -p passwd
node01: Authorized
node02: Authorized
```

Generate and synchronise the Corosync configuration
```
[node01]# pcs cluster setup --name gfs_cluster node01 node02
```

Start and enable the Cluster on all nodes
```
[node01]# pcs cluster start --all
[All]# pcs cluster enable --all
```

### Configure STONITH (Node Fencing)

Install a fencing agent suitable for VMware environment
```
[All]# yum -y install fence-agents-vmware-soap
```

Populate the file with the current raw XML config from the CIB
```
[node01]# pcs cluster cib stonith_cfg
```

Create a new STONITH resource named my_vcenter-fence
```
[node01]# pcs -f stonith_cfg stonith create my_vcenter-fence fence_vmware_soap \
ipaddr=vcenter ipport=443 ssl_insecure=1 login="administrator" passwd="passwd" pcmk_reboot_action=1 pcmk_host_map="vcenter:node01;vcenter:node02" pcmk_host_check=static-list pcmk_host_list="node01,node02" power_wait=3 op monitor interval=90s
```

Enable STONITH, set its action and timeout, and commit the changes
```
[node01]# pcs -f stonith_cfg property set stonith-enabled=true
[node01]# pcs -f stonith_cfg property set stonith-action=reboot
[node01]# pcs -f stonith_cfg property set stoniht-timeout=120s
[node01]# pcs cluster cib-push stonith_cfg
[node01]# pcs property list --all | grep stonith
```

### Configure Pacemaker for GFS2

We want to prevent healthy ressources from being moved around  the cluster. We can specify a different stickiness for every resource, but it is often sufficient to change the default.
```
[node01]# pcs resource defaults resource-stickiness=200
[node01]# pcs resource defaults
resource-stickiness: 200
```

Install the GFS2 commnad-line utilities and the Distributed Lock Manager(DLM) required by cluster filesystems then enable clustered locking for LVM
```
[All]# yum -y install gfs2-utils lvm2-cluster
[All]# lvmconf --enable-cluster
```

**note**
```
This sets locking_type to 3 on the system and disables lvmetad use as it is not yet supported in clustered environment. Another way of doing this would be to open the /etc/lvm/lvm.conf file
```

The DLM needs to run on all nodes, so we'll start by creating a resource for it(using the ocf:pacemaker:controld resource script), and clone it. Note that a dlm resource is a required dependency for clvmd and GFS2 then Set up clvmd as a cluster resource
```
[node01]# pcs cluster cib dlm_cfg
[node01]# pcs -f dlm_cfg resource create dlm ocf:pacemaker:controld op monitor interval=120s on-fail=fence clone interleave=true ordered=true
[node01]# pcs -f dlm_cfg resource create dlvmd ocf:heartbeat:clvm op monitor interval=120s on-fail=fence clone interleave=true ordered=true
```

Setup clvmd and dlm dependency and start up order. Create the ordering and the colocation so that clvm starts after dlm and that both resources start on the same node
```
[node01]# pcs -f dlm_cfg constraint order start dlm-clone then clvmd-clone
[node01]# pcs -f dlm_cfg constraint colocation add clvmd-clone with dlm-clone
```

Set the no-quorum-policy of the cluster to freeze so that when quorum is lost, the remaining partition will do nothing until quorum is regained - GFS2 requires quorum to operate
and commit changes
```
[node01]# pcs -f dlm_cfg property set no-quorum-policy=freeze
[node01]# pcs cluster cib-push dlm_cfg
```

### LVM Configuration

Create LVM objects from a single cluster node
```
[node01]# fdisk /dev/sdb
[node01]# pvcreate /dev/sdb1
[node01]# vgcreate --autobakcup=y --clustered=y vg_cluster /dev/sdb1
[node01]# lvcreate -l 100%FREE -n lv_cluster vg_cluster
[node01]# mkfs.gfs2 -j3 -J32 -t gfs_cluster:gfs2_storage -p lock_dlm /dev/vg_cluster/lv_cluster
```

Create a mountpoint
```
[All]# mkdir -p /cluster/storage
```

### Create Pacemaker Filesystem Resource

It is generally recommended to mount GFS2 file systems with the noatime and nodiratime arguments. This allows GFS2 to spend less time updating disk inodes for every access.
```
[node01]# pcs resource create gfs_res01 Filesystem device="/dev/vg_cluster/lv_cluster" directory="/cluster/storage" fstype="gfs2" options="noatime,nodiratime,rw" op monitor interval=90s on-fail=fence clone interleave=true
```

We deed to define a _netdev option when we use LVM on a GFS filesystem over a partition provided via the iSCSI protocol. To do so, we will simplyupdate the filesystem resource
```
[node01]# pcs resource update gfs2_res01 options="noatime,nodiratime,rw,_netdev"
```
