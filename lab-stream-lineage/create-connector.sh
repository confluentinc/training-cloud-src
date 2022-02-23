#!/bin/bash

echo "---- Creating connector ----"
echo " "

if [ ! -f ./connector-config.json ]
then
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
fi

CONNECTOR_ID=$(confluent connect create --config connector-config.json | awk '{print $4}')

cat <<EOT >> /home/training/.bashrc
export CONNECTOR_ID=$CONNECTOR_ID
EOT

echo "Done! Connector created with ID: $CONNECTOR_ID"
