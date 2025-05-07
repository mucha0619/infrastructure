# Openstack Helm Gate 

### Host Configuration

* ook-first (master-node)
    * cpu: 8 core
    * Mem: 16G
    * Disk: 70G
   
* ook-node1 (worker-node)
    * cpu: 4 core
    * Mem: 8G
    * Disk: 100G
   
* ook-node2 (worker-node)
    * cpu: 4 core
    * Mem: 8G
    * Disk: 50G

# Deploy Openstack helm Infrastructure

###  Kubernetes and Common Setup
```
# Install Basic Utilities
apt install -y git curl make

# Clone the Openstack-Helm Repos
set -xe

git clone https://opendev.org/openstack/openstack-helm-infra.git
git clone https://opendev.org/openstack/openstack-helm.git

# Deploy kubernetes & Helm(Run this at openstack-helm directory)
CURRENT_DIR="$(pwd)"
: ${OSH_INFRA_PATH:="../openstack-helm-infra"}
cd ${OSH_INFRA_PATH}
make dev-deploy setup-host
make dev-deploy k8s
cd ${CURRENT_DIR}
```

### Helm Chart Installation
```
# Setup Clients on the host and assemble the charts
sudo -H -E pip3 install --upgrade pip
sudo -H -E pip3 install \
  -c${UPPER_CONSTRAINTS_FILE:=https://releases.openstack.org/constraints/upper/${OPENSTACK_RELEASE:-xena}} \
  cmd2 python-openstackclient python-heatclient --ignore-installed

export HELM_CHART_ROOT_PATH="${HELM_CHART_ROOT_PATH:="${OSH_INFRA_PATH:="../openstack-helm-infra"}"}"

sudo -H mkdir -p /etc/openstack
sudo -H chown -R $(id -un): /etc/openstack
FEATURE_GATE="tls"; if [[ ${FEATURE_GATES//,/ } =~ (^|[[:space:]])${FEATURE_GATE}($|[[:space:]]) ]]; then
  tee /etc/openstack/clouds.yaml << EOF
  clouds:
    openstack_helm:
      region_name: RegionOne
      identity_api_version: 3
      cacert: /etc/openstack-helm/certs/ca/ca.pem
      auth:
        username: 'admin'
        password: 'password'
        project_name: 'admin'
        project_domain_name: 'default'
        user_domain_name: 'default'
        auth_url: 'https://keystone.openstack.svc.cluster.local/v3'
EOF
else
  tee /etc/openstack/clouds.yaml << EOF
  clouds:
    openstack_helm:
      region_name: RegionOne
      identity_api_version: 3
      auth:
        username: 'admin'
        password: 'password'
        project_name: 'admin'
        project_domain_name: 'default'
        user_domain_name: 'default'
        auth_url: 'http://keystone.openstack.svc.cluster.local/v3'
EOF
fi

# Build helm-toolkit, most charts depend on helm-toolkit
make -C ${HELM_CHART_ROOT_PATH} helm-toolkit


# Deploy the ingress controller
export HELM_CHART_ROOT_PATH="${HELM_CHART_ROOT_PATH:="${OSH_INFRA_PATH:="../openstack-helm-infra"}"}"
: ${OSH_EXTRA_HELM_ARGS_INGRESS:="$(./tools/deployment/common/get-values-overrides.sh ingress)"}

# Lint and package chart
make -C ${HELM_CHART_ROOT_PATH} ingress

# Deploy command
: ${OSH_EXTRA_HELM_ARGS:=""}
tee /tmp/ingress-kube-system.yaml << EOF
deployment:
  mode: cluster
  type: DaemonSet
network:
  host_namespace: true
EOF

touch /tmp/ingress-component.yaml

if [ -n "${OSH_DEPLOY_MULTINODE}" ]; then
  tee --append /tmp/ingress-kube-system.yaml << EOF
pod:
  replicas:
    error_page: 2
EOF
  tee /tmp/ingress-component.yaml << EOF
pod:
  replicas:
    ingress: 2
    error_page: 2
EOF
fi

helm upgrade --install ingress-kube-system ${HELM_CHART_ROOT_PATH}/ingress \
  --namespace=kube-system \
  --values=/tmp/ingress-kube-system.yaml \
  ${OSH_EXTRA_HELM_ARGS} \
  ${OSH_EXTRA_HELM_ARGS_INGRESS} \
  ${OSH_EXTRA_HELM_ARGS_INGRESS_KUBE_SYSTEM}

# Wait for deploy
./tools/deployment/common/wait-for-pods.sh kube-system

# Deploy namespace ingress
helm upgrade --install ingress-openstack ${HELM_CHART_ROOT_PATH}/ingress \
  --namespace=openstack \
  --values=/tmp/ingress-component.yaml \
  ${OSH_EXTRA_HELM_ARGS} \
  ${OSH_EXTRA_HELM_ARGS_INGRESS} \
  ${OSH_EXTRA_HELM_ARGS_INGRESS_OPENSTACK}

# Wait for deploy
./tools/deployment/common/wait-for-pods.sh openstack

helm upgrade --install ingress-ceph ${HELM_CHART_ROOT_PATH}/ingress \
  --namespace=ceph \
  --values=/tmp/ingress-component.yaml \
  ${OSH_EXTRA_HELM_ARGS} \
  ${OSH_EXTRA_HELM_ARGS_INGRESS} \
  ${OSH_EXTRA_HELM_ARGS_INGRESS_CEPH}

# Wait for deploy
./tools/deployment/common/wait-for-pods.sh ceph
```

### Deploy MariaDB
```
export HELM_CHART_ROOT_PATH="${HELM_CHART_ROOT_PATH:="${OSH_INFRA_PATH:="../openstack-helm-infra"}"}"
: ${OSH_EXTRA_HELM_ARGS_MARIADB:="$(./tools/deployment/common/get-values-overrides.sh mariadb)"}

# Lint and package chart
make -C ${HELM_CHART_ROOT_PATH} mariadb

# Deploy command
: ${OSH_EXTRA_HELM_ARGS:=""}
helm upgrade --install mariadb ${HELM_CHART_ROOT_PATH}/mariadb \
    --namespace=openstack \
    --set pod.replicas.server=1 \
    ${OSH_EXTRA_HELM_ARGS} \
    ${OSH_EXTRA_HELM_ARGS_MARIADB}

# Wait for deploy
./tools/deployment/common/wait-for-pods.sh openstack


### MariaDB helm install 과정에서 몇몇 init pod들이 동작하지 않는 문제 발생
~/openstack-helm-infra/mariadb/values.yaml에 설정된 storageClass 명과 실제 storageClass가 상이
```

### Deploy RabbitMQ
```
export HELM_CHART_ROOT_PATH="${HELM_CHART_ROOT_PATH:="${OSH_INFRA_PATH:="../openstack-helm-infra"}"}"
: ${OSH_EXTRA_HELM_ARGS_RABBITMQ:="$(./tools/deployment/common/get-values-overrides.sh rabbitmq)"}

# Lint and package chart
make -C ${HELM_CHART_ROOT_PATH} rabbitmq

# Deploy command
: ${OSH_EXTRA_HELM_ARGS:=""}
helm upgrade --install rabbitmq ${HELM_CHART_ROOT_PATH}/rabbitmq \
    --namespace=openstack \
    ${OSH_EXTRA_HELM_ARGS} \
    ${OSH_EXTRA_HELM_ARGS_RABBITMQ}

# Wait for deploy
./tools/deployment/common/wait-for-pods.sh openstack
```

### Deploy Memchaced
```
export HELM_CHART_ROOT_PATH="${HELM_CHART_ROOT_PATH:="${OSH_INFRA_PATH:="../openstack-helm-infra"}"}"
: ${OSH_EXTRA_HELM_ARGS_MEMCACHED:="$(./tools/deployment/common/get-values-overrides.sh memcached)"}

# Lint and package chart
make -C ${HELM_CHART_ROOT_PATH} memcached

# Deploy command
: ${OSH_EXTRA_HELM_ARGS:=""}
helm upgrade --install memcached ${HELM_CHART_ROOT_PATH}/memcached \
    --namespace=openstack \
    ${OSH_EXTRA_HELM_ARGS:=} \
    ${OSH_EXTRA_HELM_ARGS_MEMCACHED}

# Wait for deploy
./tools/deployment/common/wait-for-pods.sh openstack
```


# Deploy Openstack Components

<b>Run command at '~/openstack-helm'</b>

### Deploy Keystone
```
make keystone

# Get the over-rides to use
: ${OSH_EXTRA_HELM_ARGS_KEYSTONE:="$(./tools/deployment/common/get-values-overrides.sh keystone)"}

# Deploy command
: ${OSH_EXTRA_HELM_ARGS:=""}
helm upgrade --install keystone ./keystone \
    --namespace=openstack \
    ${OSH_EXTRA_HELM_ARGS} \
    ${OSH_EXTRA_HELM_ARGS_KEYSTONE}

# Wait for deploy
./tools/deployment/common/wait-for-pods.sh openstack

# Validate Deployment info
export OS_CLOUD=openstack_helm
sleep 30 #NOTE(portdirect): Wait for ingress controller to update rules and restart Nginx
openstack endpoint list


### job과 pod중 rabbit-init 관련 컨테이너들에 에러 발생 -> openstack command 정상 작동하는 것으로 보아 rabbitmq 이미 설치하여 발생하는 문제로 추정 => values.yaml에서 수정하여 테스트 필요
```

### Deploy Glance
```
make glance

: ${OSH_EXTRA_HELM_ARGS:=""}
: ${GLANCE_BACKEND:="swift"}
: ${OSH_EXTRA_HELM_ARGS_GLANCE:="$(./tools/deployment/common/get-values-overrides.sh glance)"}
tee /tmp/glance.yaml <<EOF
storage: ${GLANCE_BACKEND}
EOF
helm upgrade --install glance ./glance \
  --namespace=openstack \
  --values=/tmp/glance.yaml \
  --set manifests.network_policy=true \
  ${OSH_EXTRA_HELM_ARGS} \
  ${OSH_EXTRA_HELM_ARGS_GLANCE}

./tools/deployment/common/wait-for-pods.sh openstack

export OS_CLOUD=openstack_helm
openstack service list
sleep 30 #NOTE(portdirect): Wait for ingress controller to update rules and restart Nginx
openstack image list
openstack image show 'Cirros 0.3.5 64-bit'
```

