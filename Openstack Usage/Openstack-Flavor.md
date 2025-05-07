### Create Flavor sample
```shell
openstack flavor create --id 1 --vcpus 2 --ram 2048 --disk 50 m1.small
openstack flavor create --id 2 --vcpus 4 --ram 8192 --disk 50 --ephemeral 10 m1.large
```

