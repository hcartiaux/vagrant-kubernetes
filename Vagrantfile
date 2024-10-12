# encoding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'erb'

current_dir = File.dirname(File.expand_path(__FILE__))
params      = YAML.load_file("#{current_dir}/config.yaml")

domain      = params['domain']
j           = params['jumpbox']
s           = params['server']
n           = params['nodes']

Vagrant.configure("2") do |config|

  config.trigger.before [:up, :provision] do |trigger|
    trigger.info = "Generate SSH keys locally..."
    trigger.run = {inline: "bash -c 'test ! -f \"#{current_dir}/ssh/id_rsa\" && ssh-keygen -P \"\" -f \"#{current_dir}/ssh/id_rsa\" || echo SSH keys already generated '"}
  end

  config.vm.define "server" do |server|
      server.vm.box = "debian/bookworm64"

      server.vm.hostname = "#{s['hostname']}.#{domain}"
      server.vm.provider :virtualbox do |vb|
          vb.name   = "server"
          vb.gui    = false
          vb.memory = s['memory']
      end

      server.vm.network "private_network", ip: s['ip'], hostname: true

      server.vm.provision "shell", path: "scripts/1_sysupdate.sh"
      server.vm.provision 'shell', reboot: true
      server.vm.provision "shell", inline: <<-SHELL
          uname -mov
      SHELL

      # 3. Provisioning Compute Resources
      server.vm.provision "shell", path: "scripts/3_sshd.sh"
  end

  n.each do |key, worker|
      config.vm.define "#{key}" do |node|
          node.vm.box = "debian/bookworm64"

          node.vm.hostname = "#{worker['hostname']}.#{domain}"
          node.vm.provider :virtualbox do |vb|
              vb.name   = "#{key}"
              vb.gui    = false
              vb.memory = "#{worker['memory']}"
          end

          node.vm.network "private_network", ip: worker['ip'], hostname: true

          node.vm.provision "shell", path: "scripts/1_sysupdate.sh"
          node.vm.provision 'shell', reboot: true
          node.vm.provision "shell", inline: <<-SHELL
              uname -mov
          SHELL

          # 3. Provisioning Compute Resources
          node.vm.provision "shell", path: "scripts/3_sshd.sh"
      end
  end

  # Orchestrator VM
  config.vm.define "jumpbox" do |jumpbox|
      jumpbox.vm.box = "debian/bookworm64"

      jumpbox.vm.hostname = "#{j['hostname']}.#{domain}"
      jumpbox.vm.provider :virtualbox do |vb|
          vb.name   = "jumpbox"
          vb.gui    = false
          vb.memory = j['memory']
      end

      jumpbox.vm.network "private_network", ip: j['ip'], hostname: true

      jumpbox.vm.provision "shell", path: "scripts/1_sysupdate.sh"
      jumpbox.vm.provision 'shell', reboot: true
      jumpbox.vm.provision "shell", inline: <<-SHELL
          uname -mov
      SHELL

      # 2. Set Up The Jumpbox
      template_downloads = ERB.new(File.read("#{current_dir}/templates/downloads.erb"), nil, '-')
      jumpbox.vm.provision "shell", inline: <<-SHELL
          apt-get -y install wget curl vim openssl git

          cd /root
          git clone --depth 1 \
            https://github.com/kelseyhightower/kubernetes-the-hard-way.git
          cd /root/kubernetes-the-hard-way

          mkdir -p downloads
          echo "#{template_downloads.result(binding)}" > downloads.txt
          wget -q --https-only -c \
            -P downloads          \
            -i downloads.txt
          ls -loh downloads

          chmod +x downloads/kubectl
          cp downloads/kubectl /usr/local/bin/

          kubectl version --client
      SHELL

      # 3. Provisioning Compute Resources
      jumpbox.vm.provision "shell", path: "scripts/3_sshd.sh"
      template_machines  = ERB.new(File.read("#{current_dir}/templates/machines.erb"),  nil, '-')
      jumpbox.vm.provision "shell", inline: <<-SHELL
          cd /root
          echo "#{template_machines.result(binding)}"  > machines.txt

          while read IP FQDN HOST SUBNET; do
            ssh-keyscan ${IP} >> .ssh/known_hosts
          done < machines.txt

          while read IP FQDN HOST SUBNET; do
            echo -n "${HOST} "
            ssh -n root@${IP} uname -o -m
          done < machines.txt

          while read IP FQDN HOST SUBNET; do
            echo -n "${HOST} "
            ssh -n root@${IP} hostname --fqdn
          done < machines.txt

          echo "" > hosts
          echo "# Kubernetes The Hard Way" >> hosts
          while read IP FQDN HOST SUBNET; do
              ENTRY="${IP} ${FQDN} ${HOST}"
              echo $ENTRY >> hosts
          done < machines.txt
          cat hosts >> /etc/hosts

          for host in server node-0 node-1; do
             ssh-keyscan ${host} >> .ssh/known_hosts
             ssh root@${host} uname -o -m -n
          done

          while read IP FQDN HOST SUBNET; do
            scp hosts root@${HOST}:~/
            ssh -n \
              root@${HOST} "cat hosts >> /etc/hosts"
          done < machines.txt
      SHELL
  end

end
