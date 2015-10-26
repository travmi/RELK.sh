# -*- mode: ruby -*-
# vi: set ft=ruby :

$hostnames = <<EOF
echo "Setting up /etc/hosts"
echo -e "172.16.21.5\telasticsearch\n172.16.21.6\tconfluence\n172.16.21.7\tcrowd\n172.16.21.8\tclient\n" >> /etc/hosts
EOF

# Install packages I like
$packages = <<EOF
echo "Installing extra packages"
yum update -y
yum install vim git rsync wget telnet bind-utils -y
setenforce 0
sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
sed -i s/SELINUX=permissive/SELINUX=disabled/g /etc/selinux/config
EOF

# Clean up /etc/resolv.conf if it tries to set domain/search
$resolv = <<EOF
echo "Sanitizing /etc/resolv.conf"
sed -i '/search/d' /etc/resolv.conf
sed -i '/domain/d' /etc/resolv.conf
EOF

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

 config.vm.define "elasticsearch" do |elasticsearch|
   elasticsearch.vm.box = "geerlingguy/centos7"
   elasticsearch.vm.hostname = "elasticsearch"
   elasticsearch.vm.network :private_network, ip: "172.16.21.5"
   elasticsearch.vm.provider "virtualbox" do |vb|
     vb.customize ["modifyvm", :id, "--memory", "2048"]
     vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
     vb.customize ["modifyvm", :id, "--cpus", "2"]
    end
   elasticsearch.vm.provision "shell", inline: "sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config && sed -i s/SELINUX=permissive/SELINUX=disabled/g /etc/selinux/config && setenforce 0"
  end

 config.vm.define "redis" do |redis|
   redis.vm.box = "geerlingguy/centos7"
   redis.vm.hostname = "redis"
   redis.vm.network :private_network, ip: "172.16.21.6"
   redis.vm.provider "virtualbox" do |vb|
     vb.customize ["modifyvm", :id, "--memory", "512"]
     vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
     vb.customize ["modifyvm", :id, "--cpus", "2"]
    end
  end

 config.vm.define "logstash" do |logstash|
   logstash.vm.box = "geerlingguy/centos7"
   logstash.vm.hostname = "logstash"
   logstash.vm.network :private_network, ip: "172.16.21.7"
   logstash.vm.provider "virtualbox" do |vb|
     vb.customize ["modifyvm", :id, "--memory", "512"]
     vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
     vb.customize ["modifyvm", :id, "--cpus", "2"]
    end
  end

  config.vm.define "client" do |client|
    client.vm.box = "geerlingguy/centos7"
    client.vm.hostname = "client"
    client.vm.network :private_network, ip: "172.16.21.8"
    client.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--cpus", "2"]
     end
   end

  hosts = ["elasticsearch", "redis", "logstash", "client"]
  hosts.each do |i|
    config.vm.define "#{i}" do |node|
        node.vm.provision "shell", inline: $hostnames
        node.vm.provision "shell", inline: $resolv
        node.vm.provision "shell", inline: $packages
    end
  end

#  clients = ["agent1", "agent2", "agent3"]
#  clients.each do |i|
#    config.vm.define "#{i}" do |node|
#    	node.vm.provision "shell",
#      	  inline: ""
#        node.vm.provision "shell",
#          inline: ""
#    end
#  end

end
