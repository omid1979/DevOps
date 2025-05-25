
pcs resource create nginx ocf:heartbeat:nginx op monitor interval=30s
pcs resource create frr systemd:frr op monitor interval=30s
pcs resource create ntp systemd:ntp op monitor interval=30s
pcs resource create wireguard systemd:wg-quick@client op monitor interval=30s

pcs resource enable nginx
pcs resource enable frr
pcs resource enable ntp
pcs resource enable wireguard

pcs resource group add service-group webserver frr wireguard ntp

pcs constraint location services_group prefers node1=100 node2=50 

pcs resource meta services_group resource-stickiness=100

pcs resource enable services_group

pcs resource create vip ocf:heartbeat:IPaddr2 ip=192.168.221.230 cidr_netmask=24 op monitor interval=30
pcs resource group add services_group vip
pcs resource enable vip

pcs resource
pcs status



