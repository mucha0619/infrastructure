# Openstack Manual Install

### Goals
| Manually install the OpenStack on Ubuntu20.04 and connect with the Ceph Cluster

### Host Configuration

|    HostName   |  CPU  |  RAM  |  sda   | sdb    |       IP       |  OS         |
| :-----------: | :---: | :---: | :----: | :----: | :------------: | :-------:   |
| OS-Controller |   4   |  8Gb  |  50Gb  | 50Gb   | 10.170.130.161 | Ubuntu20.04 |
| OS-Compute    |   4   |  8Gb  |  50Gb  | 100Gb  | 10.170.130.161 | Ubuntu20.04 |
| ceph-mon      |   4   |  8Gb  |  50Gb  |   -    | 10.170.131.11  | Ubuntu20.04 |
| ceph-osd1     |   2   |  4Gb  |  50Gb  | 50Gb   | 10.170.130.161 | Ubuntu20.04 |
| ceph-osd2     |   2   |  4Gb  |  50Gb  | 50Gb   | 10.170.130.161 | Ubuntu20.04 |

* Openstack Version : yoga
* Ceph Version : quincy(17.2.6)

```md
Hardware requirements recommended (official)
      |    Controller    |     Compute       |
----------------------------------------------
Cpu   |      1Core +     |      1Core +      |
RAM   |      4Gb +       |      2Gb +        |
HDD   |      5Gb +       |      10Gb +       | 
```


### Architecture




## Prerequirements

### Activate openstack repository and Install Openstack Client
```shell
# Activate archive repository(Controller and Compute)
apt -y update
add-apt-repository cloud-archive:yoga

# Install Openstack Client
apt install python3-openstackclient
```
* Ubuntu20.04 supports up to version yoga archive repository.

### Install and Configure MYSQL
```shell
# Install SQL Database to store information
apt install -y mariadb-server python3-pymysql

vi /etc/mysql/mariadb.conf.d/99-openstack.cnf
---
[mysqld]
bind-address = 10.170.130.161 # Change to the IP addresses mariadb listens

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096 # needs over 500 requires
collation-server = utf8_general_ci
character-set-server = utf8

service mysql restart
mysql_secure_installation
```

### Install and Configure rebbitmq(message queue)
```shell
# Install message queue for interchange and coordination of operations and status information between services
apt install -y rabbitmq-server

# Add openstack user
rabbitmqctl add_user openstack RABBIT_PASS

# Allows configuration, write, and read access for openstack users
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
```

### Install and Configure Memcached
```shell
# Install Memcached to cache tokens using Identity service authentication mechanism for services
apt install -y memcached python3-memcache

# edit /etc/memcached.conf to enable access to other nodes over the management network
---
-l 10.170.130.161 # change from -l 127.0.0.1

service memcached restart
```

### Install and Configure Etcd
```shell
# Install Etcd, a reliable distributed key-value repository for distributed key lock management, configuration storage, service availability, and continuous tracking of other scenarios
apt -y install etcd

# Edit /etc/default/etcd to enable access from another nodes through management network
---

ETCD_NAME="os-controller"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER="controller=http://10.170.130.161:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.170.130.161:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://10.170.130.161:2379"
ETCD_LISTEN_PEER_URLS="http://10.170.130.1612380"
ETCD_LISTEN_CLIENT_URLS="http://10.170.130.161:2379"
```

### Configure the Apache HTTP server
```shell
apt -y install apache2 libapache2-mod-wsgi-py3 python3-oauth2client

# Edit /etc/apache2/apache2.conf
---
SererName os-controller

service apache2 restart

# Load environment variables
vi ~/keystonerc
---
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=1234
export OS_AUTH_URL=http://os-controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export PS1='\u@\h \W(keystone)\$ '

chmod 600 ~/keystonerc

source ~/keystonerc
echo "source ~/keystonerc " >> ~/.bashrc
```


## Install Openstack Services

### Install and Configure Keystone(Identity Serivce)
```shell
# Create keystone database and grant privileges
mysql

MariaDB [(none)]> CREATE DATABASE keystone;
MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'os-controller' \
IDENTIFIED BY 'KEYSTONE_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY 'KEYSTONE_DBPASS';

# Install and configure keystone packeage
apt -y install keystone

vi /etc/keystone/keystone.conf
---

[database]
# Comment or remove any other options in the [database] section
# ...
connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@os-controller/keystone

[token]
# ...
provider = fernet

# Populate the Identity service database
su -s /bin/sh -c "keystone-manage db_sync" keystone

#Initialize Fernet key repository
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

#Bootstrap the Identity service
keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
  --bootstrap-admin-url http://os-controller:5000/v3/ \
  --bootstrap-internal-url http://os-controller:5000/v3/ \
  --bootstrap-public-url http://os-controller:5000/v3/ \
  --bootstrap-region-id RegionOne
```
* --keystone-user and --keystone-group are operating system's user/group that will be used to run keystone.

* The Identity service provides authentication services for each Openstack service.(combination of domains, projects, users, and roles)
```shell
# "default" domain already exist from the keystone-manage bootstrap step
openstack domain create --description "My first Domain" osdomain
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | My first Domain                  |
| enabled     | True                             |
| id          | cfe1011d44c947b9a78edd75729416c3 |
| name        | osdomain                         |
| options     | {}                               |
| tags        | []                               |
+-------------+----------------------------------+

# Create Project that Contains a unique user for each service
openstack project create --domain osdomain --description "Service Project" service
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Service Project                  |
| domain_id   | cfe1011d44c947b9a78edd75729416c3 |
| enabled     | True                             |
| id          | e31d4196078549d1a0c0e3f506936a97 |
| is_domain   | False                            |
| name        | service                          |
| options     | {}                               |
| parent_id   | cfe1011d44c947b9a78edd75729416c3 |
| tags        | []                               |
+-------------+----------------------------------+

# Regular(non-admin) tasks should use an unprivileged project and user.
openstack project create --domain default --description "My frist Project" myproject
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | My frist Project                 |
| domain_id   | default                          |
| enabled     | True                             |
| id          | b144595238b24eaa9dfbdad58255a597 |
| is_domain   | False                            |
| name        | myproject                        |
| options     | {}                               |
| parent_id   | default                          |
| tags        | []                               |
+-------------+----------------------------------+

openstack user create --domain default --password-prompt yhkim
User Password:
Repeat User Password:
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| domain_id           | default                          |
| enabled             | True                             |
| id                  | 129fa54e8f83429db3521279cc748c63 |
| name                | yhkim                            |
| options             | {}                               |
| password_expires_at | None                             |
+---------------------+----------------------------------+

# Add role
openstack role create myrole
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | None                             |
| domain_id   | None                             |
| id          | 5c76417f57924beda2a4a65175eba5a2 |
| name        | myrole                           |
| options     | {}                               |
+-------------+----------------------------------+

# Add the role to the project and user
openstack role add --project myproject --user yhkim myrole
```

### Install and Configure Glance service(Image service)
```shell
# Create glance database and grant previleges
mysql

MariaDB [(none)]> CREATE DATABASE glance;
MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'os-controller' \
  IDENTIFIED BY 'GLANCE_DBPASS';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
  IDENTIFIED BY 'GLANCE_DBPASS';

# Create the glance user
openstack user create --domain default --password-prompt glance
User Password:
Repeat User Password:
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| domain_id           | default                          |
| enabled             | True                             |
| id                  | 2fc4f401046642d59d758c30a45bf9f9 |
| name                | glance                           |
| options             | {}                               |
| password_expires_at | None                             |
+---------------------+----------------------------------+

# Add admin role to the glacne user and service project
openstack role add --project service --user glance admin

# Create the glance service entity
openstack service create --name glance --description "OpenStack Image" image
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Image                  |
| enabled     | True                             |
| id          | 7ecc4c87b56645b4823b109aa016e5ea |
| name        | glance                           |
| type        | image                            |
+-------------+----------------------------------+

# Create the Glance API endpoints
openstack endpoint create --region RegionOne image public http://os-controller:9292
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 0668ceded9334b22a7c1dba25740f452 |
| interface    | public                           |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 7ecc4c87b56645b4823b109aa016e5ea |
| service_name | glance                           |
| service_type | image                            |
| url          | http://os-controller:9292        |
+--------------+----------------------------------+

openstack endpoint create --region RegionOne image internal http://os-controller:9292
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | e6679e6929fa4284832128f4a1f01cee |
| interface    | internal                         |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 7ecc4c87b56645b4823b109aa016e5ea |
| service_name | glance                           |
| service_type | image                            |
| url          | http://os-controller:9292        |
+--------------+----------------------------------+

openstack endpoint create --region RegionOne image admin http://os-controller:9292
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 64ab78df25584f758edaadbfd958dc95 |
| interface    | admin                            |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 7ecc4c87b56645b4823b109aa016e5ea |
| service_name | glance                           |
| service_type | image                            |
| url          | http://os-controller:9292        |
+--------------+----------------------------------+

# Install and configure components
apt install glance

# edit /etc/glance/glance-api.conf
vi /etc/glance/galnce-api.conf
---
[default]
# Configure when use Ceph rbd as a glance backend
default_store=rbd
show_image_direct_url=True
# -------------------------------------------------

[database]
# ...
connection = mysql+pymysql://glance:GLANCE_DBPASS@os-controller/glance

[keystone_authentication]
#...
www_authenticate_uri = http://os-controller:5000
auth_url = http://os-controller:5000
memcached_servers = os-controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = GLANCE_PASS

[paste_deploy]
# ...
flavor = keystone

[glance_store]
# ...
# Configure when use local directory as a glance backend(default)
#stores = file,http
#default_store = file
#filesystem_store_datadir = /var/lib/glance/images/

# Configure when use Ceph rbd as a glance backend
stores = rbd
rbd_store_ceph_conf = /etc/ceph/ceph.conf
rbd_store_user = glance
rbd_store_pool = images
rbd_store_chunk_size = 8
# -------------------------------------------------

[oslo_policy]
# 모든 Openstack 서비스에서 RBAC정책 적용을 지원하는 라이브러리
enforce_scope = false
# 정책을 평가할 때 범위를 적용할 지 여부를 제어
# true : 요청에 사용된 토큰의 범위가 적용중인 정책의 scope_type과 비교, 불일치 시 InvalidScope 예외 발생
# false(default) : 일치하지않는 번위로 정책이 호출되고 있음을 알리는 메시지 기록
enforce_new_defaults = true
# 정책을 평가할 때 사용되지 않는 이전 기본값을 사용할지 여부를 제어. 
# 기본값은 false 이며, false일 경우 이전 기본 값에는 허용 되지만 새 기본값에는 허용되지 않는 경우 토큰 허용 x

```
* As default Glance use backend, which uploads and stores in a directory on the controller node hosting the Glance service. (/var/lib/glance/images)
* When edit *.conf of services. Rather than modifying the original file, it is easier to create a new setup file with only the necessary options after backing up the original file. 

* About Oslo.limit
    * Concept: 서비스에서 관리하는 리소스에 대한 사용 검사 수행 (리소스 청구 대상, 리소스 청구 위치 정의)
    * Usage: real-time allocation of resources belonging to someone and something
    * Limit: Total number of resources someone or something should have
    * Claim: The quantity of resources being asked for by someone. 사용량과 제한량 사이의 관계에 의해 제한됨. (Succesful Claim -> usage)
    * Enforcement: 사용자가 더 많은 리소스를 얻을 수 있는지 여부를 결정하기 위해 사용데이터, Limit information 및 Claim을 수집하는 프로세스
    * For detail: https://docs.openstack.org/oslo.limit/latest/user/usage.html#conceptual-overview

* Configure External ceph cluster settings
```shell

```

### Ceph 클러스터 구축 후 진행//