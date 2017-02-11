iptables -F
iptables -t nat -F

cat /proc/sys/net/ipv4/ip_forward


#iptables -t nat -A POSTROUTING -j SNAT -o eno1 --to-source 192.168.0.12 #ip of firewall

#should be in the firewall script
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eno1 -j SNAT --to-source 192.168.0.12
iptables -t nat -A PREROUTING -i eno1 -j DNAT --to-destination 10.0.0.1

ifconfig enp3s2 10.0.0.254

iptables -t nat -L

