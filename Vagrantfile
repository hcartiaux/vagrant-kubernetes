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
nodes_list  = params['nodes'].map { |_, node| node['hostname'] }

Vagrant.configure("2") do |config|

  # Pre-requisite - generate a set of ssh keys locally
  config.trigger.before [:up, :provision] do |trigger|
    trigger.info = "Generate SSH keys locally..."
    trigger.run = {inline: "bash -c 'test ! -f \"#{current_dir}/ssh/id_rsa\" && ssh-keygen -P \"\" -f \"#{current_dir}/ssh/id_rsa\" || echo SSH keys already generated '"}
  end

  # Server
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

  # Compute nodes
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

      # 4. Provisioning a CA and Generating TLS Certificates
      jumpbox.vm.provision "shell", inline: <<-SHELL
          cd /root/kubernetes-the-hard-way
          {
            openssl genrsa -out ca.key 4096
            openssl req -x509 -new -sha512 -noenc \
              -key ca.key -days 3653 \
              -config ca.conf \
              -out ca.crt
          }
          certs=(
            "admin" #{nodes_list.map { |hostname| "\"#{hostname}\"" }.join(' ')}
            "kube-proxy" "kube-scheduler"
            "kube-controller-manager"
            "kube-api-server"
            "service-accounts"
          )
          for i in ${certs[*]}; do
            openssl genrsa -out "${i}.key" 4096

            openssl req -new -key "${i}.key" -sha256 \
              -config "ca.conf" -section ${i} \
              -out "${i}.csr"

            openssl x509 -req -days 3653 -in "${i}.csr" \
              -copy_extensions copyall \
              -sha256 -CA "ca.crt" \
              -CAkey "ca.key" \
              -CAcreateserial \
              -out "${i}.crt"
          done
          ls -1 *.crt *.key *.csr

          for host in #{nodes_list.join(' ')}; do
            ssh root@$host mkdir /var/lib/kubelet/

            scp ca.crt    \
              root@$host:/var/lib/kubelet/

            scp $host.crt \
              root@$host:/var/lib/kubelet/kubelet.crt

            scp $host.key \
              root@$host:/var/lib/kubelet/kubelet.key
          done

          scp                                         \
            ca.key ca.crt                             \
            kube-api-server.key kube-api-server.crt   \
            service-accounts.key service-accounts.crt \
            root@server:~/
      SHELL

      # 5. Generating Kubernetes Configuration Files for Authentication
      jumpbox.vm.provision "shell", inline: <<-SHELL
          cd /root/kubernetes-the-hard-way

          # The kubelet Kubernetes Configuration File
          for host in #{nodes_list.join(' ')}; do
            kubectl config set-cluster kubernetes-the-hard-way \
              --certificate-authority=ca.crt                   \
              --embed-certs=true                               \
              --server=https://server.kubernetes.local:6443    \
              --kubeconfig=${host}.kubeconfig

            kubectl config set-credentials system:node:${host} \
              --client-certificate=${host}.crt                 \
              --client-key=${host}.key                         \
              --embed-certs=true                               \
              --kubeconfig=${host}.kubeconfig

            kubectl config set-context default                 \
              --cluster=kubernetes-the-hard-way                \
              --user=system:node:${host}                       \
              --kubeconfig=${host}.kubeconfig

            kubectl config use-context default                 \
              --kubeconfig=${host}.kubeconfig
          done

          # The kube-proxy Kubernetes Configuration File
          {
            kubectl config set-cluster kubernetes-the-hard-way \
              --certificate-authority=ca.crt                   \
              --embed-certs=true                               \
              --server=https://server.kubernetes.local:6443    \
              --kubeconfig=kube-proxy.kubeconfig

            kubectl config set-credentials system:kube-proxy   \
              --client-certificate=kube-proxy.crt              \
              --client-key=kube-proxy.key                      \
              --embed-certs=true                               \
              --kubeconfig=kube-proxy.kubeconfig

            kubectl config set-context default                 \
              --cluster=kubernetes-the-hard-way                \
              --user=system:kube-proxy                         \
              --kubeconfig=kube-proxy.kubeconfig

            kubectl config use-context default                 \
              --kubeconfig=kube-proxy.kubeconfig
          }

          # The kube-controller-manager Kubernetes Configuration File
          {
            kubectl config set-cluster kubernetes-the-hard-way \
              --certificate-authority=ca.crt                   \
              --embed-certs=true                               \
              --server=https://server.kubernetes.local:6443    \
              --kubeconfig=kube-controller-manager.kubeconfig

            kubectl config set-credentials system:kube-controller-manager \
              --client-certificate=kube-controller-manager.crt            \
              --client-key=kube-controller-manager.key                    \
              --embed-certs=true                                          \
              --kubeconfig=kube-controller-manager.kubeconfig

            kubectl config set-context default                 \
              --cluster=kubernetes-the-hard-way                \
              --user=system:kube-controller-manager            \
              --kubeconfig=kube-controller-manager.kubeconfig

            kubectl config use-context default                 \
              --kubeconfig=kube-controller-manager.kubeconfig
          }

          # The kube-scheduler Kubernetes Configuration File
          {
            kubectl config set-cluster kubernetes-the-hard-way \
              --certificate-authority=ca.crt                   \
              --embed-certs=true                               \
              --server=https://server.kubernetes.local:6443    \
              --kubeconfig=kube-scheduler.kubeconfig

            kubectl config set-credentials system:kube-scheduler \
              --client-certificate=kube-scheduler.crt            \
              --client-key=kube-scheduler.key                    \
              --embed-certs=true                                 \
              --kubeconfig=kube-scheduler.kubeconfig

            kubectl config set-context default                 \
              --cluster=kubernetes-the-hard-way                \
              --user=system:kube-scheduler                     \
              --kubeconfig=kube-scheduler.kubeconfig

            kubectl config use-context default                 \
              --kubeconfig=kube-scheduler.kubeconfig
          }

          # The admin Kubernetes Configuration File
          {
            kubectl config set-cluster kubernetes-the-hard-way \
              --certificate-authority=ca.crt                   \
              --embed-certs=true                               \
              --server=https://127.0.0.1:6443                  \
              --kubeconfig=admin.kubeconfig

            kubectl config set-credentials admin               \
              --client-certificate=admin.crt                   \
              --client-key=admin.key                           \
              --embed-certs=true                               \
              --kubeconfig=admin.kubeconfig

            kubectl config set-context default                 \
              --cluster=kubernetes-the-hard-way                \
              --user=admin                                     \
              --kubeconfig=admin.kubeconfig

            kubectl config use-context default                 \
              --kubeconfig=admin.kubeconfig
          }

          # Distribute the Kubernetes Configuration Files
          for host in #{nodes_list.join(' ')}; do
            ssh root@$host "mkdir /var/lib/kube-proxy"

            scp kube-proxy.kubeconfig  \
              root@$host:/var/lib/kube-proxy/kubeconfig

            scp ${host}.kubeconfig     \
              root@$host:/var/lib/kubelet/kubeconfig
          done

          scp admin.kubeconfig                 \
            kube-controller-manager.kubeconfig \
            kube-scheduler.kubeconfig          \
            root@server:~/
      SHELL

      # 6. Generating the Data Encryption Config and Key
      jumpbox.vm.provision "shell", inline: <<-SHELL
          cd /root/kubernetes-the-hard-way

          cat > configs/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: \\${ENCRYPTION_KEY}
      - identity: {}
EOF

          export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
          envsubst < configs/encryption-config.yaml \
            > encryption-config.yaml
          scp encryption-config.yaml root@server:~/
      SHELL

      # 7. Bootstrapping the etcd Cluster
      jumpbox.vm.provision "shell", inline: <<-SHELL
          cd /root/kubernetes-the-hard-way

          scp \
            downloads/etcd-*.tar.gz \
            units/etcd.service \
            root@server:~/

          ssh root@server /vagrant/scripts/7_etcd_server.sh
      SHELL
  end

end
