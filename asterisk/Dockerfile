FROM docker.arvancloud.ir/ubuntu:bionic

RUN apt update
RUN apt upgrade -y

RUN apt install -y build-essential wget curl libncurses5-dev libssl-dev libxml2-dev uuid-dev sqlite3 libsqlite3-dev pkg-config libjansson-dev libedit-dev
RUN apt install -y net-tools vim isc-dhcp-server 
WORKDIR /usr/local/src

# Getting, Building and Installing Asterisk
RUN wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18-current.tar.gz
RUN tar -zxvf asterisk-18-current.tar.gz  
RUN cd asterisk-18.26.1
WORKDIR /usr/local/src/asterisk-18.26.1
RUN ./configure
RUN make 
RUN make install

# Test Configuration
RUN mkdir -p /etc/asterisk
COPY ./configuration/* /etc/asterisk/

# Configure DHCP server
RUN echo "INTERFACESv4='eth0'" > /etc/default/isc-dhcp-server
RUN echo "authoritative;\n\
subnet 192.168.1.0 netmask 255.255.255.0 {\n\
  range 192.168.1.100 192.168.1.200;\n\
  option routers 192.168.1.1;\n\
  option domain-name-servers 8.8.8.8, 8.8.4.4;\n\
  default-lease-time 600;\n\
  max-lease-time 7200;\n\
}" > /etc/dhcp/dhcpd.conf

WORKDIR /etc/asterisk

EXPOSE 5060/udp 5060/tcp 10000-20000/udp 67/udp 68/udp

CMD asterisk -f

