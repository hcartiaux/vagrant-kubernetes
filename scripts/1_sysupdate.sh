#!/bin/bash

echo "========================="
echo "# 1. Updating the system "
echo "========================="

apt-get update -y
apt-get --with-new-pkgs upgrade -y
apt-get autoremove -y

uname -mov
