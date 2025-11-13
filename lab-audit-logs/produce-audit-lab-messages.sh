#!/bin/bash

#####################################################################
# Audit Logs Lab - Produce Messages Script
# 
# This script:
# - Verifies topic "topic-for-audit-lab" exists
# - Produces 10 JSON messages to the topic
# - Captures timestamps for Metrics API queries
# - Updates query.json with cluster ID and timestamps
#
# Prerequisites:
# 1. setup-audit-lab-env-cluster.sh must be run first
# 2. Topic "topic-for-audit-lab" must be created in UI
#####################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${GREEN}===================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}===================================${NC}\n"
}

# Function to get current UTC timestamp
get_utc_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Check if summary file exists
if [ ! -f "audit-lab-summary.txt" ]; then
    print_error "audit-lab-summary.txt not found!"
    print_error "Please run setup-audit-lab-env-cluster.sh first"
    exit 1
fi

# Extract cluster ID from summary file
CLUSTER_ID=$(grep "ID:" audit-lab-summary.txt | grep "lkc-" | awk '{print $NF}')

if [ -z "$CLUSTER_ID" ]; then
    print_error "Could not find cluster ID in audit-lab-summary.txt"
    exit 1
fi

print_info "Using cluster: ${CLUSTER_ID}"

# Check if user is logged in
print_info "Checking Confluent Cloud authentication..."
if ! confluent environment list &> /dev/null; then
    print_error "Not logged in to Confluent Cloud. Please run: confluent login"
    exit 1
fi

# Use the cluster
confluent kafka cluster use ${CLUSTER_ID}

#####################################################################
# STEP 1: Verify Topic Exists
#####################################################################
print_step "STEP 1: Verifying Topic Exists"

TOPIC_NAME="topic-for-audit-lab"
print_info "Checking if topic exists: ${TOPIC_NAME}"

if ! confluent kafka topic describe ${TOPIC_NAME} &> /dev/null; then
    print_error "Topic '${TOPIC_NAME}' does not exist!"
    print_error ""
    print_error "Please create the topic in Confluent Cloud UI first:"
    print_error "1. Go to Confluent Cloud Console"
    print_error "2. Navigate to your cluster"
    print_error "3. Click 'Topics' → 'Create topic'"
    print_error "4. Name: ${TOPIC_NAME}"
    print_error "5. Partitions: 6"
    print_error "6. Click 'Create with defaults'"
    exit 1
fi

print_success "Topic '${TOPIC_NAME}' exists!"

# Get topic details
TOPIC_PARTITIONS=$(confluent kafka topic describe ${TOPIC_NAME} -o json | jq -r '.partitions_count' 2>/dev/null || echo "6")
print_info "Topic partitions: ${TOPIC_PARTITIONS}"

#####################################################################
# STEP 2: Produce Messages to Topic
#####################################################################
print_step "STEP 2: Producing Messages to Topic"

print_info "Capturing UTC timestamp for Metrics API query..."

# Capture timestamp BEFORE producing
TIMESTAMP_START=$(get_utc_timestamp)
print_success "Start timestamp (UTC): ${TIMESTAMP_START}"

print_info "Producing 10 messages to topic: ${TOPIC_NAME}"

# Create temporary message file
TEMP_MSG_FILE=$(mktemp)
for i in {1..10}; do
    echo "{\"message_id\": $i, \"content\": \"Audit log test message $i\", \"timestamp\": \"$(get_utc_timestamp)\"}"
done > ${TEMP_MSG_FILE}

# Produce messages
cat ${TEMP_MSG_FILE} | confluent kafka topic produce ${TOPIC_NAME} &> /dev/null

# Clean up temp file
rm -f ${TEMP_MSG_FILE}

# Capture timestamp AFTER producing
sleep 2
TIMESTAMP_END=$(get_utc_timestamp)
print_success "End timestamp (UTC): ${TIMESTAMP_END}"

print_success "10 messages produced successfully"

# Calculate interval for query.json (round to nearest minute, add 10 min window)
if command -v date &> /dev/null; then
    START_DATE=$(echo ${TIMESTAMP_START} | cut -d'T' -f1)
    START_HOUR=$(echo ${TIMESTAMP_START} | cut -d'T' -f2 | cut -d':' -f1)
    START_MIN=$(echo ${TIMESTAMP_START} | cut -d':' -f2)
    INTERVAL_START="${START_DATE}T${START_HOUR}:${START_MIN}:00Z"
    
    # Add 10 minutes for the end interval
    # Force decimal interpretation to avoid octal errors with leading zeros
    END_MIN=$((10#$START_MIN + 10))
    END_HOUR=$((10#$START_HOUR))
    if [ $END_MIN -ge 60 ]; then
        END_MIN=$((END_MIN - 60))
        END_HOUR=$((10#$START_HOUR + 1))
    fi
    INTERVAL_END=$(printf "%sT%02d:%02d:00Z" "$START_DATE" "$END_HOUR" "$END_MIN")
else
    INTERVAL_START="${TIMESTAMP_START}"
    INTERVAL_END="${TIMESTAMP_END}"
fi

# Wait for metrics to be recorded
print_info "Waiting for metrics to be recorded..."
sleep 10

#####################################################################
# STEP 3: Update query.json File
#####################################################################
print_step "STEP 3: Updating query.json File"

print_info "Updating query.json with cluster ID and timestamps..."

# Create a backup of the original file
if [ ! -f "query.json.backup" ]; then
    cp query.json query.json.backup 2>/dev/null || true
fi

# Update query.json with the correct values
cat > query.json << EOF
{
    "aggregations": [
        {
            "metric": "io.confluent.kafka.server/received_bytes"
        }
    ],
    "filter": {
        "field": "resource.kafka.id",
        "op": "EQ",
        "value": "${CLUSTER_ID}"
    },
    "granularity": "PT1M",
    "group_by": [
        "metric.topic"
    ],
    "intervals": [
        "${INTERVAL_START}/${INTERVAL_END}"
    ]
}
EOF

print_success "Updated query.json with:"
print_success "  Cluster ID: ${CLUSTER_ID}"
print_success "  Interval: ${INTERVAL_START}/${INTERVAL_END}"

#####################################################################
# STEP 4: Update Summary File
#####################################################################
print_step "STEP 4: Updating Summary File"

print_info "Updating audit-lab-summary.txt..."
cat >> audit-lab-summary.txt << EOF

========================================
MESSAGES PRODUCED
========================================

Topic: ${TOPIC_NAME}
Partitions: ${TOPIC_PARTITIONS}
Messages: 10
Status: Complete

Timestamps for Metrics API Query:
  Start: ${TIMESTAMP_START}
  End: ${TIMESTAMP_END}

For query.json (Step 50):
  "intervals": ["${INTERVAL_START}/${INTERVAL_END}"]
  
  NOTE: query.json has been automatically updated with:
  - Cluster ID: ${CLUSTER_ID}
  - Interval: ${INTERVAL_START}/${INTERVAL_END}
  
  You can proceed directly to Step 52 (run the query).

Audit Log Events to Search For:
  1. kafka.CreateTopics (resource: ${TOPIC_NAME}) - from UI creation
  2. kafka.Produce (messages to ${TOPIC_NAME}) - from this script
  3. Authentication events (API key usage)

========================================
EOF

print_success "Updated audit-lab-summary.txt"

#####################################################################
# SUMMARY
#####################################################################
print_step "SETUP COMPLETE - PART 2 of 2"

echo ""
echo "========================================="
echo "   AUDIT LOGS LAB - MESSAGES PRODUCED   "
echo "========================================="
echo ""
echo "Topic: ${TOPIC_NAME}"
echo "Messages: 10 (produced successfully)"
echo ""
echo "Timestamps for Metrics API Query:"
echo "  Start: ${TIMESTAMP_START}"
echo "  End: ${TIMESTAMP_END}"
echo ""
echo "For query.json (Step 50):"
echo "  \"intervals\": [\"${INTERVAL_START}/${INTERVAL_END}\"]"
echo "  (Already configured in query.json)"
echo ""
echo "========================================="
echo "         NEXT STEPS (IMPORTANT!)        "
echo "========================================="
echo ""
echo "1. WAIT 1-2 MINUTES"
echo "   Audit log events need time to propagate"
echo ""
echo "2. CONSUME AUDIT LOGS"
echo "   Follow the lab instructions to consume"
echo "   and filter audit log events"
echo ""
echo "3. SEARCH FOR EVENTS:"
echo "   - kafka.CreateTopics (${TOPIC_NAME})"
echo "   - kafka.Produce (${TOPIC_NAME})"
echo ""
echo "========================================="
echo ""
print_success "All information saved in: audit-lab-summary.txt"
print_info "Generated/Updated files:"
print_info "  - audit-lab-summary.txt"
print_info "  - query.json"
echo ""

