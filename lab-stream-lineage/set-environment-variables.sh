#!/bin/bash

if grep "BOOTSTRAP_SERVERS" /home/training/.bashrc >/dev/null; then
  echo "Already done!"
  exit 0
fi

echo "---- Setting Environment Variables ----"
echo " "

CLUSTER_ID=$(confluent kafka cluster list | grep -o 'lkc[^ ]\+')

echo "Creating new API key and secret..."
api_response=$(confluent api-key create --resource $CLUSTER_ID --description "global access - Lab Stream Lineage")

cat <<EOT >> /home/training/.bashrc
export CLUSTER_ID=$(confluent kafka cluster list | grep -o 'lkc[^ ]\+') 
export USER_ACCOUNT_ID=$(confluent iam user list | grep -o 'u-[^ ]\+') 
export API_KEY=$(echo "$api_response" | grep "API Key" | awk '{print $5}')
export API_SECRET=$(echo "$api_response" | grep "Secret" | awk '{print $5}')
export BOOTSTRAP_SERVERS=$(confluent kafka cluster describe | grep -o -P '(?<=SASL_SSL://).*(?=[ \t])')
EOT

echo " "
echo "Done! Environment variables successfully stored."