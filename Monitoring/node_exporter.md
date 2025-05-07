
```
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xzvf node_exporter-1.7.0.linux-amd64.tar.gz
mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/bin/node_exporter

vi /etc/systemd/system/node_exporter.service
---
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/bin/node_exporter

[Install]
WantedBy=multi-user.target
---


systemctl daemon daemon-reload
systemctl enable node_exporter
systemctl restart node_exporter
systemctl status node_exporter
```


avg(node_load1{instance=~"$host:$node_port",job=~""}) by (instance) / count(node_cpu_scaling_frequency_hertz{instance=~"$host:$node_port",job=~"$node_job"}) by (instance) * 100


avg(100 - ((lustre_available_kilobytes{component="ost"} / lustre_capacity_kilobytes{component="ost"}) * 100)) avg(100 - ((lustre_ava)))