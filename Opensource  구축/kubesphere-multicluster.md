```shell
curl -sfL https://get-kk.kubesphere.io | VERSION=v3.0.12 sh -

./kk create config -f cascade-cluster.yaml --with-kubernetes v1.23.10 --with-kubesphere v3.3.0

# Install dependency
dnf -y install socat conntrack ebtables ipset ipvsadm

vi cascade-cluster.yaml
---
apiVersion: kubekey.kubesphere.io/v1alpha2
kind: Cluster
metadata:
  name: sample
spec:
  hosts:
  - {name: master, address: 192.168.2.101, internalAddress: 192.168.2.101, user: centos, password: "centos"}
  - {name: node1, address: 150.183.250.236, internalAddress: 150.183.250.236, user: centos, password: "centos"}
  - {name: node2, address: 150.183.250.235, internalAddress: 150.183.250.235, user: centos, password: "centos"}
  - {name: node3, address: 150.183.250.234, internalAddress: 150.183.250.234, user: centos, password: "centos"}
  - {name: node4, address: 150.183.250.233, internalAddress: 150.183.250.233, user: centos, password: "centos"}
  roleGroups:
    etcd:
    - master
    control-plane:
    - master
    worker:
    - node1
    - node2
    - node3
    - node4
  controlPlaneEndpoint:
    ## Internal loadbalancer for apiservers
    # internalLoadbalancer: haproxy

    domain: 192.168.2.101
    address: ""
    port: 6443
  kubernetes:
    version: v1.23.10
    clusterName: cluster.cascade.local
    autoRenewCerts: true
    containerManager: docker
  etcd:
    type: kubekey
  network:
    plugin: calico
    kubePodsCIDR: 10.233.64.0/18
    kubeServiceCIDR: 10.233.0.0/18
    ## multus support. https://github.com/k8snetworkplumbingwg/multus-cni
    multusCNI:
      enabled: false
  registry:
    privateRegistry: ""
    namespaceOverride: ""
    registryMirrors: []
    insecureRegistries: []
  addons: []

  ---
  ...
  spec:
    ...
    authentication:
      jwtSecret: "s05ZZFuvwnfx5OYS3qQehOxV7dOpZsuU"
  ...
  multicluster:
    clusterRole: member
...


./kk create cluster -f cascade-cluster.yaml

```

```shell
# Cave Cluster는 각 노드들이 사설 네트워크에 구성되어있음.
# pfsense의 WAN IP를 통해 외부와 통신
# Host cluster와의 통신을 위하여, pfsense WAN IP와 monitor IP 간의 NAT 설정해놓고, kube-apiserver의 cert IP를 추가해줌.

curl -sfL https://get-kk.kubesphere.io | VERSION=v3.0.12 sh -

./kk create config -f cave-cluster.yaml --with-kubernetes v1.23.10 --with-kubesphere v3.3.0

# Install dependency
socat conntrack ebtables ipset ipvsadm

vi cascade-cluster.yaml
---
apiVersion: kubekey.kubesphere.io/v1alpha2
kind: Cluster
metadata:
  name: sample
spec:
  hosts:
  - {name: master, address: 192.168.2.101, internalAddress: 192.168.2.101, user: root, password: "Server@369"}
  - {name: node1, address: 192.168.2.1, internalAddress: 192.168.2.1, port: 22000, user: root, password: "Server@369"}
  - {name: node2, address: 192.168.2.2, internalAddress: 192.168.2.2, port: 22000, user: root, password: "Server@369"}
  - {name: node3, address: 192.168.2.3, internalAddress: 192.168.2.3, port: 22000, user: root, password: "Server@369"}
  - {name: node4, address: 192.168.2.4, internalAddress: 192.168.2.4, port: 22000, user: root, password: "Server@369"}
  - {name: node5, address: 192.168.2.5, internalAddress: 192.168.2.5, port: 22000, user: root, password: "Server@369"}
  - {name: node6, address: 192.168.2.6, internalAddress: 192.168.2.6, port: 22000, user: root, password: "Server@369"}
  - {name: node7, address: 192.168.2.7, internalAddress: 192.168.2.7, port: 22000, user: root, password: "Server@369"}
  - {name: node8, address: 192.168.2.8, internalAddress: 192.168.2.8, port: 22000, user: root, password: "Server@369"}
  roleGroups:
    etcd:
    - master
    control-plane:
    - master
    worker:
    - node1
    - node2
    - node3
    - node4
    - node5
    - node6
    - node7
    - node8
  controlPlaneEndpoint:
    ## Internal loadbalancer for apiservers
    # internalLoadbalancer: haproxy

    domain: lb.kubesphere.local
    address: "192.168.2.101"
    port: 6443
  kubernetes:
    version: v1.23.10
    clusterName: cluster.cave.local
    autoRenewCerts: true
    containerManager: docker
  etcd:
    type: kubekey
  network:
    plugin: calico
    kubePodsCIDR: 10.233.64.0/18
    kubeServiceCIDR: 10.233.0.0/18
    ## multus support. https://github.com/k8snetworkplumbingwg/multus-cni
    multusCNI:
      enabled: false
  registry:
    privateRegistry: ""
    namespaceOverride: ""
    registryMirrors: []
    insecureRegistries: []
  addons: []

  ---
  ...
  spec:
    ...
    authentication:
      jwtSecret: "s05ZZFuvwnfx5OYS3qQehOxV7dOpZsuU"
  ...
  multicluster:
    clusterRole: member
...


./kk create cluster -f cascade-cluster.yaml

```

```shell
### API 서버 IP 추가

# kubeadm config 내용 추출
kubectl get configmap kubeadm-config -n kube-system -o jsonpath='{.data.ClusterConfiguration}' > kubeadm-conf.yaml

# kubeadm-conf.yaml 파일에 certSANS 항목 추가
apiServer:
  certSANs:
  - kubernetes
  - kubernetes.default
  - kubernetes.default.svc
  - kubernetes.default.svc.cluster.local
  - localhost
  - 127.0.0.1
  - lb.kubesphere.local
  - 192.168.2.101
  - 150.183.125.73
  - master
  - master.cluster.local
  - node1
  - node1.cluster.local
  - 192.168.2.1
  - node2
  - node2.cluster.local
  - 192.168.2.2
  - node3
  - node3.cluster.local
  - 192.168.2.3
  - node4
  - node4.cluster.local
  - 192.168.2.4
  - node5
  - node5.cluster.local
  - 192.168.2.5
  - node6
  - node6.cluster.local
  - 192.168.2.6
  - node7
  - node7.cluster.local
  - 192.168.2.7
  - node8
  - node8.cluster.local
  - 192.168.2.8
  - 10.233.0.1


# api server CERT key 재생성
cd /etc/kubernetes/pki
mkdir backup
mv apiserver.* backup
kubeadm init phase certs apiserver --config kubeadm-conf.yaml

# configmap 'kubeadm-config'에 변경 사항 반영
kubeadm init phase upload-config kubelet --config ~/work/kubeadm-conf.yaml


# Host cluster에 cave cluster .kube/config 등록 시 API server 주소를 public IP로 변경해야함
```



# Add node
```shell
vi cascade-cluster.yaml

# 마스터 노드와 추가 할 노드 정보만 (* 기존노드 정보는 있으면 안됨)
---
apiVersion: kubekey.kubesphere.io/v1alpha2
kind: Cluster
metadata:
  name: sample
spec:
  hosts:
  - {name: master, address: 192.168.2.101, internalAddress: 192.168.2.101, user: centos, password: "centos"}
  - {name: node4, address: 150.183.250.236, internalAddress: 150.183.250.236, user: centos, password: "centos"}
  
  roleGroups:
    etcd:
    - master
    control-plane:
    - master
    worker:
    - node4


./kk add nodes -f cascade-cluster.yaml
```




docker update --restart=no rabbitmq
docker stop rabbitmq

rm -rfv /var/lib/docker/volumes/rabbitmq/_data/mnesia/


cp -Rv /var/lib/docker/volumes/rabbitmq/_data/mnesia{,.bk$(date +%F)}