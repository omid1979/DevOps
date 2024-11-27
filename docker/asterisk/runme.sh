docker compose -f asterisk.yml up -d



docker network create --subnet=172.10.0.0/16 asterisk-network 

docker run --net asterisk --ip 172.10.0.10 -d --name asterisk1 --hostname asterisk1 -p 5060:5060/tcp -p 10000-10099:10000-10099/udp -v ./asterisk1/log:/var/log/asterisk/ -v ./asterisk1/asterisk/sip.conf:/etc/asterisk/sip.conf asterisk:latest

docker run --net asterisk --ip 172.10.0.20 -d --name asterisk2 --hostname asterisk2 -p 5061:5060/tcp -p 10100-10199:10000-10099/udp -v ./asterisk2/log:/var/log/asterisk/ -v ./asterisk2/asterisk/sip.conf:/etc/asterisk/sip.conf asterisk:latest

docker run --net asterisk --ip 172.10.0.30 -d --name asterisk3 --hostname asterisk3 -p 5062:5060/tcp -p 10200-10299:10000-10099/udp -v ./asterisk3/log:/var/log/asterisk/ -v ./asterisk3/asterisk/sip.conf:/etc/asterisk/sip.conf asterisk:latest

