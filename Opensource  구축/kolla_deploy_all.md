* Version Info
Kolla-ansible : antelope(2023.1)

### 1. Install dependencies and activate virtual environment

```shell
 sudo dnf -y update
 sudo dnf install python3-devel libffi-devel gcc openssl-devel python3-libselinux -y

 sudo dnf install -y python3
 sudo dnf groupinstall development -y
 python3 -m venv kolla
 source kolla/bin/activate

 pip install -U pip
 pip install 'ansible>=6,<8' # depand on kolla-ansible version
```

### 2. Install kolla-ansible

```shell
 pip install git+https://opendev.org/openstack/kolla-ansible@stable/2023.1
# (pip install kolla-ansible)

 sudo mkdir -p /etc/kolla
 sudo chown $USER:$USER /etc/kolla

 cp -r kolla/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
 cp kolla/share/kolla-ansible/ansible/inventory/multinode .

## Install Ansible Galaxy requirements
 kolla-ansible install-deps
```

### 3. Configure Ansible

```shell
sudo mkdir /etc/ansible
sudo vi /etc/ansible/ansible.cfg
---
[defaults]
host_key_checking=False
piplining=True
forks=100
```

### 4-1. Prepare initial configuration(lvm, nfs version)

```shell
(kolla) [rocky@ki-cont01 ansible]$  grep -Ev '^#|^$' /etc/kolla/globals.yml
---
workaround_ansible_issue_8743: yes
kolla_base_distro: "rocky"
openstack_release: "2023.1"
kolla_internal_vip_address: "172.236.5.10"
kolla_external_vip_address: "150.183.252.10"
network_interface: "{{ br_mgmt }}"
kolla_external_vip_interface: "eth4"
api_interface: "{{ br_mgmt }}"
swift_storage_interface: "{{ network_interface }}"
tunnel_interface: "{{ br_vxlan }}"
storage_interface: "{{ br_storage }}"
dns_interface: "{{ br_mgmt }}"
octavia_network_interface: "{{ br_mgmt }}"
neutron_external_interface: "{{ br_ex }}"
neutron_plugin_agent: "ovn"
enable_haproxy: "yes"
enable_rabbitmq: "yes"
enable_ceilometer: "yes"
enable_cinder: "yes"
enable_cinder_backup: "yes"
enable_gnocchi: "yes"
enable_gnocchi_statsd: "yes"
enable_heat: "{{ enable_openstack_core | bool }}"
enable_horizon: "{{ enable_openstack_core | bool }}"
enable_horizon_heat: "{{ enable_heat | bool }}"
enable_horizon_magnum: "{{ enable_magnum | bool }}"
enable_horizon_manila: "{{ enable_manila | bool }}"
enable_magnum: "yes"
enable_manila: "yes"
enable_manila_backend_cephfs_native: "yes"
enable_manila_backend_cephfs_nfs: "yes"
enable_neutron_dvr: "yes"
enable_neutron_provider_networks: "yes"
enable_octavia: "yes"
enable_octavia_driver_agent: "{{ enable_octavia | bool and neutron_plugin_agent == 'ovn' }}"
enable_opensearch: "no"
enable_prometheus: "yes"
enable_skyline: "yes"
external_ceph_cephx_enabled: "yes"
ceph_glance_keyring: "ceph.client.glance.keyring"
ceph_glance_user: "glance"
ceph_glance_pool_name: "images"
ceph_cinder_keyring: "ceph.client.cinder.keyring"
ceph_cinder_user: "cinder"
ceph_cinder_pool_name: "volumes"
ceph_cinder_backup_keyring: "ceph.client.cinder-backup.keyring"
ceph_cinder_backup_user: "cinder-backup"
ceph_cinder_backup_pool_name: "backups"
ceph_nova_keyring: "{{ ceph_cinder_keyring }}"
ceph_nova_user: "{{ ceph_cinder_user }}"
ceph_nova_pool_name: "vms"
ceph_gnocchi_keyring: "ceph.client.gnocchi.keyring"
ceph_gnocchi_user: "gnocchi"
ceph_gnocchi_pool_name: "gnocchi"
ceph_manila_keyring: "ceph.client.manila.keyring"
ceph_manila_user: "manila"
glance_backend_ceph: "yes"
gnocchi_backend_storage: "ceph"
cinder_backend_ceph: "yes"
cinder_backup_driver: "ceph"
nova_backend_ceph: "yes"
neutron_ovn_distributed_fip: "yes"
neutron_ovn_dhcp_agent: "yes"
enable_prometheus_openstack_exporter_external: "yes"
prometheus_openstack_exporter_compute_api_version: 2.87


```

### generate password (/etc/kolla/passwords.yml)
```shell
 kolla-genpwd
```
### Create directory for ceph.conf and keyrings
```shell
mkdir -p /etc/kolla/config/cinder/cinder-volume
mkdir -p /etc/kolla/config/cinder/cinder-backup
mkdir -p /etc/kolla/config/glance
mkdir -p /etc/kolla/config/nova
mkdir -p /etc/kolla/config/manila
```


### 5. Perform Deployment
```shell
 kolla-ansible -i multinode bootstrap-servers

 kolla-ansible -i all-in-one prechecks

 kolla-ansible -i all-in-one deploy

 pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/2023.1

 kolla-ansible post-deploy  /etc/kolla/admin-openrc.sh

### The file will be generated in /etc/kolla/clouds.yaml, you can use it by copying it to /etc/openstack or ~/.config/openstack, or by setting the OS_CLIENT_CONFIG_FILE environment variable.

cp /etc/kolla/clouds.yaml /etc/openstack/

source /etc/kolla/admin-openrc.sh

### init-runonce script (make demo perpose)
# kolla/share/kolla-ansible/init-runonce

## Horzion account
ID : admin
password : cat /etc/kolla/passwords.yml | grep keystone_admin_password

```


