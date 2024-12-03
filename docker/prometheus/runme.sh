docker run --name prometheus \
    -v /opt/prometheus:/opt/bitnami/prometheus/data \
    #-v /opt/prometheus/prometheus.yml:/opt/bitnami/prometheus/conf/prometheus.yml \
    docker.arvancloud.ir/bitnami/prometheus:latest

# Create persistent volume for your data
#docker volume create prometheus-data
# Start Prometheus container
docker run --name prometheus \
    -p 9090:9090 \
    -v /opt/prometheus.yml:/etc/prometheus/prometheus.yml \
    -v /opt/prometheus:/prometheus \
    docker.arvancloud.ir/prom/prometheus
