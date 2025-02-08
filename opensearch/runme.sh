 docker run -d -p 9200:9200 -p 9600:9600 -e "discovery.type=single-node" opensearchproject/opensearch:latest


 docker run -d -p 9200:9200 -p 9600:9600 -e "discovery.type=single-node" -e "OPENSEARCH_INITIAL_ADMIN_PASSWORD=Cluster@76411" opensearchproject/opensearch:latest
 curl https://localhost:9200 -ku admin:Cluster@76411




export OPENSEARCH_INITIAL_ADMIN_PASSWORD=Cluster@76411

