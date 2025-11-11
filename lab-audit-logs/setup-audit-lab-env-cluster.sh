#!/bin/bash

#####################################################################
# Audit Logs Lab - Environment & Cluster Setup Script
# 
# This script creates:
# - Lab-env environment
# - cluster_lab Standard Kafka cluster (AWS us-west-2)
# - API key for cluster access
#
# After running this script, students will:
# 1. Manually create topic "topic-for-audit-lab" in the UI
# 2. Run the produce-audit-lab-messages.sh script
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

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    print_error "jq is not installed. Please install it first."
    print_info "Ubuntu/Debian: sudo apt-get install jq"
    print_info "macOS: brew install jq"
    print_info "RHEL/CentOS: sudo yum install jq"
    exit 1
fi

# Check if confluent CLI is installed
if ! command -v confluent &> /dev/null; then
    print_error "Confluent CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is logged in
print_info "Checking Confluent Cloud authentication..."
if ! confluent environment list &> /dev/null; then
    print_error "Not logged in to Confluent Cloud. Please run: confluent login"
    exit 1
fi

print_success "Authenticated to Confluent Cloud"

#####################################################################
# STEP 1: Create Lab Environment
#####################################################################
print_step "STEP 1: Creating Lab Environment"

LAB_ENV_NAME="Lab-env"
print_info "Checking for existing '${LAB_ENV_NAME}' environment..."

LAB_ENV_ID=$(confluent environment list -o json | jq -r ".[] | select(.name==\"${LAB_ENV_NAME}\") | .id" 2>/dev/null | head -1)

if [ -z "$LAB_ENV_ID" ]; then
    print_info "Creating lab environment: ${LAB_ENV_NAME}"
    LAB_ENV_ID=$(confluent environment create ${LAB_ENV_NAME} -o json | jq -r '.id')
    
    if [ -z "$LAB_ENV_ID" ] || [ "$LAB_ENV_ID" == "null" ]; then
        print_error "Failed to create environment"
        exit 1
    fi
    
    print_success "Created lab environment: ${LAB_ENV_ID}"
else
    print_warning "Lab environment '${LAB_ENV_NAME}' already exists: ${LAB_ENV_ID}"
    read -p "Do you want to use this existing environment? (yes/no): " USE_EXISTING
    if [ "$USE_EXISTING" != "yes" ]; then
        print_error "Please delete the existing environment first or choose a different name"
        exit 1
    fi
fi

confluent environment use ${LAB_ENV_ID}
print_success "Using lab environment: ${LAB_ENV_ID}"

#####################################################################
# STEP 2: Create Standard Kafka Cluster
#####################################################################
print_step "STEP 2: Creating Standard Kafka Cluster"

CLUSTER_NAME="cluster_lab"
print_info "Checking for existing cluster: ${CLUSTER_NAME}"

CLUSTER_ID=$(confluent kafka cluster list -o json | jq -r ".[] | select(.name==\"${CLUSTER_NAME}\") | .id" 2>/dev/null | head -1)

if [ -z "$CLUSTER_ID" ]; then
    print_info "Creating Standard cluster: ${CLUSTER_NAME}"
    print_info "Cloud: AWS | Region: us-west-2"
    print_info "This may take 1-2 minutes..."
    
    CLUSTER_CLOUD="aws"
    CLUSTER_REGION="us-west-2"
    
    CLUSTER_ID=$(confluent kafka cluster create ${CLUSTER_NAME} \
        --cloud ${CLUSTER_CLOUD} \
        --region ${CLUSTER_REGION} \
        --type standard \
        -o json | jq -r '.id')
    
    if [ -z "$CLUSTER_ID" ] || [ "$CLUSTER_ID" == "null" ]; then
        print_error "Failed to create cluster"
        exit 1
    fi
    
    print_success "Created cluster: ${CLUSTER_ID}"
    
    # Wait for cluster to be ready
    print_info "Waiting for cluster to be ready..."
    sleep 30
    while true; do
        STATUS=$(confluent kafka cluster describe ${CLUSTER_ID} -o json 2>/dev/null | jq -r '.status')
        if [ "$STATUS" == "UP" ]; then
            break
        fi
        print_info "Cluster status: ${STATUS}. Waiting..."
        sleep 15
    done
    
    print_success "Cluster is ready!"
else
    print_warning "Cluster '${CLUSTER_NAME}' already exists: ${CLUSTER_ID}"
fi

confluent kafka cluster use ${CLUSTER_ID}

# Get bootstrap server
BOOTSTRAP_SERVER=$(confluent kafka cluster describe ${CLUSTER_ID} -o json | jq -r '.endpoint' | sed 's/SASL_SSL:\/\///')
print_success "Bootstrap server: ${BOOTSTRAP_SERVER}"

#####################################################################
# STEP 3: Create API Key for Cluster
#####################################################################
print_step "STEP 3: Creating API Key"

# Verify we're using the correct cluster
CURRENT_CLUSTER=$(confluent kafka cluster describe -o json 2>/dev/null | jq -r '.id' 2>/dev/null)
if [ "$CURRENT_CLUSTER" != "$CLUSTER_ID" ]; then
    print_warning "Current cluster context doesn't match. Setting context..."
    confluent kafka cluster use ${CLUSTER_ID}
fi

print_info "Creating API key for cluster: ${CLUSTER_ID}"

# Create API key and capture output
API_KEY_OUTPUT=$(confluent api-key create --resource ${CLUSTER_ID} -o json 2>&1)
API_KEY_EXIT_CODE=$?

# Debug: Show raw output if there's an error
if [ $API_KEY_EXIT_CODE -ne 0 ]; then
    print_error "API key creation failed with exit code: ${API_KEY_EXIT_CODE}"
    print_error "Output: ${API_KEY_OUTPUT}"
    exit 1
fi

# Parse JSON output (note: CLI returns api_key/api_secret, not key/secret)
API_KEY=$(echo ${API_KEY_OUTPUT} | jq -r '.api_key' 2>/dev/null)
API_SECRET=$(echo ${API_KEY_OUTPUT} | jq -r '.api_secret' 2>/dev/null)

# Validate API key was created
if [ -z "$API_KEY" ] || [ "$API_KEY" == "null" ]; then
    print_error "Failed to parse API key from output"
    print_error "Raw output: ${API_KEY_OUTPUT}"
    exit 1
fi

print_success "Created API Key: ${API_KEY}"
print_info "API Secret: ${API_SECRET} (save this securely!)"

# Use the API key
confluent api-key use ${API_KEY} --resource ${CLUSTER_ID}
print_success "API key is active"

#####################################################################
# STEP 4: Generate Summary File
#####################################################################
print_step "STEP 4: Generating Summary File"

print_info "Creating audit-lab-summary.txt..."
cat > audit-lab-summary.txt << EOF
========================================
AUDIT LOGS LAB - INFRASTRUCTURE SUMMARY
========================================

Environment:
  Name: ${LAB_ENV_NAME}
  ID: ${LAB_ENV_ID}

Cluster:
  Name: ${CLUSTER_NAME}
  ID: ${CLUSTER_ID}
  Bootstrap Server: ${BOOTSTRAP_SERVER}

API Key:
  Key: ${API_KEY}
  Secret: ${API_SECRET}
  (IMPORTANT: Save this secret securely!)

========================================
NEXT STEPS
========================================

1. Create Topic in Confluent Cloud UI:
   - Go to Confluent Cloud Console
   - Navigate to your cluster: ${CLUSTER_NAME}
   - Click "Topics" → "Create topic"
   - Topic name: topic-for-audit-lab
   - Partitions: 6
   - Click "Create with defaults"

2. After creating the topic, run:
   ./produce-audit-lab-messages.sh

3. Wait 1-2 minutes for audit log events to propagate

4. Then proceed with the lab exercises to consume audit logs

========================================
EOF

print_success "Created audit-lab-summary.txt"

#####################################################################
# SUMMARY
#####################################################################
print_step "SETUP COMPLETE - PART 1 of 2"

echo ""
echo "========================================="
echo " AUDIT LOGS LAB - INFRASTRUCTURE READY  "
echo "========================================="
echo ""
echo "Environment: ${LAB_ENV_NAME} (${LAB_ENV_ID})"
echo "Cluster: ${CLUSTER_NAME} (${CLUSTER_ID})"
echo "Bootstrap: ${BOOTSTRAP_SERVER}"
echo "API Key: ${API_KEY}"
echo ""
echo "========================================="
echo "         NEXT STEPS (IMPORTANT!)        "
echo "========================================="
echo ""
echo "1. CREATE TOPIC IN UI:"
echo "   - Open Confluent Cloud Console"
echo "   - Go to cluster: ${CLUSTER_NAME}"
echo "   - Topics → Create topic"
echo "   - Name: topic-for-audit-lab"
echo "   - Partitions: 6"
echo ""
echo "2. AFTER CREATING TOPIC, RUN:"
echo "   ./produce-audit-lab-messages.sh"
echo ""
echo "3. Wait 1-2 minutes for audit logs"
echo ""
echo "4. Continue with lab exercises"
echo ""
echo "========================================="
echo ""
print_success "All information saved in: audit-lab-summary.txt"
echo ""

