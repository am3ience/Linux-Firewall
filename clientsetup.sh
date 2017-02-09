ifconfig eno1 down

ifconfig enp3s2 10.0.0.1/24 up

route add default gw 10.0.0.254

route -n 