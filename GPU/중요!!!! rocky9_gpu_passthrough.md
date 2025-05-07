# add kernel parameter
# for AMD CPU, specify [amd_iommu=on]



부팅!!!!

다른건 동일한듯?


```
gpu node의 /etc/kolla/nova-compute/nova.conf
---
[DEFAULT]
...
pci_alias = { "vendor_id":"10de", "product_id":"20b5", "device_type":"type-PF", "name":"A100-80G" }
pci_passthrough_whitelist = { "name":"A100-80G", "vendor_id":"10de", "product_id":"20b5" }
...

추가
```

```
controller node의 /etc/kolla/nova-api/nova.conf, /etc/kolla/nova-scheduler/nova.conf
---
[DEFAULT]
...
pci_alias = { "vendor_id":"10de", "product_id":"20f1", "device_type":"type-PF", "name":"A100" }
pci_passthrough_whitelist = { "name": "20f1", "vendor_id": "10de", "product_id": "20f1" }
pci_alias = { "vendor_id":"10de", "product_id":"1023", "device_type":"type-PCI", "name":"K40" }
pci_passthrough_whitelist = { "name": "K40", "vendor_id": "10de", "product_id": "1023" }
pci_alias = { "vendor_id":"10de", "product_id":"1df6", "device_type":"type-PCI", "name":"V100S" }
pci_passthrough_whitelist = { "name": "V100S", "vendor_id": "10de", "product_id": "1df6" }
pci_alias = { "vendor_id":"10de", "product_id":"1db6", "device_type":"type-PCI", "name":"V100" }
pci_passthrough_whitelist = { "name": "V100", "vendor_id": "10de", "product_id": "1db6" }
pci_alias = { "vendor_id":"10de", "product_id":"20b5", "device_type":"type-PF", "name":"A100-80G" }
pci_passthrough_whitelist = { "name":"A100-80G", "vendor_id":"10de", "product_id":"20b5" }

[filter_scheduler]
max_io_ops_per_host = 10
ram_weight_multiplier = 5.0
enabled_filters = AvailabilityZoneFilter, ComputeFilter, AggregateNumInstancesFilter, AggregateIoOpsFilter, ComputeCapabilitiesFilter, ImagePropertiesFilter, ServerGroupAntiAffinityFilter, ServerGroupAffinityFilter, NUMATopologyFilter, PciPassthroughFilter, AggregateMultiTenancyIsolation
host_subset_size = 10
tracks_instance_changes = True
...

추가
```

## lspci | grep -i nv
## lspci -nn | grep -i nvidia
등 명령어로 gpu 정보 확인






# K40
echo "blacklist nouveau" | tee /etc/modprobe.d/blacklist.conf > /dev/null
echo "options vfio-pci ids=10de:1023" | tee /etc/modprobe.d/vfio.conf > /dev/null
echo "vfio-pci" | tee /etc/modules-load.d/vfio-pci.conf > /dev/null

pci_alias = { "vendor_id":"10de", "product_id":"1023", "device_type":"type-PCI", "name":"K40" }
pci_passthrough_whitelist = { "name": "K40", "vendor_id": "10de", "product_id": "1023" }

sudo lspci -nnk -d 10de:1023

# A100-40G
echo "blacklist nouveau" | tee /etc/modprobe.d/blacklist.conf > /dev/null
echo "options vfio-pci ids=10de:20f1" | tee /etc/modprobe.d/vfio.conf > /dev/null
echo "vfio-pci" | tee /etc/modules-load.d/vfio-pci.conf > /dev/null

pci_alias = { "vendor_id":"10de", "product_id":"20f1", "device_type":"type-PF", "name":"A100" }
pci_passthrough_whitelist = { "name": "20f1", "vendor_id": "10de", "product_id": "20f1" }

# A100-80G
echo "blacklist nouveau" | tee /etc/modprobe.d/blacklist.conf > /dev/null
echo "options vfio-pci ids=10de:20b5" | tee /etc/modprobe.d/vfio.conf > /dev/null
echo "vfio-pci" | tee /etc/modules-load.d/vfio-pci.conf > /dev/null

pci_alias = { "vendor_id":"10de", "product_id":"20b5", "device_type":"type-PF", "name":"A100" }
pci_passthrough_whitelist = { "name": "20b5", "vendor_id": "10de", "product_id": "20b5" }


```
커널 설정 적용 (blacklist는 확인중)
grubby --update-kernel ALL --args intel_iommu=on
grubby --update-kernel ALL --args iommu=pt
grubby --update-kernel ALL --args rd.driver.blacklist=nouveau
reboot
```
검증 커맨드
``` 
sudo lspci -nnk -d 10de:20f1
dmesg | grep -i vfio
```


pci_alias = { "vendor_id":"10de", "product_id":"1df6", "device_type":"type-PF", "name":"V100S" }
pci_passthrough_whitelist = { "name": "V100S", "vendor_id": "10de", "product_id": "1df6" }




sudo docker stop ceilometer_compute
sudo docker rm ceilometer_compute
sudo rm -rf /etc/kolla/ceilometer-compute