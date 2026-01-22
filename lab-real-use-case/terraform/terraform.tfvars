# Confluent Cloud API Key (create with: confluent api-key create --resource cloud)
confluent_cloud_api_key    = "<CLOUD_API_KEY>"
confluent_cloud_api_secret = "<CLOUD_API_SECRET>"

# Flink API Key (create with: confluent api-key create --resource flink --cloud aws --region <region> --environment <env-ID>)
flink_api_key              = "<FLINK_API_KEY>"
flink_api_secret           = "<FLINK_API_SECRET>"

# Environment ID (get with: confluent environment list)
environment_id             = "<env-ID>"

# Flink Compute Pool ID (get with: confluent flink compute-pool list)
compute_pool_id            = "<pool-ID>"

# Service Account ID - the principal that will own the Flink statements
# Create with: confluent iam service-account create sa-flink-terraform --description "..."
# Then grant roles: confluent iam rbac role-binding create --principal User:<sa-ID> --role FlinkDeveloper --environment <env-ID>
service_account_id         = "<sa-flink-ID>"

# Cloud provider - must be UPPERCASE (from: confluent flink compute-pool list)
cloud                      = "AWS"

# Region where Flink compute pool is running (from: confluent flink compute-pool list)
region                     = "<region>"

# Kafka cluster name (default: "Vehicle Monitoring")
kafka_cluster_name         = "Vehicle Monitoring"
