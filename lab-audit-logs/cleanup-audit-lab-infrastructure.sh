#!/bin/bash

#####################################################################
# Audit Logs Lab Cleanup Script
# 
# This script cleans up resources created during the lab:
# - Deletes the Standard Kafka cluster
# - Optionally deletes the Lab-env environment
# - Deletes API keys (if requested)
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
# STEP 1: Find Lab Environment
#####################################################################
print_step "STEP 1: Finding Lab Environment"

LAB_ENV_NAME="Lab-env"
print_info "Looking for environment: ${LAB_ENV_NAME}"

LAB_ENV_ID=$(confluent environment list -o json | jq -r ".[] | select(.name==\"${LAB_ENV_NAME}\") | .id" 2>/dev/null | head -1)

if [ -z "$LAB_ENV_ID" ]; then
    print_error "Environment '${LAB_ENV_NAME}' not found"
    print_info "Cannot proceed with cleanup"
    exit 1
else
    print_success "Found environment: ${LAB_ENV_ID}"
fi

confluent environment use ${LAB_ENV_ID}

#####################################################################
# STEP 2: Find Cluster
#####################################################################
print_step "STEP 2: Finding Cluster"

CLUSTER_NAME="cluster_lab"
print_info "Looking for cluster: ${CLUSTER_NAME}"

CLUSTER_ID=$(confluent kafka cluster list -o json | jq -r ".[] | select(.name==\"${CLUSTER_NAME}\") | .id" 2>/dev/null | head -1)

if [ -z "$CLUSTER_ID" ]; then
    print_warning "Cluster '${CLUSTER_NAME}' not found in environment ${LAB_ENV_ID}"
    print_info "No cluster to delete"
else
    print_success "Found cluster: ${CLUSTER_ID}"
fi

#####################################################################
# STEP 3: Delete Cluster
#####################################################################
if [ -n "$CLUSTER_ID" ]; then
    print_step "STEP 3: Deleting Cluster"
    
    print_info "Deleting cluster: ${CLUSTER_ID}"
    confluent kafka cluster delete ${CLUSTER_ID} --force
    print_success "Cluster deletion initiated"
else
    print_step "STEP 3: Delete Cluster (SKIPPED)"
    print_info "No cluster to delete"
fi

#####################################################################
# STEP 4: Delete Environment
#####################################################################
print_step "STEP 4: Deleting Environment"

print_info "Deleting environment: ${LAB_ENV_ID}"

# Attempt to delete the environment (--force to skip confirmation)
if confluent environment delete ${LAB_ENV_ID} --force 2>/dev/null; then
    print_success "Environment deleted successfully"
else
    print_warning "Environment deletion failed (may have remaining resources)"
    print_info "Environment: ${LAB_ENV_ID}"
fi

#####################################################################
# STEP 5: Clean Up Files
#####################################################################
print_step "STEP 5: Clean Up Generated Files"

# Clean up summary file
if [ -f "audit-lab-summary.txt" ]; then
    rm -f audit-lab-summary.txt
    print_success "Deleted audit-lab-summary.txt"
else
    print_info "No summary file to delete"
fi

# Restore query.json backup if it exists
if [ -f "query.json.backup" ]; then
    mv query.json.backup query.json
    print_success "Restored original query.json"
else
    print_info "No query.json backup to restore"
fi

#####################################################################
# SUMMARY
#####################################################################
print_step "CLEANUP COMPLETE!"

echo ""
echo "========================================="
echo "         CLEANUP SUMMARY                 "
echo "========================================="
echo ""

if [ -n "$CLUSTER_ID" ]; then
    echo "✓ Cluster deletion initiated: ${CLUSTER_ID}"
else
    echo "⊙ No cluster found to delete"
fi

echo "✓ Environment deletion attempted: ${LAB_ENV_ID}"
echo "✓ Generated files cleaned up"
echo ""
echo "Next steps:"
echo "  1. Verify deletion in Confluent Cloud UI"
echo "  2. Check for any remaining API keys (Administration > API Keys)"
echo "  3. Review billing to ensure no unexpected charges"
echo ""
echo "========================================="
echo ""

print_success "Cleanup script completed!"
