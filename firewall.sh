##!/bin/sh

### User Configuration ###

echo "What is the internal subnet of your network? (eg. 192.168.1.0/24)"
read subnet

echo "What is the name of your internal network card? (eg. eno0)"
read internal

echo "What is the name of your external network card? (eg. eno1)"
read external

### /User Configuration ###

## DO NOT TOUCH BELOW THIS LINE ###
#-----------------------------------------------------------------

clear
#flush IP tables
iptables -F
#delete user-chains
iptables -X

# Change the default chain policy to DROP
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#User Defined chain
iptables -N ssh
iptables -N www
iptables -N otherdrop
iptables -N otheraccept


iptables -A ssh -j ACCEPT
iptables -A www -j ACCEPT
iptables -A otherdrop -j DROP
iptables -A otheraccept -j ACCEPT

#---------------------------------------------------
#Drop all TCP packets with the SYN and FIN bit set.
iptables -A FORWARD -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP 

#---------------------------------------------------
#Do not allow Telnet packets at all
iptables -A FORWARD -p tcp --dport 23 -j DROP 
iptables -A FORWARD -p tcp --sport 23 -j DROP 

#---------------------------------------------------
#For FTP and SSH services, set control connections to "Minimum Delay" and FTP data to "Maximum Throughput"
#FTP Data
iptables -A PREROUTING -t mangle -p tcp --dport 20 -j TOS --set-tos Minimize-Delay
iptables -A PREROUTING -t mangle -p tcp --sport 20 -j TOS --set-tos Minimize-Delay
#FTP Control
iptables -A PREROUTING -t mangle -p tcp --dport 21 -j TOS --set-tos Minimize-Delay
iptables -A PREROUTING -t mangle -p tcp --sport 21 -j TOS --set-tos Minimize-Delay
#SSH
iptables -A PREROUTING -t mangle -p tcp --dport 22 -j TOS --set-tos Minimize-Delay
iptables -A PREROUTING -t mangle -p tcp --sport 22 -j TOS --set-tos Minimize-Delay

#FTP data to "Maximum Throughput"
iptables -A PREROUTING -t mangle -p tcp --dport 20 -j TOS --set-tos Maximize-Throughput
iptables -A PREROUTING -t mangle -p tcp --sport 20 -j TOS --set-tos Maximize-Throughput

#----------------------------------------------------
#Allow inbound/outbound DHCP
#iptables -A OUTPUT -p udp --dport 68 -j otheraccept
#iptables -A INPUT -p udp --sport 68 -j otheraccept
#iptables -A OUTPUT -p tcp --dport 68 -j otheraccept
#iptables -A INPUT -p tcp --sport 68 -j otheraccept

#----------------------------------------------------
#Allow inbound/outbound DNS
#iptables -A OUTPUT -p udp --dport 53 -j otheraccept
#iptables -A INPUT -p udp --sport 53 -j otheraccept
#iptables -A OUTPUT -p tcp --dport 53 -j otheraccept
#iptables -A INPUT -p tcp --sport 53 -j otheraccept

#---------------------------------------------------
#save then restart the iptables
systemctl iptables save
systemctl iptables restart

iptables -L -v -n -x
