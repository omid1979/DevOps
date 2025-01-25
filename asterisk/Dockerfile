FROM docker.arvancloud.ir/ubuntu:bionic

RUN apt update
RUN apt upgrade -y

RUN apt install -y build-essential wget curl libncurses5-dev libssl-dev libxml2-dev uuid-dev sqlite3 libsqlite3-dev pkg-config libjansson-dev libedit-dev
RUN apt install -y net-tools vim 
RUN apt clean all 
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

WORKDIR /etc/asterisk

CMD ["asterisk", "-f"]
