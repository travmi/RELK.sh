RELK.sh
=======

Install the ELK stack (with Redis) with one script for the central log server (only for CentOS 6.5).

Use the following line (remember to read comments of RELK.sh-file tho):

    curl -k https://raw.githubusercontent.com/adionditsak/RELK.sh/master/RELK.sh | bash

##Testing

Sending messages to Redis:

```
/opt/logstash/bin/logstash -e 'input { stdin { } } output { redis { host => ["172.16.21.5"] data_type => "list" key=> "logstash" } }'
```

Config testing for logstash:

```
/opt/logstash/bin/logstash -f /etc/logstash/conf.d/logstash-simple.conf --configtest
```
