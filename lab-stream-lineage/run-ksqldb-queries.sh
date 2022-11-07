#!/bin/bash

echo "---- Running ksqlDB queries ----"
echo " "

ksql -u $KSQLDB_API_KEY -p $KSQLDB_API_SECRET $KSQLDB_ENDPOINT <<EOF
CREATE STREAM customer_csv_stream (first_name STRING, last_name STRING, email STRING, date STRING, country STRING) WITH (KAFKA_TOPIC='customer-info-csv', VALUE_FORMAT='DELIMITED')\;
CREATE STREAM customer_json_stream WITH (VALUE_FORMAT='JSON', KAFKA_TOPIC='customer-info-json') AS SELECT  *  FROM customer_csv_stream EMIT CHANGES\;
CREATE STREAM orders_stream (ordertime BIGINT, orderid BIGINT, itemid STRING, orderunits double, address STRUCT<city STRING, state STRING, zipcode INT>) WITH (KAFKA_TOPIC='orders', VALUE_FORMAT='JSON')\;
CREATE STREAM filtered_orders_stream WITH (KAFKA_TOPIC='filtered-orders') AS SELECT orderid, itemid, orderunits FROM orders_stream WHERE orderunits > 8\;
EOF

echo " "
echo "Done!"

