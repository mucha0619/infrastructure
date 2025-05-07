### Provider Network 생성
```sehll

vi /etc/kolla/neutron-server/m12_conf.ini
---
[m12_type_flat]
flat_networks = physnet1

vi /etc/kolla/neutron-server/linuxbridge_agent.ini
---
[linux_bridge]
physical_interface_mappings = physnet1:[INTERFACE_NAME]


openstack network create  --share --external --provider-physical-network physnet1 --provider-network-type flat kisti-public-net

openstack subnet create --network kisti-public-net  --allocation-pool start=150.183.252.201,end=150.183.251.240   --dns-nameserver 8.8.8.8 --gateway 150.183.251.1   --subnet-range 150.183.251.0/23 physnet1
```

enx00e04c3604e0 l