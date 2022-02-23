#!/bin/bash

echo "---- Creating topics ----"
echo " "

confluent kafka topic create customer-info-csv --partitions 2
confluent kafka topic create customer-info-json --partitions 2
confluent kafka topic create user-position --partitions 4
confluent kafka topic create orders --partitions 4
confluent kafka topic create filtered-orders --partitions 4

echo "Done! Topics created."

