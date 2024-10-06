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

  config.vm.define "jumpbox" do |jumpbox|
      jumpbox.vm.box = "debian/bookworm64"

      jumpbox.vm.hostname = "#{j['hostname']}.#{domain}"
      jumpbox.vm.provider :virtualbox do |vb|
          vb.name   = "jumpbox"
          vb.gui    = false
          vb.memory = j['memory']
      end

      jumpbox.vm.network "private_network", ip: j['ip'], hostname: true

      template = ERB.new File.read("#{current_dir}/downloads.erb")

      jumpbox.vm.provision "shell", inline: <<-SHELL
          apt-get update -y
          apt-get --with-new-pkgs upgrade -y
          apt-get -y install wget curl vim openssl git
          uname -mov
      SHELL

      jumpbox.vm.provision 'shell', reboot: true

      jumpbox.vm.provision "shell", inline: <<-SHELL
          uname -mov

          cd /root

          git clone --depth 1 \
            https://github.com/kelseyhightower/kubernetes-the-hard-way.git
          cd /root/kubernetes-the-hard-way

          mkdir -p downloads
          echo "#{template.result(binding)}" > downloads.txt
          wget -q --https-only -c \
            -P downloads          \
            -i downloads.txt
          ls -loh downloads

          chmod +x downloads/kubectl
          cp downloads/kubectl /usr/local/bin/

          kubectl version --client
      SHELL
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

      server.vm.provision "shell", inline: <<-SHELL
          apt-get update -y
          apt-get --with-new-pkgs upgrade -y
          uname -mov
      SHELL

      server.vm.provision 'shell', reboot: true

      server.vm.provision "shell", inline: <<-SHELL
          uname -mov
      SHELL

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

          node.vm.provision "shell", inline: <<-SHELL
              apt-get update -y
              apt-get --with-new-pkgs upgrade -y
              uname -mov
          SHELL

          node.vm.provision 'shell', reboot: true

          node.vm.provision "shell", inline: <<-SHELL
              uname -mov
          SHELL
      end
  end

end
