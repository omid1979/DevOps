
docker pull iwaseyusuke/mininet

docker pull onosproject/onos:latest

docker run -t -d -p 8181:8181 -p 8101:8101 -p 6653:6653 -p 6633:6633 --name onos onosproject/onos:latest

docker run -it  --privileged -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /lib/modules:/lib/modules iwaseyusuke/mininet 


URL :  http://localhost:8181/onos/ui
	user:  onos
	pass : rocks


CLI :  bash# ssh -p 8101 onos@localhost
	rocks 

app activate org.onosproject.openflow
app activate org.onosproject.fwd


mn --controller=remote,ip=172.17.0.3,port=6653 --topo=linear,3  --switch=ovs,protocols=OpenFlow13

====================
mininet> pingall
        *** Ping: testing ping reachability
        h1 -> h2 h3 h4
        h2 -> h1 h3 h4
        h3 -> h1 h2 h4
        h4 -> h1 h2 h3
        *** Results: 0% dropped (12/12 received)

#bandwith Test
        mininet> h1 iperf -s &
        mininet> h2 iperf -c h1
#Delay Test
        ininet> h1 ping -c 4 h2

#Traffic Monior using Wireshark :
        sudo wireshark &

#O-RAN Policys :

onos> add-flows -f reactive





 
=====================
mininet> pingall
	*** Ping: testing ping reachability
	h1 -> h2 h3 h4
	h2 -> h1 h3 h4
	h3 -> h1 h2 h4
	h4 -> h1 h2 h3
	*** Results: 0% dropped (12/12 received)

#bandwith Test
	mininet> h1 iperf -s &
	mininet> h2 iperf -c h1
Delay Test
	ininet> h1 ping -c 4 h2

Traffic Monior using Wireshark : 
	sudo wireshark &

O-RAN Policys : 

onos> add-flows -f reactive



