#!/bin/bash

#####################################################################
# Cluster Linking Infrastructure Cleanup Script
# 
# This script removes all resources created by the setup script:
# - API keys
# - Service accounts
# - Clusters
# - Environments (optional)
# - Generated configuration files
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
    print_error "Confluent CLI is not installed."
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
# Load Environment Variables (if available)
#####################################################################
if [ -f "cluster-linking-env.sh" ]; then
    print_info "Loading environment variables from cluster-linking-env.sh..."
    source cluster-linking-env.sh
else
    print_warning "cluster-linking-env.sh not found. Will search for resources by name."
fi

print_warning "This script will DELETE the following resources:"
echo "  - Destination cluster (destination-cluster)"
echo "  - Source cluster (source-cluster)"
echo "  - Service accounts (sa-cluster-linking-clients, sa-cluster-link)"
echo "  - All associated API keys"
echo "  - Generated configuration files"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    print_info "Cleanup cancelled."
    exit 0
fi

#####################################################################
# STEP 1: Find Environment IDs
#####################################################################
print_step "STEP 1: Locating Environments"

if [ -z "$SOURCE_ENV_ID" ]; then
    SOURCE_ENV_ID=$(confluent environment list -o json | jq -r '.[] | select(.name=="source-env") | .id' | head -1)
fi

if [ -z "$DEST_ENV_ID" ]; then
    DEST_ENV_ID=$(confluent environment list -o json | jq -r '.[] | select(.name=="destination-env") | .id' | head -1)
fi

if [ -n "$SOURCE_ENV_ID" ]; then
    print_info "Found source environment: ${SOURCE_ENV_ID}"
else
    print_warning "Source environment 'source-env' not found"
fi

if [ -n "$DEST_ENV_ID" ]; then
    print_info "Found destination environment: ${DEST_ENV_ID}"
else
    print_warning "Destination environment 'destination-env' not found"
fi

#####################################################################
# STEP 2: Find Cluster IDs
#####################################################################
print_step "STEP 2: Locating Clusters"

if [ -z "$SOURCE_CLUSTER_ID" ] && [ -n "$SOURCE_ENV_ID" ]; then
    confluent environment use ${SOURCE_ENV_ID}
    SOURCE_CLUSTER_ID=$(confluent kafka cluster list -o json | jq -r '.[] | select(.name=="source-cluster") | .id' | head -1)
fi

if [ -z "$DEST_CLUSTER_ID" ] && [ -n "$DEST_ENV_ID" ]; then
    confluent environment use ${DEST_ENV_ID}
    DEST_CLUSTER_ID=$(confluent kafka cluster list -o json | jq -r '.[] | select(.name=="destination-cluster") | .id' | head -1)
fi

if [ -n "$SOURCE_CLUSTER_ID" ]; then
    print_info "Found source cluster: ${SOURCE_CLUSTER_ID}"
else
    print_warning "Source cluster 'source-cluster' not found"
fi

if [ -n "$DEST_CLUSTER_ID" ]; then
    print_info "Found destination cluster: ${DEST_CLUSTER_ID}"
else
    print_warning "Destination cluster 'destination-cluster' not found"
fi

#####################################################################
# STEP 3: Delete Destination Cluster
#####################################################################
if [ -n "$DEST_CLUSTER_ID" ] && [ -n "$DEST_ENV_ID" ]; then
    print_step "STEP 3: Deleting Destination Cluster"
    confluent environment use ${DEST_ENV_ID}
    
    print_info "Deleting destination cluster: ${DEST_CLUSTER_ID}"
    confluent kafka cluster delete ${DEST_CLUSTER_ID} --force
    print_success "Destination cluster deleted (or deletion initiated)"
else
    print_warning "Skipping destination cluster deletion (not found)"
fi

#####################################################################
# STEP 4: Delete Source Cluster
#####################################################################
if [ -n "$SOURCE_CLUSTER_ID" ] && [ -n "$SOURCE_ENV_ID" ]; then
    print_step "STEP 4: Deleting Source Cluster"
    confluent environment use ${SOURCE_ENV_ID}
    
    print_info "Deleting source cluster: ${SOURCE_CLUSTER_ID}"
    confluent kafka cluster delete ${SOURCE_CLUSTER_ID} --force
    print_success "Source cluster deleted (or deletion initiated)"
else
    print_warning "Skipping source cluster deletion (not found)"
fi

#####################################################################
# STEP 5: Delete Service Accounts
#####################################################################
print_step "STEP 5: Deleting Service Accounts"

# Find and delete sa-cluster-linking-clients
if [ -z "$SA_CLIENTS_ID" ]; then
    SA_CLIENTS_ID=$(confluent iam service-account list -o json | jq -r '.[] | select(.name=="sa-cluster-linking-clients") | .id' | head -1)
fi

if [ -n "$SA_CLIENTS_ID" ]; then
    print_info "Deleting service account: ${SA_CLIENTS_ID}"
    confluent iam service-account delete ${SA_CLIENTS_ID} --force
    print_success "Deleted service account: ${SA_CLIENTS_ID}"
else
    print_warning "Service account 'sa-cluster-linking-clients' not found"
fi

# Find and delete sa-cluster-link
if [ -z "$SA_LINK_ID" ]; then
    SA_LINK_ID=$(confluent iam service-account list -o json | jq -r '.[] | select(.name=="sa-cluster-link") | .id' | head -1)
fi

if [ -n "$SA_LINK_ID" ]; then
    print_info "Deleting service account: ${SA_LINK_ID}"
    confluent iam service-account delete ${SA_LINK_ID} --force
    print_success "Deleted service account: ${SA_LINK_ID}"
else
    print_warning "Service account 'sa-cluster-link' not found"
fi

#####################################################################
# STEP 6: Delete Destination Environment
#####################################################################
if [ -n "$DEST_ENV_ID" ]; then
    print_step "STEP 6: Deleting Destination Environment"
    
    print_info "Deleting destination environment: ${DEST_ENV_ID}"
    if confluent environment delete ${DEST_ENV_ID} --force; then
        print_success "Destination environment deleted"
    else
        print_warning "Could not delete destination environment. It may still have resources."
        print_info "You can delete it manually later via the Confluent Cloud UI."
    fi
fi

#####################################################################
# STEP 7: Delete Source Environment
#####################################################################
if [ -n "$SOURCE_ENV_ID" ]; then
    print_step "STEP 7: Deleting Source Environment"
    
    print_info "Deleting source environment: ${SOURCE_ENV_ID}"
    if confluent environment delete ${SOURCE_ENV_ID} --force; then
        print_success "Source environment deleted"
    else
        print_warning "Could not delete source environment. It may still have resources."
        print_info "You can delete it manually later via the Confluent Cloud UI."
    fi
fi

#####################################################################
# STEP 8: Delete Generated Files
#####################################################################
print_step "STEP 8: Deleting Generated Files"

FILES_TO_DELETE=(
    "SOURCE-java-client.config"
    "DESTINATION-java-client.config"
    "cluster-linking-env.sh"
)

for file in "${FILES_TO_DELETE[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        print_success "Deleted: $file"
    else
        print_info "File not found (already deleted): $file"
    fi
done

#####################################################################
# SUMMARY
#####################################################################
print_step "CLEANUP COMPLETE!"

echo ""
echo "========================================="
echo "         CLEANUP SUMMARY                 "
echo "========================================="
echo ""
echo "The following resources have been deleted:"
echo "  ✓ Destination cluster"
echo "  ✓ Source cluster"
echo "  ✓ Service accounts"
echo "  ✓ Destination environment"
echo "  ✓ Source environment"
echo "  ✓ Generated configuration files"
echo ""
echo "========================================="
echo ""
print_info "Note: Cluster deletions may take a few minutes to complete."
print_info "You can verify the cleanup in the Confluent Cloud UI."
echo ""

