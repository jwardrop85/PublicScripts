#!/bin/bash
# download the package to the VM 
wget https://dl.influxdata.com/telegraf/releases/telegraf-1.22.0-1.x86_64.rpm
# install the package 
sudo yum localinstall telegraf-1.22.0-1.x86_64.rpm
# generate the new Telegraf config file in the current directory 
telegraf --input-filter cpu:mem:disk --output-filter azure_monitor config > azm-telegraf.conf
# replace the example config with the new generated config 
sudo cp azm-telegraf.conf /etc/telegraf/telegraf.conf
# stop the telegraf agent on the VM 
sudo systemctl stop telegraf
# start the telegraf agent on the VM to ensure it picks up the latest configuration 
sudo systemctl start telegraf
exit 0