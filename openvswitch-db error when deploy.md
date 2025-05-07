

### Openvswitch_db error when re-deploy kolla-ansible

```shell
RUNNING HANDLER [openvswitch : Restart openvswitch-db-server container] **************************************************************************************************
changed: [localhost]

RUNNING HANDLER [openvswitch : Waiting for openvswitch_db service to be ready] *******************************************************************************************
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (30 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (29 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (28 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (27 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (26 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (25 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (24 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (23 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (22 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (21 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (20 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (19 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (18 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (17 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (16 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (15 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (14 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (13 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (12 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (11 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (10 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (9 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (8 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (7 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (6 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (5 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (4 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (3 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (2 retries left).
FAILED - RETRYING: [localhost]: Waiting for openvswitch_db service to be ready (1 retries left).
fatal: [localhost]: FAILED! => {"attempts": 30, "changed": false, "cmd": ["docker", "exec", "openvswitch_db", "ovs-vsctl", "--no-wait", "show"], "delta": "0:00:00.011093", "end": "2023-08-07 01:05:47.864808", "msg": "non-zero return code", "rc": 1, "start": "2023-08-07 01:05:47.853715", "stderr": "Error response from daemon: Container 86e7815d6588eb15146948c74b8de9cdc37becf5759ae930e0a337b3bc24a5a7 is not running", "stderr_lines": ["Error response from daemon: Container 86e7815d6588eb15146948c74b8de9cdc37becf5759ae930e0a337b3bc24a5a7 is not running"], "stdout": "", "stdout_lines": []}
```

위 에러가 발생하면서 배포가 안됨.

docker ps / docker volume ls 확인 결과, 동작하고 있는 컨테이너 및 볼륨은 존재하지 않았음.

어쨋든 문제의 원인은 기존 배포가 제대로 destory 되지 않았기 때문이라고 생각하여 추가 확인 해봄

`ps -ef | grep openvswitch` 실행 시 동작중인 프로세스 확인됨

```shell
(kolla) sqkadmin@sqk-cloud:~$ ps -ef | grep open
root     3266715       1  0 01:12 ?        00:00:00 ovsdb-server /etc/openvswitch/conf.db -vconsole:emer -vsyslog:err -vfile:info --remote=punix:/var/run/openvswitch/db.sock --private-key=db:Open_vSwitch,SSL,private_key --certificate=db:Open_vSwitch,SSL,certificate --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert --no-chdir --log-file=/var/log/openvswitch/ovsdb-server.log --pidfile=/var/run/openvswitch/ovsdb-server.pid --detach
root     3266765       1  0 01:12 ?        00:00:00 ovs-vswitchd unix:/var/run/openvswitch/db.sock -vconsole:emer -vsyslog:err -vfile:info --mlockall --no-chdir --log-file=/var/log/openvswitch/ovs-vswitchd.log --pidfile=/var/run/openvswitch/ovs-vswitchd.pid --detach
sqkadmin 3266809 3130202  0 01:16 pts/0    00:00:00 grep --color=auto open
```

해당 프로세스가 원인이 되는 것으로 판단되어, openvswitch_switch 를 remove 해줌
`sudo apt -y remove openvswitch-switch`


이후 배포 시도시 해결!

항상 재배포 설치 시 남아있는 프로세스, 찌꺼기들 확인하자.



