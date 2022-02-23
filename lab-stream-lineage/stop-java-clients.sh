#!/bin/bash

echo "---- Stopping Java clients ----"
echo " "

PIDs=($(ps -ax | grep lab-stream-lineage | awk '{print $1}'))

for i in "${PIDs[@]::${#PIDs[@]}-1}"
do
   kill "$i"
done

echo "Done! Java clients stopped."
