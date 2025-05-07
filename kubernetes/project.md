Controlplane에 Jenkins 설치

* Jenkins Download

```jenkins download
$ wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
$ sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ >  /etc/apt/sources.list.d/jenkins.list'
$ sudo apt-get update
$ sudo apt-get install jenkins
```



* JDK 17 사용 시 Jenkins 구동이 안되는 문제 발생(JDK 11로 변경 시 정상 설치)

``` JDK 11로 변경
$ sudo update-alternatives --config java
There are 2 choices for the alternative java (providing /usr/bin/java).

  Selection    Path                                         Priority   Status
------------------------------------------------------------
  0            /usr/lib/jvm/java-17-openjdk-amd64/bin/java   1711      auto mode
* 1            /usr/lib/jvm/java-11-openjdk-amd64/bin/java   1111      manual mode
  2            /usr/lib/jvm/java-17-openjdk-amd64/bin/java   1711      manual mode

Press <enter> to keep the current choice[*], or type selection number:1
```



* Jenkins 정상 동작

![스크린샷 2022-04-12 오후 2.24.16](/Users/yonghyeon/Documents/project image/스크린샷 2022-04-12 오후 2.24.16.png)



* Application에서 8080 포트 사용중이기 때문에 jenkins 기본 포트 9000으로 변경

```jenkins port change
$ sudo vi /etc/default/jenkins
```

![스크린샷 2022-04-12 오후 2.27.05](/Users/yonghyeon/Documents/project image/스크린샷 2022-04-12 오후 2.27.05.png)



* jenkins의 로그 파일 정보는 `/var/log/jenkins/jenkins.log` 에서 확인 가능



* Jenkins 초기 접속 창

![스크린샷 2022-04-12 오후 2.28.43](/Users/yonghyeon/Documents/project image/스크린샷 2022-04-12 오후 2.28.43.png)



* 경로 조회하여 초기 비밀번호 확인

```jenkins default passwd
$ sudo cat /var/lib/jenkins/secrets/initialAdminPassword
244945bf8bc14e949e57e102ccc451d2
```



* 추천 Plugin 설치

![스크린샷 2022-04-12 오후 2.31.59](/Users/yonghyeon/Documents/project image/스크린샷 2022-04-12 오후 2.31.59.png)



* Git Credential 설정(ID, password 방식과 SSH 방식이 있지만 보안상 SSH 방식 추천)

> 비대칭 키를 생성해준 후 public key는 GitHub repository에 private 키는 jenkins credentials에 등록

	1. 비대칭 키 생성



2. private key credential 등록



