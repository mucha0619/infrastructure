### SKYLINE API SERVER
```shell
# DBeaver접속 후 skyline db 생성
openstack user create --domain default --password-prompt skyline

openstack role add --project service --user skyline admin

# MariaDB 계정(DBeaver)
ID : root
PASSWD : cat /etc/kolla/passwords.yml | grep database_password

CREATE DATABASE IF NOT EXISTS skyline DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;


GRANT ALL PRIVILEGES ON skyline.* TO 'skyline'@'localhost' IDENTIFIED BY '1234';

GRANT ALL PRIVILEGES ON skyline.* TO 'skyline'@'%'  IDENTIFIED BY '1234';

sudo docker pull 99cloud/skyline:2023.1
git clone https://opendev.org/skyline/skyline-apiserver

sudo mkdir -p /etc/skyline /var/log/skyline /var/lib/skyline /var/log/nginx

cp skyline-apiserver/etc/skyline.yaml.sample /etc/skyline/skyline.yaml

# /etc/skyline/skyline.yaml 수정
---
default:
  database_url: mysql://skyline:SKYLINE_DBPASS@DB_SERVER:3306/skyline
  debug: true
  log_dir: /var/log/skyline
openstack:
  keystone_url: http://KEYSTONE_SERVER:5000/v3/
  system_user_password: SKYLINE_SERVICE_PASSWORD


sudo docker run -d --name skyline_bootstrap \
  -e KOLLA_BOOTSTRAP="" \
  -v /etc/skyline/skyline.yaml:/etc/skyline/skyline.yaml \
  -v /var/log:/var/log \
  --net=host 99cloud/skyline:2023.1

  sudo docker rm -f skyline_bootstrap

  sudo docker run -d --name skyline --restart=always \
  -v /etc/skyline/skyline.yaml:/etc/skyline/skyline.yaml \
  -v /var/log:/var/log \
  --net=host 99cloud/skyline:2023.1
```


curl -i \
  -H "Content-Type: application/json" \
  -d '
{ "auth": {
    "identity": {
      "methods": ["password"],
      "password": {
        "user": {
          "name": "admin",
          "domain": { "id": "default" },
          "password": "password"
        }
      }
    }
  }
}' \
  "http://keystone.openstack.svc.cluster.local/v3" ; echo


curl -i \
  -H "Content-Type: application/json" \
  -d '
{ "auth": {
    "identity": {
      "methods": ["token"],
      "token": {
        "id": "'$OS_TOKEN'"
      }
    }
  }
}' \
  "http://172.236.5.45:51994/v3" ; echo