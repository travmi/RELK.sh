#/bin/bash

##########################################################
### INTRODUCTION
##########################################################

: '
Install and configure R (Redis) + ELK server from scratch on CentOS 6.5.
* Logstash version 1.5.x
* Elasticsearch version 1.4.x
- You have to change the IP-address to the IP of the central server in configuration marked with [ip-for-central-server].
- You may have to change the Elasticsearch network.host parameter to the internal IP of your server to use eg. GET on the URL from Kibana.
- You may have to change the Kibana elasticsearch parameter to the actual URL with your internal IP to connect probably to the interface.
- The "elasticsearch_url:" in the Kibana config needs to be set to the IP address of the elasticsearch server.
- Redis configs needs to be bound to IP address.
'

##########################################################
### MAIN
##########################################################

main() {
dependencies
elasticsearch
logstash
kibana
redis
start_and_chkconfig
}

##########################################################
### DEPENDENCIES
##########################################################

dependencies() {
echo ""
echo "Dependencies"
sleep 2
yum install epel-release -y
yum -y install java-1.8.0-openjdk nginx redis
}

##########################################################
### ELASTICSEARCH
##########################################################

elasticsearch() {
echo ""
echo "Elasticsearch"
cat <<EOF >> /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-1.4]
name=Elasticsearch repository for 1.4.x packages
baseurl=http://packages.elasticsearch.org/elasticsearch/1.4/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1
EOF
yum -y install elasticsearch
sed -i '/network.host/c\network.host: localhost' /etc/elasticsearch/elasticsearch.yml
sed -i '/discovery.zen.ping.multicast.enabled/c\discovery.zen.ping.multicast.enabled: false' /etc/elasticsearch/elasticsearch.yml
sed -i '/cluster.name/c\cluster.name: elasticsearch' /etc/elasticsearch/elasticsearch.yml
sed -i '/network.host/c\network.host: 172.16.21.5' /etc/elasticsearch/elasticsearch.yml
chown -R elasticsearch:elasticsearch /var/lib/elasticsearch/ /var/log/elasticsearch/
}

##########################################################
### LOGSTASH
##########################################################

logstash() {
echo ""
echo "Logstash"
sleep 2
cat <<EOF >> /etc/yum.repos.d/logstash.repo
[logstash-1.5]
name=logstash repository for 1.5.x packages
baseurl=http://packages.elasticsearch.org/logstash/1.5/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1
EOF
yum -y install logstash
cat <<EOF >> /etc/logstash/conf.d/default.conf
input {
redis {
host => "172.16.21.5"
type => "redis"
data_type => "list"
key => "logstash"
}
}
filter {
}
output {
elasticsearch {
host => ["172.16.21.5"]
cluster => "elasticsearch"
}
stdout { codec => rubydebug }
}
EOF
chown -R logstash:logstash /var/lib/logstash/ /var/log/logstash/
}

##########################################################
### KIBANA
##########################################################

kibana() {
echo ""
echo "Kibana"
sleep 2
#cd /var/www/html
#mkdir kibana
#curl -O https://download.elasticsearch.org/kibana/kibana/kibana-4.0.0-linux-x64.tar.gz
#tar -xzvf kibana-4.0.0-linux-x64.tar.gz
#cd kibana-4.0.0-linux-x64
#mv * ../kibana; cd ..; ls
cat <<EOF >> /etc/yum.repos.d/kibana.repo
[kibana-4.1]
name=Kibana repository for 4.1.x packages
baseurl=http://packages.elastic.co/kibana/4.1/centos
gpgcheck=1
gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
EOF
yum install kibana -y
sed -i '/elasticsearch_url:/c\elasticsearch_url: "http://172.16.21.5:9200"' /opt/kibana/config/kibana.yml
cat <<EOF >> /etc/nginx/conf.d/kibana.conf
server {
    listen          80;
    server_name     kibana;

    access_log  /var/log/nginx/kibana.access.log main;
    error_log   /var/log/nginx/kibana.error.log;

    #auth_basic "Authorized users";
    #auth_basic_user_file /file/location/kibana.htpasswd;

    location / {
        proxy_pass http://172.16.21.5:5601;
        proxy_http_version 1.1;
        #proxy_set_header Upgrade $http_upgrade;
        #proxy_set_header Connection 'upgrade';
        #proxy_set_header Host $host;
        #proxy_cache_bypass $http_upgrade;
    }

#    location / {
#        root  /var/www/html/kibana;
#        #index  index.html  index.htm;
#       proxy_pass http://172.16.21.5:5601;
#       proxy_read_timeout 90;
#    }

    location ~ ^/_aliases$ {
        proxy_pass http://172.16.21.5:9200;
        proxy_read_timeout 90;
    }
    location ~ ^/.*/_aliases$ {
        proxy_pass http://172.16.21.5:9200;
        proxy_read_timeout 90;
    }
    location ~ ^/_nodes$ {
        proxy_pass http://172.16.21.5:9200;
        proxy_read_timeout 90;
    }
    location ~ ^/.*/_search$ {
        proxy_pass http://172.16.21.5:9200;
        proxy_read_timeout 90;
    }
    location ~ ^/.*/_mapping {
        proxy_pass http://172.16.21.5:9200;
        proxy_read_timeout 90;
    }

    # Password protected end points
    location ~ ^/kibana-int/dashboard/.*$ {
        proxy_pass http://172.16.21.5:5601;
        proxy_read_timeout 90;
        limit_except GET {
          proxy_pass http://172.16.21.5:5601;
          # auth_basic "Restricted";
          # auth_basic_user_file /file/location/kibana.htpasswd;
        }
    }
    location ~ ^/kibana-int/temp.*$ {
        proxy_pass http://172.16.21.5:5601;
        proxy_read_timeout 90;
        limit_except GET {
            proxy_pass http://172.16.21.5:5601;
            # auth_basic "Restricted";
            # auth_basic_user_file /file/location/kibana.htpasswd;
        }
    }
}

EOF
chown -R nginx:nginx /var/www/html/*
}

##########################################################
### REDIS
##########################################################

redis() {
echo ""
echo "Redis"
sleep 2
sed -i '/bind 127.0.0.1/c\bind 172.16.21.5' /etc/redis.conf
mkdir -p /var/log/redis
touch /var/log/redis/redis.log
chown -R redis:redis /var/log/redis/
}

##########################################################
### START SERVICES + CHKCONFIG ON
##########################################################

start_and_chkconfig() {
echo ""
echo "Starting services + enable"
sleep 2
systemctl enable elasticsearch
systemctl enable logstash
systemctl enable redis
systemctl enable httpd
systemctl enable kibana
systemctl restart elasticsearch
systemctl restart logstash
systemctl restart nginx
systemctl restart redis
systemctl restart kibana
}

##########################################################
### INIT
##########################################################

main

##########################################################
### AGENTS GUIDE
##########################################################

# Install logstash agents on your agent servers:
: '
Redhat-based:
yum -y install java-1.8.0-openjdk
cat <<EOF >> /etc/yum.repos.d/logstash.repo
[logstash-1.5]
name=Logstash repository for 1.5.x packages
baseurl=http://packages.elasticsearch.org/logstash/1.5/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1
EOF
yum -y install logstash
Debian-based:
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
sudo apt-get -y install oracle-java7-installer
echo "deb http://packages.elasticsearch.org/logstash/1.4/debian stable main" | sudo tee /etc/apt/sources.list.d/logstash.list
sudo apt-get update
sudo apt-get install logstash=1.4.2-1-2c0f5a1
Bug: In Ubuntu you may have to edit the LS_GROUP=logstash to LS_GROUP=adm in the logstash Init script - known bug
'
# Redirect output to Redis at this server:
: '
input {
file {
type => "messages"
path => ["/var/log/messages"]
}
}
output {
redis {
host => ["172.16.21.5"]
data_type => "list"
key => "logstash"
}
}
'
