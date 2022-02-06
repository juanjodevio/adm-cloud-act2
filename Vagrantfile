# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/bionic64"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "file", source: "./install_mongo.sh", destination: "/tmp/install_mongo.sh"
  config.vm.provision "file", source: "./config.ini", destination: "/tmp/config.ini"

  config.vm.provision "shell", inline: <<-SHELL
    chmod 755 /tmp/install_mongo.sh
    /tmp/install_mongo.sh -f /tmp/config.ini
  SHELL
end
