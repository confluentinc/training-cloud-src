#!/bin/bash

#####################################################################
# Cluster Linking Infrastructure Setup Script
# 
# This script automates the creation of:
# - Source and Destination environments
# - Source (Basic/Standard) and Destination (Dedicated) clusters
# - Service accounts for clients and cluster linking
# - API keys with appropriate ACLs
# - Configuration files for clients
#####################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
# STEP 1: Create Source Environment
#####################################################################
print_step "STEP 1: Creating Source Environment"

# Check if source-env environment already exists
SOURCE_ENV_NAME="source-env"
print_info "Checking for existing '${SOURCE_ENV_NAME}' environment..."

SOURCE_ENV_ID=$(confluent environment list -o json | jq -r ".[] | select(.name==\"${SOURCE_ENV_NAME}\") | .id" | head -1)

if [ -z "$SOURCE_ENV_ID" ]; then
    print_info "Creating source environment: ${SOURCE_ENV_NAME}"
    SOURCE_ENV_ID=$(confluent environment create ${SOURCE_ENV_NAME} --governance-package essentials -o json | jq -r '.id')
    print_success "Created source environment: ${SOURCE_ENV_ID}"
else
    print_warning "Source environment '${SOURCE_ENV_NAME}' already exists: ${SOURCE_ENV_ID}"
fi

confluent environment use ${SOURCE_ENV_ID}
print_success "Using source environment: ${SOURCE_ENV_ID}"

#####################################################################
# STEP 2: Create Destination Environment
#####################################################################
print_step "STEP 2: Creating Destination Environment"

DEST_ENV_NAME="destination-env"
print_info "Checking for existing '${DEST_ENV_NAME}' environment..."

DEST_ENV_ID=$(confluent environment list -o json | jq -r ".[] | select(.name==\"${DEST_ENV_NAME}\") | .id" | head -1)

if [ -z "$DEST_ENV_ID" ]; then
    print_info "Creating destination environment: ${DEST_ENV_NAME}"
    DEST_ENV_ID=$(confluent environment create ${DEST_ENV_NAME} --governance-package essentials -o json | jq -r '.id')
    print_success "Created destination environment: ${DEST_ENV_ID}"
else
    print_warning "Destination environment '${DEST_ENV_NAME}' already exists: ${DEST_ENV_ID}"
fi

print_success "Destination environment ID: ${DEST_ENV_ID}"

#####################################################################
# STEP 3: Create Source Cluster (Basic)
#####################################################################
print_step "STEP 3: Creating Source Cluster"

confluent environment use ${SOURCE_ENV_ID}

SOURCE_CLUSTER_NAME="source-cluster"
print_info "Checking for existing source cluster..."

SOURCE_CLUSTER_ID=$(confluent kafka cluster list -o json | jq -r ".[] | select(.name==\"${SOURCE_CLUSTER_NAME}\") | .id" | head -1)

if [ -z "$SOURCE_CLUSTER_ID" ]; then
    print_info "Creating source cluster (Basic): ${SOURCE_CLUSTER_NAME}"
    print_info "Cloud: Azure | Region: Germany West Central (Frankfurt)"
    print_info "This may take a few minutes..."
    
    # Source cluster: Azure Frankfurt
    SOURCE_CLOUD="azure"
    SOURCE_REGION="germanywestcentral"
    
    SOURCE_CLUSTER_ID=$(confluent kafka cluster create ${SOURCE_CLUSTER_NAME} \
        --cloud ${SOURCE_CLOUD} \
        --region ${SOURCE_REGION} \
        --type basic \
        -o json | jq -r '.id')
    
    print_success "Created source cluster: ${SOURCE_CLUSTER_ID}"
    
    # Wait for cluster to be ready
    print_info "Waiting for source cluster to be ready..."
    sleep 30
    while true; do
        STATUS=$(confluent kafka cluster describe ${SOURCE_CLUSTER_ID} -o json | jq -r '.status')
        if [ "$STATUS" == "UP" ]; then
            break
        fi
        print_info "Cluster status: ${STATUS}. Waiting..."
        sleep 10
    done
    print_success "Source cluster is UP"
else
    print_warning "Source cluster already exists: ${SOURCE_CLUSTER_ID}"
fi

# Get source cluster bootstrap server
SOURCE_BOOTSTRAP=$(confluent kafka cluster describe ${SOURCE_CLUSTER_ID} -o json | jq -r '.endpoint' | sed 's/SASL_SSL:\/\///')
print_success "Source Bootstrap Server: ${SOURCE_BOOTSTRAP}"

#####################################################################
# STEP 4: Create Destination Cluster (Dedicated)
#####################################################################
print_step "STEP 4: Creating Destination Cluster"

confluent environment use ${DEST_ENV_ID}

DEST_CLUSTER_NAME="destination-cluster"
print_info "Checking for existing destination cluster..."

DEST_CLUSTER_ID=$(confluent kafka cluster list -o json | jq -r ".[] | select(.name==\"${DEST_CLUSTER_NAME}\") | .id" | head -1)

if [ -z "$DEST_CLUSTER_ID" ]; then
    print_info "Creating destination cluster (Dedicated 1 CKU): ${DEST_CLUSTER_NAME}"
    print_info "Cloud: AWS | Region: US East 2 (Ohio)"
    print_info "This may take several minutes (5-10 minutes)..."
    
    # Destination cluster: AWS Ohio
    DEST_CLOUD="aws"
    DEST_REGION="us-east-2"
    
    DEST_CLUSTER_ID=$(confluent kafka cluster create ${DEST_CLUSTER_NAME} \
        --cloud ${DEST_CLOUD} \
        --region ${DEST_REGION} \
        --type dedicated \
        --cku 1 \
        --availability single-zone \
        -o json | jq -r '.id')
    
    print_success "Created destination cluster: ${DEST_CLUSTER_ID}"
    
    # Wait for cluster to be ready
    print_info "Waiting for destination cluster to be ready (this takes 5-10 minutes)..."
    sleep 60
    while true; do
        STATUS=$(confluent kafka cluster describe ${DEST_CLUSTER_ID} -o json 2>/dev/null | jq -r '.status')
        if [ "$STATUS" == "UP" ]; then
            break
        fi
        print_info "Cluster status: ${STATUS}. Waiting..."
        sleep 30
    done
    print_success "Destination cluster is UP"
else
    print_warning "Destination cluster already exists: ${DEST_CLUSTER_ID}"
fi

# Get destination cluster bootstrap server
DEST_BOOTSTRAP=$(confluent kafka cluster describe ${DEST_CLUSTER_ID} -o json | jq -r '.endpoint' | sed 's/SASL_SSL:\/\///')
print_success "Destination Bootstrap Server: ${DEST_BOOTSTRAP}"

#####################################################################
# STEP 5: Create Topic in Source Cluster
#####################################################################
print_step "STEP 5: Creating Topic in Source Cluster"

confluent environment use ${SOURCE_ENV_ID}
confluent kafka cluster use ${SOURCE_CLUSTER_ID}

TOPIC_NAME="courier-positions"
print_info "Checking for existing topic: ${TOPIC_NAME}"

if confluent kafka topic describe ${TOPIC_NAME} &> /dev/null; then
    print_warning "Topic '${TOPIC_NAME}' already exists"
else
    print_info "Creating topic: ${TOPIC_NAME}"
    confluent kafka topic create ${TOPIC_NAME} --partitions 1
    print_success "Created topic: ${TOPIC_NAME}"
fi

#####################################################################
# STEP 6: Create Service Account for Clients
#####################################################################
print_step "STEP 6: Creating Service Account for Clients"

SA_CLIENTS_NAME="sa-cluster-linking-clients"
print_info "Checking for existing service account: ${SA_CLIENTS_NAME}"

SA_CLIENTS_ID=$(confluent iam service-account list -o json | jq -r ".[] | select(.name==\"${SA_CLIENTS_NAME}\") | .id" | head -1)

if [ -z "$SA_CLIENTS_ID" ]; then
    print_info "Creating service account: ${SA_CLIENTS_NAME}"
    SA_CLIENTS_ID=$(confluent iam service-account create ${SA_CLIENTS_NAME} \
        --description "Service Account for the producer and consumer in the Cluster Linking lab" \
        -o json | jq -r '.id')
    print_success "Created service account: ${SA_CLIENTS_ID}"
else
    print_warning "Service account already exists: ${SA_CLIENTS_ID}"
fi

#####################################################################
# STEP 7: Create API Keys for Source Cluster Clients
#####################################################################
print_step "STEP 7: Creating API Keys for Source Cluster"

confluent environment use ${SOURCE_ENV_ID}
confluent kafka cluster use ${SOURCE_CLUSTER_ID}

print_info "Creating API key for source cluster clients..."
SOURCE_API_KEY_OUTPUT=$(confluent api-key create --resource ${SOURCE_CLUSTER_ID} --service-account ${SA_CLIENTS_ID} -o json)
SOURCE_API_KEY=$(echo ${SOURCE_API_KEY_OUTPUT} | jq -r '.api_key')
SOURCE_API_SECRET=$(echo ${SOURCE_API_KEY_OUTPUT} | jq -r '.api_secret')

if [ -z "$SOURCE_API_KEY" ] || [ "$SOURCE_API_KEY" == "null" ]; then
    print_error "Failed to create API key for source cluster"
    echo "Output: ${SOURCE_API_KEY_OUTPUT}"
    exit 1
fi

print_success "Created API Key: ${SOURCE_API_KEY}"
print_info "Waiting for API key to be ready..."
sleep 10

# Apply ACLs for source cluster
print_info "Applying ACLs for source cluster clients..."

# ACL for consumer group
confluent kafka acl create \
    --allow \
    --service-account ${SA_CLIENTS_ID} \
    --operations READ \
    --consumer-group "courier-" \
    --prefix \
    --cluster ${SOURCE_CLUSTER_ID}

# ACL for topic READ
confluent kafka acl create \
    --allow \
    --service-account ${SA_CLIENTS_ID} \
    --operations READ \
    --topic ${TOPIC_NAME} \
    --cluster ${SOURCE_CLUSTER_ID}

# ACL for topic WRITE
confluent kafka acl create \
    --allow \
    --service-account ${SA_CLIENTS_ID} \
    --operations WRITE \
    --topic ${TOPIC_NAME} \
    --cluster ${SOURCE_CLUSTER_ID}

print_success "Applied ACLs for source cluster"

#####################################################################
# STEP 8: Create API Keys for Destination Cluster Clients
#####################################################################
print_step "STEP 8: Creating API Keys for Destination Cluster"

confluent environment use ${DEST_ENV_ID}
confluent kafka cluster use ${DEST_CLUSTER_ID}

print_info "Creating API key for destination cluster clients..."
DEST_API_KEY_OUTPUT=$(confluent api-key create --resource ${DEST_CLUSTER_ID} --service-account ${SA_CLIENTS_ID} -o json)
DEST_API_KEY=$(echo ${DEST_API_KEY_OUTPUT} | jq -r '.api_key')
DEST_API_SECRET=$(echo ${DEST_API_KEY_OUTPUT} | jq -r '.api_secret')

if [ -z "$DEST_API_KEY" ] || [ "$DEST_API_KEY" == "null" ]; then
    print_error "Failed to create API key for destination cluster"
    echo "Output: ${DEST_API_KEY_OUTPUT}"
    exit 1
fi

print_success "Created API Key: ${DEST_API_KEY}"
print_info "Waiting for API key to be ready..."
sleep 10

# Apply ACLs for destination cluster
print_info "Applying ACLs for destination cluster clients..."

# ACL for consumer group
confluent kafka acl create \
    --allow \
    --service-account ${SA_CLIENTS_ID} \
    --operations READ \
    --consumer-group "courier-" \
    --prefix \
    --cluster ${DEST_CLUSTER_ID}

# ACL for topic READ
confluent kafka acl create \
    --allow \
    --service-account ${SA_CLIENTS_ID} \
    --operations READ \
    --topic ${TOPIC_NAME} \
    --cluster ${DEST_CLUSTER_ID}

# ACL for topic WRITE
confluent kafka acl create \
    --allow \
    --service-account ${SA_CLIENTS_ID} \
    --operations WRITE \
    --topic ${TOPIC_NAME} \
    --cluster ${DEST_CLUSTER_ID}

print_success "Applied ACLs for destination cluster"

#####################################################################
# STEP 9: Create Service Account for Cluster Link
#####################################################################
print_step "STEP 9: Creating Service Account for Cluster Link"

SA_LINK_NAME="sa-cluster-link"
print_info "Checking for existing service account: ${SA_LINK_NAME}"

SA_LINK_ID=$(confluent iam service-account list -o json | jq -r ".[] | select(.name==\"${SA_LINK_NAME}\") | .id" | head -1)

if [ -z "$SA_LINK_ID" ]; then
    print_info "Creating service account: ${SA_LINK_NAME}"
    SA_LINK_ID=$(confluent iam service-account create ${SA_LINK_NAME} \
        --description "Service Account for the cluster link in Cluster Linking lab" \
        -o json | jq -r '.id')
    print_success "Created service account: ${SA_LINK_ID}"
else
    print_warning "Service account already exists: ${SA_LINK_ID}"
fi

#####################################################################
# STEP 10: Create API Key for Cluster Link (Source)
#####################################################################
print_step "STEP 10: Creating API Key for Cluster Link"

confluent environment use ${SOURCE_ENV_ID}
confluent kafka cluster use ${SOURCE_CLUSTER_ID}

print_info "Creating API key for cluster link..."
LINK_API_KEY_OUTPUT=$(confluent api-key create --resource ${SOURCE_CLUSTER_ID} --service-account ${SA_LINK_ID} -o json)
LINK_API_KEY=$(echo ${LINK_API_KEY_OUTPUT} | jq -r '.api_key')
LINK_API_SECRET=$(echo ${LINK_API_KEY_OUTPUT} | jq -r '.api_secret')

if [ -z "$LINK_API_KEY" ] || [ "$LINK_API_KEY" == "null" ]; then
    print_error "Failed to create API key for cluster link"
    echo "Output: ${LINK_API_KEY_OUTPUT}"
    exit 1
fi

print_success "Created API Key: ${LINK_API_KEY}"
print_info "Waiting for API key to be ready..."
sleep 10

# Apply ACLs for cluster link
print_info "Applying ACLs for cluster link..."

# ACL for topic READ and DESCRIBE_CONFIGS
confluent kafka acl create \
    --allow \
    --service-account ${SA_LINK_ID} \
    --operations READ,DESCRIBE_CONFIGS \
    --topic ${TOPIC_NAME} \
    --cluster ${SOURCE_CLUSTER_ID}

# ACL for topic DESCRIBE
confluent kafka acl create \
    --allow \
    --service-account ${SA_LINK_ID} \
    --operations DESCRIBE \
    --topic ${TOPIC_NAME} \
    --cluster ${SOURCE_CLUSTER_ID}

# ACL for consumer group READ and DESCRIBE
confluent kafka acl create \
    --allow \
    --service-account ${SA_LINK_ID} \
    --operations READ,DESCRIBE \
    --consumer-group "courier-" \
    --prefix \
    --cluster ${SOURCE_CLUSTER_ID}

print_success "Applied ACLs for cluster link"

#####################################################################
# STEP 11: Generate Configuration Files
#####################################################################
print_step "STEP 11: Generating Configuration Files"

# Generate SOURCE-java-client.config
print_info "Generating SOURCE-java-client.config..."
cat > SOURCE-java-client.config << EOF
bootstrap.servers=${SOURCE_BOOTSTRAP}
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule   required username='${SOURCE_API_KEY}'   password='${SOURCE_API_SECRET}';
EOF
print_success "Created SOURCE-java-client.config"

# Generate DESTINATION-java-client.config
print_info "Generating DESTINATION-java-client.config..."
cat > DESTINATION-java-client.config << EOF
bootstrap.servers=${DEST_BOOTSTRAP}
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule   required username='${DEST_API_KEY}'   password='${DEST_API_SECRET}';
EOF
print_success "Created DESTINATION-java-client.config"

# Generate environment variables file
print_info "Generating cluster-linking-env.sh (environment variables)..."
cat > cluster-linking-env.sh << EOF
#!/bin/bash
# Cluster Linking Lab - Environment Variables
# Source this file: source cluster-linking-env.sh

export SOURCE_ENV_ID="${SOURCE_ENV_ID}"
export DEST_ENV_ID="${DEST_ENV_ID}"
export SOURCE_CLUSTER_ID="${SOURCE_CLUSTER_ID}"
export DEST_CLUSTER_ID="${DEST_CLUSTER_ID}"
export SOURCE_BOOTSTRAP="${SOURCE_BOOTSTRAP}"
export DEST_BOOTSTRAP="${DEST_BOOTSTRAP}"
export SA_CLIENTS_ID="${SA_CLIENTS_ID}"
export SA_LINK_ID="${SA_LINK_ID}"
export LINK_API_KEY="${LINK_API_KEY}"
export LINK_API_SECRET="${LINK_API_SECRET}"
export TOPIC_NAME="${TOPIC_NAME}"

echo "Environment variables loaded for Cluster Linking lab"
echo "Source Cluster: \${SOURCE_CLUSTER_ID}"
echo "Destination Cluster: \${DEST_CLUSTER_ID}"
EOF
chmod +x cluster-linking-env.sh
print_success "Created cluster-linking-env.sh"

#####################################################################
# SUMMARY
#####################################################################
print_step "SETUP COMPLETE!"

echo ""
echo "========================================="
echo "         INFRASTRUCTURE SUMMARY          "
echo "========================================="
echo ""
echo "Source Environment:"
echo "  Name: ${SOURCE_ENV_NAME}"
echo "  ID: ${SOURCE_ENV_ID}"
echo ""
echo "Destination Environment:"
echo "  Name: ${DEST_ENV_NAME}"
echo "  ID: ${DEST_ENV_ID}"
echo ""
echo "Source Cluster:"
echo "  Name: ${SOURCE_CLUSTER_NAME}"
echo "  ID: ${SOURCE_CLUSTER_ID}"
echo "  Bootstrap: ${SOURCE_BOOTSTRAP}"
echo ""
echo "Destination Cluster:"
echo "  Name: ${DEST_CLUSTER_NAME}"
echo "  ID: ${DEST_CLUSTER_ID}"
echo "  Bootstrap: ${DEST_BOOTSTRAP}"
echo ""
echo "Topic: ${TOPIC_NAME} (created in source cluster)"
echo ""
echo "Service Accounts:"
echo "  Clients: ${SA_CLIENTS_ID}"
echo "  Cluster Link: ${SA_LINK_ID}"
echo ""
echo "Generated Files:"
echo "  - SOURCE-java-client.config"
echo "  - DESTINATION-java-client.config"
echo "  - cluster-linking-env.sh"
echo ""
echo "========================================="
echo ""
print_success "You can now proceed with the Cluster Linking lab!"
print_info "To use environment variables in your terminal:"
echo "  $ source cluster-linking-env.sh"
echo ""

