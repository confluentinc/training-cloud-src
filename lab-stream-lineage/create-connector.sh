#!/bin/bash

if grep "CONNECTOR_ID" /home/training/.bashrc >/dev/null; then
  echo "Already done!"
  exit 0
fi

echo "---- Creating connector ----"
echo " "

if [ -f ./connector-config.json ]; then
  rm connector-config.json
fi

cat <<EOT >> ./connector-config.json
{
    "name" : "UserOrdersConnector",
    "connector.class": "DatagenSource",
    "kafka.auth.mode": "KAFKA_API_KEY",
    "kafka.api.key": "$API_KEY",
    "kafka.api.secret" : "$API_SECRET",
    "kafka.topic" : "orders",
    "output.data.format" : "JSON",
    "json.output.decimal.format": "NUMERIC",
    "quickstart" : "ORDERS",
    "tasks.max" : "1"
}
EOT


CONNECTOR_ID=$(confluent connect cluster create --config-file connector-config.json | grep -o 'lcc[^ ]\+')

cat <<EOT >> /home/training/.bashrc
export CONNECTOR_ID=$CONNECTOR_ID
EOT

echo "Done! Connector created with ID: $CONNECTOR_ID"