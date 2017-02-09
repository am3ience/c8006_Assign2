##!/bin/sh

### User Configuration ###

echo "What is the internal subnet of your network? ex.) 192.168.1.0/24"
read subnet

echo "What is the name of your internal network card? ex.) eno0"
read intnic

echo "What is the name of your external network card? ex.) eno1"
read extnic

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
#Accept Fragments
iptables -A FORWARD -f -j ACCEPT

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
