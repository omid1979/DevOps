#!/bin/bash
set -e

  sleep 30
  echo "Waiting for Elasticsearch availability"
  echo "Setting kibana_system password"
  curl -X POST -u elastic:${ELASTIC_PASSWORD} -H "Content-Type: application/json" http://elasticsearch:9200/_security/user/kibana_system/_password -d "{\"password\":\"${KIBANA_SYSTEM_PASSWORD}\"}"

echo "All done!"
