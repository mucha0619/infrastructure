# OOK Deploy

### Goals
Ceph 클러스터와 kubernetes 클러스터 위에 오픈스택 코어 서비스 배포 (nova,cinder,glance,neutron)

### Day1

1. Cephadm Install (quincy)

2. kubespray kubernetes deploy
```shell
#패키지 업데이트
sudo apt update
#Python 설치
sudp apt install -y python3-pip

#kubespary python package install
cd kubespray/
sudo pip3 install -r requirements.txt

#Inventory 파일 설정
cp -r inventory/sample inventory/mycluster
vi inventory/mycluster/inventory.ini 
---
# ## Configure 'ip' variable to bind kubernetes services on a
# ## different ip than the default iface
# ## We should set etcd_member_name for etcd cluster. The node that is not a etcd member do not need to set the value, or can set the empty string value.
[all]
sqk-kolla ansible_host=10.170.70.115   ip=10.170.70.115 etcd_member_name=etcd1
compute01 ansible_host=10.170.170.200  ip=10.170.170.200 etcd_member_name=etcd2
compute02 ansible_host=10.170.170.205  ip=10.170.170.205 etcd_member_name=etcd3
# node4 ansible_host=95.54.0.15  # ip=10.3.0.4 etcd_member_name=etcd4
# node5 ansible_host=95.54.0.16  # ip=10.3.0.5 etcd_member_name=etcd5
# node6 ansible_host=95.54.0.17  # ip=10.3.0.6 etcd_member_name=etcd6

# ## configure a bastion host if your nodes are not directly reachable
# [bastion]
# bastion ansible_host=x.x.x.x ansible_user=some_user

[kube_control_plane]
sqk-kolla
# node2
# node3

[etcd]
sqk-kolla
# node2
# node3

[kube_node]
compute01
compute02
# node4
# node5
# node6

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
---

# Kubespary 설치
ansible-playbook -i inventory/mycluster/inventory.ini -become --become-user=root cluster.yml 

# kubectl 설정
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

```


3. Install Helm
```shell
#Helm 설치
curl -LO https://git.io/get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
helm init --service-account tiller --upgrade
helm version
#Client: &version.Version{SemVer:"v2.17.0", GitCommit:"a690bad98af45b015bd3da1a41f6218b1a451dbe", GitTreeState:"clean"}
#Server: &version.Version{SemVer:"v2.17.0", GitCommit:"a690bad98af45b015bd3da1a41f6218b1a451dbe", GitTreeState:"clean"}

#local helm repo 등록
sudo tee /etc/systemd/system/helm-serve.service <<EOF
[Unit]
Description=Helm Server
After=network.target
  
[Service]
User=root
Restart=always
ExecStart=/usr/local/bin/helm serve
  
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload ; systemctl enable helm-serve --now
helm repo list
#NAME    URL
#stable  https://charts.helm.sh/stable
#local   http://127.0.0.1:8879/charts

##Setting CSI(Ceph RBD)
[root@kube-cy4-kube001 ~]# ceph mon dump
dumped monmap epoch 1
epoch 1
fsid f9b17cb6-b38c-455b-b10d-5c44d7bcc36b
last_changed 2020-08-01 16:23:11.258185
created 2020-08-01 16:23:11.258185
min_mon_release 14 (nautilus)
0: [v2:10.4.20.21:3300/0,v1:10.4.20.21:6789/0] mon.kube-cy4-kube001

[root@kube-cy4-kube001 ~]# ceph osd pool create kubernetes 64 64
pool 'kubernetes' created
[root@kube-cy4-kube001 ~]# rbd pool init kubernetes
[root@kube-cy4-kube001 ~]# ceph auth get-or-create client.kubernetes mon 'profile rbd' osd 'profile rbd pool=kubernetes'
[client.kubernetes]
    key = AQBMeiVf1CKrHBAAYeIVScZlRiDo6D58xvPM4Q==

[root@kube-cy4-kube001 ~]# cd /home/deploy/
[root@kube-cy4-kube001 deploy]# git clone https://github.com/ceph/ceph-csi.git ; cd ceph-csi/

## 현재 쿠버네티스 버전이 1.22.1 이기 때문에, csi driver 버전을 3.8로 변경
git checkout origin/release-v3.8 

+ 오류 추가 발생 시, ceph-csi/example/rbd/ 경로의 ceph-conf.yaml fsid, monip  추가 후 apply
+ all in one 이기 때문에, pod deploy들 replica 1로 변경

# 배포 확인

[root@kube-cy4-kube001 rbd]# kubectl  get pod
NAME                                        READY   STATUS    RESTARTS   AGE
csi-rbdplugin-2m68m                         3/3     Running   0          19s
csi-rbdplugin-8xfpd                         3/3     Running   0          19s
csi-rbdplugin-provisioner-b77dfc64c-469b6   6/6     Running   0          20s
csi-rbdplugin-provisioner-b77dfc64c-lwgg9   6/6     Running   0          20s
csi-rbdplugin-provisioner-b77dfc64c-wnxkt   6/6     Running   0          20s
csi-rbdplugin-r9v28                         3/3     Running   0          19s
 
 
[root@kube-cy4-kube001 rbd]# kubectl  get sc
NAME         PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc   rbd.csi.ceph.com   Delete          Immediate           true                   79s
 
[root@kube-cy4-kube001 rbd]# cd /home/deploy/ceph-csi/
[root@kube-cy4-kube001 ceph-csi]# kubectl create -f examples/rbd/pvc.yaml
[root@kube-cy4-kube001 ceph-csi]# kubectl  get pvc
NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
rbd-pvc   Bound    pvc-a33aeeec-e51a-463a-a708-f6ede4dbbc8a   1Gi        RWO            csi-rbd-sc     3s

# ceph cl.uster에서 이미지 확인
[root@kube-cy4-kube001 ceph-csi]# rbd ls -p kubernetes
csi-vol-91ae5b24-d477-11ea-8fdb-1a270cdb0b8f


## Deploy Openstack Helm / Helm Infra



###  INGRESS

!!!!!! OPENSTACK INGRES 배포 시 --set deployment.cluster.class=nginx \ 꼭 붙이기!!!!!!!!!!!!!!!!!!!!!!!!!!!!
```