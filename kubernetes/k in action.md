# Kubernetes in action
---

### Hello world 컨테이너 실행하기

$ docker run busybox echo “Hello world”

1. busybox의 최신 이미지가 로컬 시스템에서 제공되고 있는지 확인
2. 최신 이미지가 아니므로 http://docker.io 의 도커 허브 레지스트리에서 최신 이미지 pull
3. docker가 컨테이너를 생성하고 그 안에서 명령을 실행


### 간단한 Node.js 앱 만들기

app.js
```
const http = require('http');
const os = require('os');

console.log("Kubia server starting...");

var handler = function(request, response) {
	console.log("Received request from " + request.connection.remoteAddress);
	response.writeHead(200);
	reponse.end("You've hit " + os.hostname() + "\n");
};

var www = http.createServer(handler);
www.listen(8080);
```

Dockerfile
```
FROM node:7 # 시작점으로 사용할 컨테이너 이미지 정의
ADD app.js /app.js # 로컬디렉터리의 app.js 파일을 이미지의 루트 디렉터리에 동일한 이름으로 추가
ENTRYPOINT ["node", "app.js"] # 이미지를 실행할 때 수행되어야 하는 명령 정의(node app.js)
```

컨테이너 이미지 만들기
` $ docker build -t kubia .` : docker에게 현재 디렉터리 내용을 기반으로 kubia라는 이미지 빌드 요청(docker는 Dockerfile을 찾아 파일 설정에 따라 이미지 빌드)
* 빌드 프로세스는 도커 클라이언트에서 수행되지 않고, 전체 디렉터리의 내용이 도커 데몬에 업로드 되고 이미지가 그 곳에서 빌드됨(빌드 디렉터리의 모든 파일이 데몬에 업로드 되기 때문에, 도커 데몬이 원격지에 있을 때 불필요한 파일이 많다면 성능이 저하됨)

### 이미지 레이어

* 이미지는 크기가 큰 하나의 바이너리 덩어리가 아니며, 여러 개의 레이어로 구성(레이어 별로 여러개의 Pull, Complete 라인이 있음)
* 여러 이미지에서 레이어를 공유하므로 이미지 저장 및 전송이 효율적
* 이미지 생성 시 Dockerfile의 각 명령에 대해 새 레이어 생성

### Docker 명령어

` $ docker run --name kubia-container -p 8080:8080 -d kubia` 

컨테이너 이미지 실행( -p : 로컬 8080포트와 컨테이너 8080포트 매핑, -d : 컨테이너 콘솔에서분리, 백그라운드에서 실행)



` $ docker inspect kubia-container` 

컨테이너의 기본 정보만 표시하는 `docker ps` 보다 자세한 정보 출력(JSON)



` $ docker exec -it kubia-container bash`

Kubia-container 내부에서 bash 실행(-i : STDIN을 오픈 상태로 유지하고 셸에 명령을 입력할 때 필요, -t : TTY 할당)

*i 옵션이 없으면 명령 입력 불가, t 가 없으면 명령 프롬프트 표시 안됨*



` $ docker stop kubia-container`

컨테이너 중지



` $ docker rm kubia-container`

컨테이너 삭제



` $ docker tag kubia mucha0619/kubia` # 이미지 태그 지정(같은 이미지에 여러 태그 추가 가능)

` $ docker push mucha0619/kubia` # docker login 명령어로 로그인 후 도커 허브에 푸시



## Kubernetes



### Pod

* 하나 이상의 밀접하게 관련된 컨테이너로 구성된 그룹
* 애플리케이션을 실행하는 자체 IP, Hostname, 프로세스 등이 있는 별도의 논리적 시스템



### Service가 필요한 이유

* Pod는 일시적이고 새롭게 생성될 때마다 새로운 IP주소를 할당 받기 때문에, 이러한 문제를 해결할 단일 진입점이 필요
* 서비스가 생성되면 정적 IP를 부여받고 서비스는 요청을 Pod 중 하나의 IP 및 Port로 전달



### Pod의 필요성

* 하나의 컨테이너에서 여러 프로세스를 실행할 때, 충돌이나 로그 파악의 복잡도가 올라가는 등 문제를 해결하기 위함
* 때문에 컨테이너들을 단일 단위로 관리할 수 있는 상위 레벨 구조가 필요



### 동일한 Pod의 컨테이너 사이의 부분 격리

* 쿠버네티스는 도커를 구성하여 각 컨테이너가 자체 세트를 가지고 있는 대신 모든 Pod 컨테이너가 동일한 리눅스 네임스페이스 세트를 공유하도록 함으로써 격리
* Pod 내의 컨테이너는 모두 같은 Hostname 및 NIC을 공유하고 동일한 IPC 네임스페이스 아래에서 실행되며 IPC로 통신 가능
* 각 컨테이너의 파일 시스템은 완전히 분리되어 있고, Volume 을 통해 디렉터리를 공유 할 수 있음



### 컨테이너가 동일한 IP 및 포트를 공유하는 방법

* 동일한 Pod의 컨테이너에서 실행중인 프로세스는 동일한 포트 번호에 바인딩 되면 충돌 발생
* Pod 내부의 모든 컨테이너에는 동일한 루프백 네트워크 인터페이스를 가짐(localhost로 통신 가능)



### 플랫 인터 포드 네트워크

* 쿠버네티스 클러스터의 모든 Pod는 한 개의 플랫과 공유 공간, 네트워크 주소 공간에 위치(모든 Pod가 다른 Pod의 IP주소에 있는 다른 모든 Pod에 액세스할 수 있음)



### 컨테이너를 Pod 전체에 적절하게 구성

1. 다수 Pod로 멀티티어 애플리케이션 분할
2. 각각 스케일링이 가능한 Pod로 분할
3. 하나의 Poddㅔ서 다수





