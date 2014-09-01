# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos64"
  config.vm.box_url = "http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20130731.box"

  config.vm.network :private_network, ip: "192.168.55.11"
  config.vm.network :public_network

  config.vm.synced_folder "./", "/vagrant", owner: 'vagrant', group: 'vagrant', mount_options: ['dmode=777', 'fmode=777']
  config.vm.provider :virtualbox do |vb|
    vb.gui = false
    vb.memory = 256
  end
end
