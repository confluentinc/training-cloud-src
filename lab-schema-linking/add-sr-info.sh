#!/bin/bash

if grep "SR_URL" /home/training/.bashrc >/dev/null; then
  echo "Already done!"
  exit 0
fi

echo " "

cat <<EOT >> /home/training/.bashrc
export SR_URL=$SR_URL
export SR_KEY=$SR_KEY
export SR_SECRET=$SR_SECRET
EOT

echo "Schema Registry information added!"