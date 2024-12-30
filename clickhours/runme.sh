
docker run -d --name clickhours -d clickhouse/clickhouse-server:latest

docker run -d -p 3000:3000 --name=grafana \
  --volume grafana-storage:/var/lib/grafana \
  grafana/grafana 
