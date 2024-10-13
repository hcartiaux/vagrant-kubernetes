#!/bin/bash

apt-get update -y
apt-get --with-new-pkgs upgrade -y
apt-get autoremove -y

uname -mov
