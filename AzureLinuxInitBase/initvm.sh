#!/bin/bash
# download the package to the VM 
wget https://dl.influxdata.com/telegraf/releases/telegraf_1.8.0~rc1-1_amd64.deb
# install the package 
sudo dpkg -i telegraf_1.8.0~rc1-1_amd64.deb
# generate the new Telegraf config file in the current directory 
telegraf --input-filter cpu:mem:disk --output-filter azure_monitor config > azm-telegraf.conf
# replace the example config with the new generated config 
sudo cp azm-telegraf.conf /etc/telegraf/telegraf.conf
# stop the telegraf agent on the VM 
sudo systemctl stop telegraf
# start the telegraf agent on the VM to ensure it picks up the latest configuration 
sudo systemctl start telegraf