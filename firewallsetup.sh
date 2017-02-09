iptables -F
iptables -t nat -F

cat /proc/sys/net/ipv4/ip_forward

iptables -t nat -A POSTROUTING -j SNAT -o eno1 --to-source 192.168.0.12 #ip of firewall

ifconfig enp3s2 10.0.0.254/24

iptables -t nat -L

