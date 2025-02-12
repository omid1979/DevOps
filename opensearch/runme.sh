docker network create opensearch-net
echo "Running openearch ...." 
 docker run -d --name opensearch   --network=opensearch-net  -p 9200:9200 -p 9300:9300  -e "OPENSEARCH_INITIAL_ADMIN_PASSWORD=Cluster@76411" -e "plugins.security.disabled=false"   -e "discovery.type=single-node"   opensearchproject/opensearch:latest
echo "Running dashboard ...."
 docker run -d --name opensearch-dashboards --network=opensearch-net -p 5601:5601 -e "OPENSEARCH_HOSTS=https://opensearch:9200" -e "OPENSEARCH_USERNAME=admin" -e "OPENSEARCH_PASSWORD=Cluster@76411"  opensearchproject/opensearch-dashboards:latest


#curl https://localhost:9200 -ku admin:Cluster@76411

echo "Running logstesh ....." 
docker run -d --name logstash -p 5000:5000/tcp -p 5044:5044 -p 514:514/udp -v ./logstash.yml:/usr/share/logstash/config/logstash.yml:ro,Z -v ./logstash.conf:/usr/share/logstash/logstash.conf:ro,Z -e "LOGSTASH_USER=logstash" -e "LOGSTASH_GROUP=logstash" logstash:8.15.1



logger -n localhost  -P 514 -d "Test log message"
