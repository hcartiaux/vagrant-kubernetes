# encoding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'erb'

current_dir = File.dirname(File.expand_path(__FILE__))
params      = YAML.load_file("#{current_dir}/config.yaml")


Vagrant.configure("2") do |config|

  config.vm.define "jumpbox" do |jumpbox|
      jumpbox.vm.box = "debian/bookworm64"

      jumpbox.vm.hostname = "jumpbox.kubernetes.local"
      jumpbox.vm.provider :virtualbox do |vb|
          vb.name = "jumpbox"
          vb.gui = false
          vb.memory = "512"
      end

      template = ERB.new File.read("#{current_dir}/downloads.erb")

      jumpbox.vm.provision "shell", inline: <<-SHELL
          apt-get update -y
          apt-get upgrade -y
          apt-get -y install wget curl vim openssl git
      SHELL

      jumpbox.vm.provision 'shell', reboot: true

      jumpbox.vm.provision "shell", inline: <<-SHELL
          uname -mov

          cd /root

          git clone --depth 1 \
            https://github.com/kelseyhightower/kubernetes-the-hard-way.git
          cd /root/kubernetes-the-hard-way

          mkdir downloads
          echo "#{template.result(binding)}" > downloads.txt
          wget -q --https-only \
            -P downloads       \
            -i downloads.txt
          ls -loh downloads

          chmod +x downloads/kubectl
          cp downloads/kubectl /usr/local/bin/

          kubectl version --client
      SHELL
  end

  config.vm.define "server" do |server|
      server.vm.box = "debian/bookworm64"

      server.vm.hostname = "server.kubernetes.local"
      server.vm.provider :virtualbox do |vb|
          vb.name = "server"
          vb.gui = false
          vb.memory = "2048"
      end

      server.vm.provision "shell", inline: <<-SHELL
          apt-get update -y
          apt-get upgrade -y
          uname -mov
      SHELL

      server.vm.provision 'shell', reboot: true

      server.vm.provision "shell", inline: <<-SHELL
          uname -mov
      SHELL

  end

  (0..(params['nodes_number']-1)).each do |i|
      config.vm.define "node-#{i}" do |node|
          node.vm.box = "debian/bookworm64"

          node.vm.hostname = "node-#{i}.kubernetes.local"
          node.vm.provider :virtualbox do |vb|
              vb.name = "node-#{i}"
              vb.gui = false
              vb.memory = "2048"
          end

          node.vm.provision "shell", inline: <<-SHELL
              apt-get update -y
              apt-get upgrade -y
              uname -mov
          SHELL

          node.vm.provision 'shell', reboot: true

          node.vm.provision "shell", inline: <<-SHELL
              uname -mov
          SHELL
      end
  end

end
