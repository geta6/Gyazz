# Ansible-playbook for Gyazz

# 動作確認環境

- Vagrant 1.4.3
- Python 2.7.6
- Ansible 1.7


# セットアップ

(TODO)vagrantのprobisioningとかssh_configとかは後でやる予定

```
% vagrant up
% cd ansible
% ansible-playbook gyazz.yml -u vagrant -k
(Enter password "vagrant")
% vagrant ssh # VMに入る

$ cd /vagrant　# 母艦PCとの同期フォルダ
$ npm i
$ GYAZZ_URL=http://gyazz.com
$ PORT=3000 npm start
```

上記の手順が終わったら、ブラウザでhttp://192.168.55.11:3000/にアクセス

# 前準備 (VagrantとかAnsbleをインストールしてない人)

- Install Vagrant
  - [http://www.vagrantup.com/](http://www.vagrantup.com/)
- Install Ansible
```
sudo easy_install pip
sudo pip install ansible --quiet
```


# インストールされるもの

- git
- vim
- yum epel reporsitory
- memcached
- mongodb server (without client)
- node.js (with nodebrew)

# Vagrant 設定

- OS: CentOS 6.4
- IP address: 192.168.55.11
- Memory: 256MB
