Docker Install from Repository 
## Removed all old docker packages 
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

======OR ==========================
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
===================================
sudo apt-get update

 sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

vi /etc/docker/daemon.json
    {
      "insecure-registries" : ["https://docker.arvancloud.ir"],
      "registry-mirrors": ["https://docker.arvancloud.ir"]
    },
    {
      "log-driver": "json-file",            
      "log-opts": {                    
            "max-size": "1g",                    
            "max-file": "2"         
            }
    }


================================
Docker Install from Package
 
https://download.docker.com/linux/ubuntu/dists/


dpkg -i containerd.io_<version>_<arch>.deb
dpkg -i docker-ce_<version>_<arch>.deb
dpkg -i docker-ce-cli_<version>_<arch>.deb
dpkg -i docker-buildx-plugin_<version>_<arch>.deb
dpkg -i docker-compose-plugin_<version>_<arch>.deb
=========================================
 sudo service docker start
 sudo systemctl enable docker.service
 sudo systemctl enable containerd.service

 docker run hello-world

===============================
 sudo groupadd docker
 sudo usermod -aG docker $USER
 newgrp docker



=============================== WORKSHOP

git clone https://github.com/docker/getting-started-app.git


├── getting-started-app/
│ ├── .dockerignore
│ ├── package.json
│ ├── README.md
│ ├── spec/
│ ├── src/
│ └── yarn.lock



# syntax=docker/dockerfile:1
FROM node:lts-alpine
WORKDIR /app
COPY . .
RUN yarn install --production
CMD ["node", "src/index.js"]
EXPOSE 3000


 docker build -t getting-started .

Start APP : 
 docker run -d -p 127.0.0.1:3000:3000 getting-started

Visit http://127.0.0.1:3000


============================================== Tutorial 
 docker ps

 modify source
 
 docker build -t getting-started 


docker stop <the-container-id>   # Stop a container
docker rm  <the-container-id>    # Remove Stoped Container
docker rm -f <the-container-id>   # stop and remove container forced 

push image 
docker push docker/getting-started  
docker build --platform linux/amd64 -t YOUR-USER-NAME/getting-started .


DOCKER VOLUME
=============
docker volume create todo-db
docker run -dp 3000:3000 --mount type=volume,src=todo-db,target=/etc/todos container-name

docker volume inspect todo-db

                [
                    {
                        "CreatedAt": "2019-09-26T02:18:36Z",
                        "Driver": "local",
                        "Labels": {},
                        "Mountpoint": "/var/lib/docker/volumes/todo-db/_data",
                        "Name": "todo-db",
                        "Options": {},
                        "Scope": "local"
                    }
                ]       


docker version
docker info
docker build -t IMAGENAME
docker image 
docker image prune
docker volume 
docker network 
docker image 
docker ps 
docker rmi  IMAGE NAME to delete
docker stop 
 docker run -it --cpus=".5" ubuntu /bin/bash
 docker run -it --cpu-period=100000 --cpu-quota=50000 ubuntu /bin/bash

docker login -u <username>

