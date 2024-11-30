docker run -d --name some-clickhouse-server --ulimit nofile=262144:262144 clickhouse/clickhouse-server

docker run -it --rm --link some-clickhouse-server:clickhouse-server --entrypoint clickhouse-client clickhouse/clickhouse-server --host clickhouse-server
# OR
docker exec -it some-clickhouse-server clickhouse-client

echo "SELECT 'Hello, ClickHouse!'" | docker run -i --rm --link some-clickhouse-server:clickhouse-server buildpack-deps:curl curl 'http://clickhouse-server:8123/?query=' -s --data-binary @-

docker run -d -p 18123:8123 -p19000:9000 --name clickhouse-server --ulimit nofile=262144:262144 \
    -v "$PWD/ch_data:/var/lib/clickhouse/" \
    -v "$PWD/ch_logs:/var/log/clickhouse-server/" \
    -v "/path/to/your/config.xml:/etc/clickhouse-server/config.xml" \
    clickhouse/clickhouse-server
echo 'SELECT version()' | curl 'http://localhost:18123/' --data-binary @-


