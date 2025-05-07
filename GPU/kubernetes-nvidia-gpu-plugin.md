# 버전정보
쿠버네티스 - 1.23.0

# Pre. 추가 될 GPU 노드 kubernetes cluster에 추가

# 1. GPU Operator 로 GPU 사용

클러스터에 GPU 노드를 추가한다고 해서 사용자가 바로 GPU를 사용할 수 있는 건 아니다. GPU를 노드에서 인식할 수 있도록 드라이버를 (없다면) 설치해야하고, 컨테이너 환경에서 GPU를 사용할 수 있게 무언가의 일들을 해야하며, 쿠버네티스 클러스터의 파드에서 GPU 리소스를 사용할 수 있도록 Device Plugin을 배포해야한다.

쿠버네티스에서는 이런 일련의 설치 및 배포 작업을 GPU Operator를 통해 손쉽게 해결할 수 있다. GPU Operator는 NVIDIA에서 제공하는 Operator로, 관련 CR을 배포하면 GPU 환경 셋업과 관련된 일련의 쿠버네티스 오브젝트들이 순차적으로 배포된다. 여기에 사용하는 CRD와 Operator는 사실상 Helm Chart를 통해서 제공된다.

```shell
# Add and update helm repo
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

# Download helm chart
helm pull nvidia/gpu-operator --untar
cd gpu-operator/
```

# 2. Chart 구조
```shell
tree -L 2
.
├── Chart.lock
├── Chart.yaml
├── charts
│   └── node-feature-discovery
├── crds
│   └── nvidia.com_clusterpolicies_crd.yaml
├── templates
│   ├── _helpers.tpl
│   ├── clusterpolicy.yaml
│   ├── operator.yaml
│   ├── podsecuritypolicy.yaml
│   ├── readonlyfs_scc.openshift.yaml
│   ├── role.yaml
│   ├── rolebinding.yaml
│   └── serviceaccount.yaml
└── values.yaml
```

* charts/node-feature-discovery 가 존재한다는 것에서 알 수 있듯이, 이 Chart는 node-feature-discovery Chart에 의존성이 있다.
    * node-feature-discovery 가 이미 클러스터에 배포되어있다면 values.yaml 에서 nfd.enabled 값을 false 로 수정하면 된다. (기본 값은 true 다.)
    * 여기서는 node-feature-discovery 도 gpu-operator Chart와 함께 배포하기로 한다.
* crds/nvidia.com_clusterpolicies_crd.yaml 에 ClusterPolicy 라는 CRD가 존재한다.
    * templates/clusterpolicy.yaml 에 이 CR이 포함되어 있다.
* templates/operator.yaml 를 통해 알 수 있듯이, GPU Operator의 동작 흐름은 ClusterPolicy 라는 CR을 제출하면 Operator가 이를 모니터링하여 관련한 컴포넌트들을 띄우는 방식이다.
* ClusterPolicy CRD에 이렇게 배포되는 컴포넌트들에 대해 정의가 되어있고, values.yaml 에서 이를 조정할 수 있다.

# 3. 컴포넌트들의 역할과 동작 과정
![alt text](image.png)

Operator (Deployment) 가 ClusterPolicy (CR) 을 모니터링하며 ClusterPolicy 에 설정된 값에 따라 컴포넌트들을 배포한다.

한편, Chart 의존성에 따라 node-feature-discovery Chart가 배포되는데, 구체적으로는 Node Feature Discovery Worker 와 Node Feature Discovery Master 가 배포된다.

* Node Feature Discovery Worker (DaemonSet)
    * 각 노드에서 노드의 정보를 취합하여 Master 로 전송한다.
* Node Feature Discovery Master (Deployment)
    * Worker 로부터 각 노드 정보를 받아서 이를 각 노드에 라벨로 추가한다.

node-feature-discovery Chart 배포가 완료되면, ClusterPolicy 에 따라 다음의 컴포넌트들이 GPU 노드에 배포된다.

* GPU Feature Discovery (DaemonSet)
    * Driver, CUDA, Core 개수 등 GPU 관련 정보를 추출하여 Node Feature Discovery 에게 전송한다.
    * 실제로 노드에 라벨을 작성하는건 Node Feature Discovery 가 담당한다.
* Nvidia Driver Installer (DaemonSet)
    * 노드에서 GPU를 감지할 수 있게 GPU Driver를 노드에 설치한다.
    * 이미 노드에 GPU Driver가 설치되어 있다면, 이 컴포넌트는 values.yaml 에서 enabled: false 로 설정하면 된다.
* Nvidia Device Plugin (DaemonSet)
    * 파드의 GPU 사용은 파드 스펙 내에 resources.nvidia.com/gpu: 1 와 같이 작성하여 사용할 수 있다.
    * 이 컴포넌트는 nvidia.com/gpu 리소스를 감지하고 처리할 수 있게 한다.
    * 참고로, Device Plugin 은 일반적으로 이런 커스텀 리소스(cpu, mem 이 아닌)를 감지하고 처리하는 컴포넌트다.
* Nvidia Container Toolkit (DaemonSet)
    * 컨테이너 환경에서 GPU를 사용할 수 있게 한다.
* GPU Operator Validator (DaemonSet)
    * GPU를 사용하는 컨테이너를 실행함으로써, 최종적으로 GPU 환경이 잘 세팅되었는지 확인한다.
* DCGM Exporter (DaemonSet)
    * GPU 관련 Metric을 특정 엔드포인트에 출력한다.
    * 이를 통해 GPU 사용량, GPU 온도, 사용중인 파드, 네임스페이스 등을 알 수 있다.

위 다이어그램에 표기한 것 처럼 1 -> 2 -> 3 순으로 배포가 진행된다. 3에서는 일부 컴포넌트간 의존성이 존재한다.
![alt text](image-1.png)

Nvidia Driver Installer 가 잘 동작해야 Nvidia Container Toolkit 이 그 다음에 잘 동작한다. 만약 직전 컴포넌트가 잘 동작하지 않는다면 뒤에 있는 컴포넌트는 앞의 컴포넌트가 잘 동작할 때까지 계속해서 기다리게 된다.


# 4. GPU 노드에 테인트 추가
Chart 배포 이전에 해야할 일이 하나 있다. GPU 노드에 테인트를 붙여주지 않으면, GPU를 사용하지 않는 파드도 GPU 노드에 스케줄링될 것이다. 이를 방지하기 위해 GPU 노드에 특정 테인트를 붙여야 한다.

특정 테인트 값은 values.yaml 에서 tolerations 로 검색해보면 다음처럼 알 수 있다.

``` shell
# values.yaml

daemonsets:
  ...
  tolerations:
  - key: nvidia.com/gpu
    operator: Exists
    effect: NoSchedule

...

node-feature-discovery:
  worker:
    tolerations:
    ...
    - key: "nvidia.com/gpu"
      operator: "Equal"
      value: "present"
      effect: "NoSchedule"

# Add taint to gpu node
kubectl taint node gpu-worker01 nvidia.com/gpu=present:NoSchedule
```

# 5. Chart 배포

```shell
# values.yaml

driver:
  enabled: false  # 노드에 이미 드라이버가 설치되어있기 때문에 false로 둔다. (드라이버 자체는 필수다)
...
migManager:
  enabled: false
...
vgpuManager:
  enabled: false

vgpuDeviceManager:
  enabled: false

vfioManager:
  enabled: false

helm install gpu-operator gpu-operator -n gpu-operator --create-namespace
kubectl get clusterpolicy -n gpu-operator
kubectl get pod -n gpu-operator -o wide
kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu
kubectl get runtimeclass
```

pod 스케쥴링을 위한 default 양식
```shell
apiVersion: v1
kind: Pod
metadata:
  name: pod-gpu-1
spec:
  containers:
  - name: cuda-vector-add
    image: k8s.gcr.io/cuda-vector-add:v0.1
    command: ["sleep"]
    args: ["100000"]
    resources:
      limits:
        nvidia.com/gpu: 1
  restartPolicy: Never
  tolerations:
  - effect: NoSchedule
    key: nvidia.com/gpu
    operator: Exists
```

