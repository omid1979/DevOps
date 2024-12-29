docker run -d \
  --name=nextcloud \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -p 443:443 \
  -v /opt/nextcloud/config:/config \
  -v /opt/nextcloud/data:/data \
  --restart unless-stopped \
  linuxserver/nextcloud:latest



