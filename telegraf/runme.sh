docker run -d --name telegraf --network telegraf -v ./telegraf.conf:/etc/telegraf/telegraf.conf:ro telegraf:alpine

docker run -d --name influxdb --network telegraf -p 8086:8086  -v "./data:/var/lib/influxdb2"  -v "./config:/etc/influxdb2" -e DOCKER_INFLUXDB_INIT_MODE=setup -e DOCKER_INFLUXDB_INIT_MODE=setup -e DOCKER_INFLUXDB_INIT_USERNAME=admin -e DOCKER_INFLUXDB_INIT_PASSWORD=cluster -e DOCKER_INFLUXDB_INIT_ORG=telegraf -e DOCKER_INFLUXDB_INIT_BUCKET=telegraf influxdb

docker run -d --name=grafana --network telegraf -p 3000:3000 grafana/grafana
