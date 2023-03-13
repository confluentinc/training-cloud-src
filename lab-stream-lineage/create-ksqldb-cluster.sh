#!/bin/bash

if grep "KSQLDB_ID" /home/training/.bashrc >/dev/null; then
  echo "Already done!"
  exit 0
fi

echo "---- Creating ksqlDB cluster ----"
echo "It may take a few minutes to provision resources to the new ksqlDB cluster."
echo " "

ksqldb_response=$(confluent ksql cluster create convert-format-app --credential-identity $USER_ACCOUNT_ID --csu 1)

KSQLDB_ID=$(echo "$ksqldb_response" | grep ID | awk '{print $4}')

echo "Creating new API key and secret to access the new ksqlDB cluster..."
ksqldb_api_response=$(confluent api-key create --resource $KSQLDB_ID)

cat <<EOT >> /home/training/.bashrc
export KSQLDB_ID=$(echo "$ksqldb_response" | grep ID | awk '{print $4}')
export KSQLDB_ENDPOINT=$(echo "$ksqldb_response" | grep Endpoint | awk '{print $4}')
export KSQLDB_API_KEY=$(echo "$ksqldb_api_response" | grep "API Key" | awk '{print $5}')
export KSQLDB_API_SECRET=$(echo "$ksqldb_api_response" | grep "Secret" | awk '{print $5}')
EOT

echo " "
echo "Done! ksqlDB environment variables have been stored."