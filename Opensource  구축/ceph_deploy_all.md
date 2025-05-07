# Ceph Cluster 구축 (via cephadm)
---

## Install Prerequirements(All node have to install)
```shell
dnf check-update

# Install dependencies to osd nodes(Install NTP if not exist)
dnf -y install python3 systemd lvm2 podman 

### Install Cephadm
```shell
dnf search release-ceph
dnf install --assumeyes centos-release-ceph-reef
dnf install --assumeyes cephadm

cephadm add-repo --release reef
cephadm install ceph-common (rocky 9.2 에서는 설치 안됨)

# Create the data directory for ceph in the bootstrap machine
mkdir -p /etc/ceph

# Start the bootstrap process
cephadm bootstrap --mon-ip 172.236.5.74 --cluster-network 172.236.0.0/16


             URL: https://N-CEPH004:8443/
            User: admin
        Password: uqwxbygav2
```


## Configure Ceph Cluster

### Copy ssh key and add osd servers
```shell
ssh-copy-id -f -i /etc/ceph/ceph.pub 172.236.5.74
ssh-copy-id -f -i /etc/ceph/ceph.pub 172.236.5.75
# /etc/ceph/ceph.pub -> ~/.ssh/auhtorized_keys 내용 복사

ceph orch host add ceph005 172.240.1.25
ceph orch host add ceph006 172.240.1.26

# ssh-copy-id -f -i /etc/ceph/ceph.pub 172.240.1.25
#ssh-copy-id -f -i /etc/ceph/ceph.pub 172.240.1.26
➔ /etc/ceph/ceph.pub -> ~/.ssh/auhtorized_keys 내용 복사

# ceph orch host add osd1 # ceph orch host add osd2 # ceph orch host add osd3
➔ 호스트 추가

# use 'device ls' command to watch the available disks
ceph orch device ls --refresh


# Create osd apply yaml file
vi apply_osd.yml
---
service_type: osd
service_id: osd_using_paths
placement:
  hosts:
    - ceph004
    - ceph005
 spec:
  data_devices:
    paths:
    - /dev/sda
    - /dev/sdb
    - /dev/sdc
    - /dev/sdd
    - /dev/sde
    - /dev/sdf
    - /dev/sdg
    - /dev/sdh
    - /dev/sdi
    - /dev/sdj
    - /dev/sdk
    - /dev/sdl
  db_devices:
    paths:
    - /dev/nvme0n1
    - /dev/nvme1n1
placement:
  hosts:
    - ceph004
    - ceph005
 spec:
  data_devices:
    paths:
    - /dev/sda
    - /dev/sdb
    - /dev/sdc
    - /dev/sdd
    - /dev/sde
    - /dev/sdf
    - /dev/sdg
    - /dev/sdh
    - /dev/sdi
    - /dev/sdj
    - /dev/sdk
    - /dev/sdl
  db_devices:
    paths:
    - /dev/nvme0n1
    - /dev/nvme1n1

# Tell cephadm to use yaml file as OSD deploy
ceph orch apply -i apply_osd.yml --dry-run
```

### Configure rbd for Openstack
```shell
# Create pools
ceph osd pool create volumes
ceph osd pool create images
ceph osd pool create backups
ceph osd pool create vms
ceph osd pool create kube

# Init pools
rbd pool init volumes
rbd pool init images
rbd pool init backups
rbd pool init vms
rbd pool init kube

# Generate keyrings
ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images' mgr 'profile rbd pool=images'
ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms'
ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups'


ceph auth caps client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms'
ceph auth caps client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups'
ceph auth get-or-create client.gnocchi mon 'profile rbd' osd 'profile rbd pool=gnocchi' mgr 'profile rbd pool=gnocchi'


# Prepare for copying keyrings
mkdir ceph-auth
ceph auth get-or-create client.glance | tee ceph-auth/ceph.client.glance.keyring
ceph auth get-or-create client.cinder | tee ceph-auth/ceph.client.cinder.keyring
ceph auth get-or-create client.cinder-backup | tee ceph-auth/ceph.client.cinder-backup.keyring
cat /etc/ceph/ceph.conf  | tee ceph-auth/ceph.conf
```
### Configure cephfs for Openstack
```shell
## Create Cephfs FileSystem
ceph fs volume create cephfs --placement="2 ceph1 ceph2"
ceph fs ls
  name: cephfs, metadata pool: cephfs_metadata, data pools: [cephfs_data ]

# Check mds status
ceph mds stat

# Authorize client.manila
read -d '' MON_CAPS << EOF
allow r,
allow command "auth del",
allow command "auth caps",
allow command "auth get",
allow command "auth get-or-create"
EOF
  
ceph auth get-or-create client.manila -o ceph.client.manila.keyring mds 'allow *' osd 'allow rw' mon "$MON_CAPS" mgr 'allow rw'

# Add following section to the ceph.conf
[client.manila]
client mount uid = 0
client mount gid = 0
log file = /opt/stack/logs/ceph-client.manila.log
admin socket = /opt/stack/status/stack/ceph-$name.$pid.asok
keyring = /etc/ceph/ceph.client.manila.keyring
```

### Copy keyrings and ceph.conf to kolla server
```shell
scp ceph-auth/ceph.conf rocky@172.236.5.45:/etc/kolla/config/glance/
scp ceph-auth/ceph.client.glance.keyring  rocky@172.236.5.45:/etc/kolla/config/glance/

scp ceph-auth/ceph.conf rocky@172.236.5.45:/etc/kolla/config/cinder/
scp ceph-auth/ceph.client.cinder* rocky@172.236.5.45:/etc/kolla/config/cinder/cinder-volume/
scp ceph-auth/ceph.client.cinder* rocky@172.236.5.45:/etc/kolla/config/cinder/cinder-backup/

scp ceph-auth/ceph.conf rocky@172.236.5.45:/etc/kolla/config/nova/
scp ceph-auth/ceph.client.cinder.keyring  rocky@172.236.5.45:/etc/kolla/config/nova/

scp ceph-auth/ceph.conf rocky@172.236.5.45:/etc/kolla/config/manila/
scp ceph-auth/ceph.client.manila.keyring rocky@172.236.5.45:/etc/kolla/config/manila/      
```

### Configure rgw for Openstack
```shell
ceph orch apply rgw swift_rgw --placement="2 ceph1 ceph2"
```




```shell
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_keystone_api_version 3
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_keystone_url https://"$internal_url":35357
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_keystone_accepted_admin_roles "admin, ResellerAdmin"
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_keystone_accepted_roles "_member_, member, admin, ResellerAdmin"
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_keystone_implicit_tenants true # Implicitly create new users in their own tenant with the same name when authenticating via Keystone. Can be limited to s3 or swift only.
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_keystone_admin_user "$rgw_keystone_admin_user"
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_keystone_admin_password "$ceph_rgw_pass" # Got from the passwords.yml
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_keystone_admin_project service
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_keystone_admin_domain default
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_keystone_verify_ssl false
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_content_length_compat true
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_enable_apis "s3, swift, swift_auth, admin"
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_s3_auth_use_keystone true
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_enforce_swift_acls true
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_swift_account_in_url true
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_swift_versioning_enabled true
sudo ceph config set "rgw.ceph_rgw.rocky-mon.dddmlj" rgw_verify_ssl true 
```


```shell
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_keystone_api_version 3
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_keystone_url http://172.240.5.44:5000
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_keystone_accepted_admin_roles "admin, ResellerAdmin"
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_keystone_accepted_roles "_member_, member, admin, ResellerAdmin"
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_keystone_implicit_tenants true
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_keystone_admin_user ceph_rgw
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_keystone_admin_password Lqx2DKxkpYeMDWBwK3Ho9MDaRyr2n2YBCl71JsUS 
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_keystone_admin_project service
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_keystone_admin_domain default
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_keystone_verify_ssl false
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_content_length_compat true
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_enable_apis "s3, swift, swift_auth, admin"
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_s3_auth_use_keystone true
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_enforce_swift_acls true
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_swift_account_in_url true
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_swift_versioning_enabled true
sudo ceph config set client.rgw.swift_rgw.ceph006.neeire rgw_verify_ssl true
```


[client.rgw.swift_rgw.ceph005.ivccth]
rgw frontends = civetweb port=172.240.1.24:8080
rgw_keystone_url = http://172.240.5.44:5000
rgw_keystone_accepted_admin_roles "admin, ResellerAdmin"
rgw_keystone_accepted_roles "_member_, member, admin, ResellerAdmin"
rgw_keystone_implicit_tenants true
rgw_keystone_admin_user ceph_rgw
rgw_keystone_admin_password Lqx2DKxkpYeMDWBwK3Ho9MDaRyr2n2YBCl71JsUS
rgw_keystone_admin_project service
rgw_keystone_admin_domain default
rgw_keystone_verify_ssl false
rgw_content_length_compat true
rgw_enable_apis "s3, swift, swift_auth, admin"
rgw_s3_auth_use_keystone true
rgw_enforce_swift_acls true
rgw_swift_account_in_url true
rgw_swift_versioning_enabled true
rgw_verify_ssl true

client.rgw.swift_rgw.ceph005.ivccth
client.rgw.swift_rgw.ceph006.neeire

client.rgw.ceph001.rgw0
[client.rgw.swift_rgw.ceph005.ivccth]
host = ceph005


keyring = /var/lib/ceph/radosgw/ceph-rgw.ceph001.rgw0/keyring
log file = /var/log/ceph/ceph-rgw-ceph001.rgw0.log
rgw frontends = beast endpoint=0.0.0.0:8080
#rgw frontends = beast endpoint=172.236.1.21:8080
rgw thread pool size = 512
rgw keystone admin password = d754d9fd34942bb375e7db7ffcc38abe27b81b86ccedfb6b0b23
rgw_swift_account_in_url = true
rgw_swift_versioning_enabled = true
rgw_enable_apis = swift, s3
rgw_keystone_accepted_roles = member, _member_, admin, swiftoperator
rgw_keystone_admin_tenant = service
rgw_keystone_api_version = 3
rgw_keystone_admin_user = radosgw
rgw_keystone_admin_domain = default
rgw_keystone_implicit_tenants = true
rgw_keystone_verify_ssl = false
rgw_s3_auth_use_keystone = true
rgw keystone url = http://172.236.1.9:5000
rgw_keystone_token_cache_size = 100
#rgw_keystone_admin_tenant = admin
#rgw_keystone_admin_user = admin