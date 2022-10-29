#!/usr/bin/env sh
IP=$(ip address show dev eth0 | grep "inet " | awk '{print $2}' | cut -d \/ -f1)
sed "s/0.0.0.0/${IP:-127.0.0.1}/g" /etc/dnsmasq.conf.tmpl > /etc/dnsmasq.conf
/usr/sbin/dnsmasq --conf-file=/etc/dnsmasq.conf --no-daemon
