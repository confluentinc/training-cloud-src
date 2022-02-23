#!/bin/bash

echo "---- Starting Java clients ----"
echo " "

cd producer-users
./gradlew run --console plain &

cd ../producer-position
./gradlew run --console plain &

cd ../consumer-orders
./gradlew run --console plain &

cd ../consumer-position
./gradlew run --console plain

