# 차트 개발 팁과 요령

---



## Helm chart 배포 매커니즘

1. Helm list (첫 배포인지 아닌지 판단)
2. 첫 배포라면 Helm install로 배포
3. 아니라면 Helm Upgrade로 업데이트
4. Pod의 상태와 상관없이 Createa만 요청하고 끝



## 차트 Install 및 업그레이드 팁

`helm install my chart -n nm-1 --create-namespace`(해당 namespace가 없으면 생성 후 배포)

`helm upgrade mychart . -n nm-1`

​											 `--create-namespace` : namespace 없을 시 생성

​											`--install` : 릴리즈가 없을 시 install 수행

​											`--wait` : pod가 running 상태가 될 때 까지 기다렸다가 결과 반환(default 5분)

​											`--timeout 10m` : 대기 시간 10분으로 변경



## Pod 자동 재기동 팁

```deployment.yaml
Configmap 수정했을 경우
deployment.yaml
---
annotations:
  checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
  # include로 configmap을 sha256sum으로 인코딩 해주면 컨피그 맵 변경 시 내용이 변경되면서 deployment에서 재생성 or rolling update
```

```deployment.yaml
수정과 상관 없이 재기동
deployment.yaml
---
rollme: {{ randAlphaNum 5 | quote }} # 알파뱃과 숫자를 랜덤으로 생성하여 ""를 붙힘 배포할 때 마다 값이 바뀌기 때문에 deployment 내용 변경으로 인식하여 pod 항상 재기동

# 개발환경에서 이미지 태그 latest 사용 시 template이 변경되더라도 deployment에서 변경을 감지하지 못하기 때문에 항상 재기동 하도록 함
# 암호화를 위한 랜덤값 생성시 주의 필요
```



## Helm에서 PV와 Namespace에 대한 동작

```PV수정
# pv.yaml의 path 수정 시 Bound상태에서 수정 불가하기 때문에 오류 발생(Uninstall 후 install 필요)
# Uninstall 시 namespace까지 삭제해 버리면 해당 namespace에 배포된 다른 리소스도 삭제되기 때문에 유의해야함

```



## Helm 저장소

```Helm저장소
# Helm은 배포나 업그레이드 시 마다 Secret이 추가되어 네이밍 룰이나 데이터가 암호화되어 포함됨
# Helm history 명령어로 출력
```





# Helm Hook

---



### Helm Hook

> Chart를 install 하거나 upgrade 할 때, 배포 전 후 등 특정 시점에 생성되어야 할 리소스를 지정
>
> 해당 yaml 파일에 annotation으로 선언

```Hook
pre-pod1.yaml
---
annotation:
  helm.sh/hook: pre-install(upgrade, rollback, delete)

post-pod1.yaml
---
annotation:
  helm.sh/hook: post-install(upgrade, rollback, delete)
  
test/*.yaml
# Helm 배포 후의 앱 상태나 부가적인 부분 테스트 용도
---
annotation:
  helm.sh/hook: test

crds/*.yaml
# custom resource definition: 쿠버네티스 리소스를 새로 정의해서 사용
# crds 폴더 내의 리소스들이 일반 Pre-install 리소스들보다 먼저 실행
  
```





### Hook-weight

> Pod 실행 우선순위 지정

```hook-weight
pre-pod1.yaml
---
annotation:
  helm.sh/hook: pre-install
  helm.sh/hook-weight: "-1"

pre-pod2.yaml
---
annotation:
  helm.sh/hook: pre-install

pre-pod3.yaml
---
annotation:
  helm.sh/hook: pre-install
  helm.sh/hook-weight: "1"
  
# 실행 우선 순위 1: [음수], 2:[0], 3:[양수]
# Hook weight를 주지 않으면 "0"이 defalut
```



### hook-detete-policy

> Hook으로 만든 리소스에 대한 삭제 시점을 정함

```hook-del
pre-pod1.yaml
---
annotations:
  helm.sh/hook: pre-install, pre-upgrade
  helm.sh/hook-delete-policy: before-hook-creation # helm upgrade 시 삭제(이름 중복 안되도록) - default 
  #helm.sh/hook-delete-policy: hook-succeeded # complete로 완료 되면 삭제
  #helm.sh/hook-delete-policy: hook-failed # failed로 완료 되면 삭제
```



### resource-policy

> hook으로 만들어진 리소스들은 helm uninstall로 삭제되지 않음
>
> hook에 대한 garbage collection 기능 추가 예정
>
> 이 때, 삭제하면 안되는 Hook 리소스에 keep 처리





