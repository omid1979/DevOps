    docker run --detach \
   --hostname '192.168.43.163' \
   --env GITLAB_OMNIBUS_CONFIG="external_url 'http://192.168.43.163'" \
   --publish 8443:443 --publish 8080:80 --publish 8022:22 \
   --name gitlab \
   --restart always \
   --volume /opt/docker-sample/gitlab-project/config:/etc/gitlab \
   --volume /opt/docker-sample/gitlab-project/logs:/var/log/gitlab \
   --volume /opt/docker-sample/gitlab-project/data:/var/opt/gitlab \
   --shm-size 256m \
   127.0.0.1:8085/repository/docker/gitlab-ce:latest



docker run -d --name gitlab-runner --restart always \
  -v /opt/docker-sample/gitlab-project/runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  127.0.0.1:8085/repository/docker/gitlab-runner:latest
       
    
    
