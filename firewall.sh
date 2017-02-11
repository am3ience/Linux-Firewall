##!/bin/sh

### User Configuration ###

#"What's the internal subnet of your network? ex.) 10.0.0.0/24"
subnet='10.0.0.0/24'

#"What's the name of your internal network card? ex.) enp3s2"
intnic='enp3s2'

#"What's the name of your external network card? ex.) eno1"
extnic='eno1'

#"What TCP service ports would you like to be allowed on the firewall? (list seperated by spaces)"
#"ex.) 80 443 53 22 67 68 HTTP, HTTPS, DNS"
TCParray=(80 443 53 22 67 68)

#"What UDP service ports would you like to be allowed on the firewall? (list seperated by spaces)"
#"ex.) 53 68 67 80 443 DNS and DHCP"
UDParray=(53 68 67 80 443)

#"What ICMP service type numbers would you like to be allowed on the firewall? (list seperated by spaces)"
#"ex.) 0 3 8 Echo Reply, Destination Unreachable, and Echo"
ICMParray=(0 3 8)

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
iptables -N TCP
iptables -N UDP
iptables -N ICMP

iptables -A TCP -j ACCEPT
iptables -A UDP -j ACCEPT
iptables -A ICMP -j ACCEPT

#--------------------------------------------------
#Firewall Routing
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eno1 -j SNAT --to-source 192.168.0.12
iptables -t nat -A PREROUTING -i eno1 -j DNAT --to-destination 10.0.0.1

#--------------------------------------------------
#Drop all packets destined for the firewall host from the outside
iptables -A INPUT -i $extnic -j DROP

#--------------------------------------------------
#Do not accept any packets with a source address from the outside matching your internal network. 
iptables -A FORWARD -i $extnic -s $subnet -j DROP

#---------------------------------------------------
#Drop all TCP packets with the SYN and FIN bit set.
iptables -A FORWARD -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP 

#---------------------------------------------------
#Do not allow Telnet packets at all
iptables -A FORWARD -p tcp --dport 23 -j DROP 
iptables -A FORWARD -p tcp --sport 23 -j DROP 

#Block all external traffic directed to ports 32768-32775, 137-139, TCP ports 111 and 515
iptables -A FORWARD -i $extnic -o $intnic -p tcp --dport 32768:32775 -j DROP
iptables -A FORWARD -i $extnic -o $intnic -p tcp --dport 137:139 -j DROP
iptables -A FORWARD -i $extnic -o $intnic -p udp --dport 32768:32775 -j DROP
iptables -A FORWARD -i $extnic -o $intnic -p udp --dport 137:139 -j DROP
iptables -A FORWARD -i $extnic -o $intnic -p tcp --dport 111 -j DROP
iptables -A FORWARD -i $extnic -o $intnic -p tcp --dport 515 -j DROP

#---------------------------------------------------
#You must ensure the you reject those connections that are coming the “wrong” way 
#(i.e., inbound SYN packets to high ports). 
iptables -A FORWARD -i $extnic -o $intnic -p tcp --tcp-flags ALL SYN ! --dport 0:1023 -j DROP

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
#Inbound/Outbound TCP packets on allowed ports
for element in "${TCParray[@]}"
do
	iptables -A FORWARD -i $intnic -o $extnic -p tcp --dport $element -m state --state NEW,ESTABLISHED -j TCP
	iptables -A FORWARD -i $extnic -o $intnic -p tcp --sport $element -m state --state NEW,ESTABLISHED -j TCP
	iptables -A FORWARD -i $intnic -o $extnic -p tcp --sport $element -m state --state NEW,ESTABLISHED -j TCP
	iptables -A FORWARD -i $extnic -o $intnic -p tcp --dport $element -m state --state NEW,ESTABLISHED -j TCP
done

#----------------------------------------------------
#Inbound/Outbound UDP packets on allowed ports
for n in "${UDParray[@]}"
do
	iptables -A FORWARD -i $intnic -o $extnic -p udp --dport $n -j UDP
	iptables -A FORWARD -i $extnic -o $intnic -p udp --sport $n -j UDP
	iptables -A FORWARD -i $intnic -o $extnic -p udp --sport $n -j UDP
	iptables -A FORWARD -i $extnic -o $intnic -p udp --dport $n -j UDP
done

#----------------------------------------------------
#Inbound/Outbound ICMP packets based on type numbers
for i in "${ICMParray[@]}"
do
	iptables -A FORWARD -i $intnic -o $extnic -p icmp --icmp-type $i -j ICMP
	iptables -A FORWARD -i $extnic -o $intnic -p icmp --icmp-type $i -j ICMP
done

#---------------------------------------------------
#Accept Fragments
iptables -A FORWARD -f -j ACCEPT

#----------------------------------------------------
#Allow inbound/outbound DHCP
#iptables -A OUTPUT -p udp --dport 68 -j ACCEPT
#iptables -A INPUT -p udp --sport 68 -j ACCEPT
#iptables -A OUTPUT -p tcp --dport 68 -j ACCEPT
#iptables -A INPUT -p tcp --sport 68 -j ACCEPT

#----------------------------------------------------
#Allow inbound/outbound DNS
#iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
#iptables -A INPUT -p udp --sport 53 -j ACCEPT
#iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
#iptables -A INPUT -p tcp --sport 53 -j ACCEPT

#---------------------------------------------------
#save then restart the iptables
systemctl iptables save
systemctl iptables restart

iptables -L -v -n -x
