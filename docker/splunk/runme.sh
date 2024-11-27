docker run -d -p 8000:8000 -p 5140:514/udp -p 7000:7000 -e "SPLUNK_START_ARGS=--accept-license" -e "SPLUNK_PASSWORD=Cluster@76411" --name splunk 127.0.0.1:8085/repository/docker/splunk/splunk:latest
