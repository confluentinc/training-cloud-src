variable "confluent_cloud_api_key" {
  type        = string
  description = "Confluent Cloud API Key"
}

variable "confluent_cloud_api_secret" {
  type        = string
  description = "Confluent Cloud API Secret"
  sensitive   = true
}

variable "flink_api_key" {
  type        = string
  description = "Flink API Key"
}

variable "flink_api_secret" {
  type        = string
  description = "Flink API Secret"
  sensitive   = true
}

variable "environment_id" {
  type        = string
  description = "Confluent Cloud Environment ID (e.g., env-xxxxx)"
}

variable "compute_pool_id" {
  type        = string
  description = "Flink Compute Pool ID (e.g., lfcp-xxxxx)"
}

variable "service_account_id" {
  type        = string
  description = "Service Account ID that owns the Flink statements (e.g., sa-xxxxx)"
}

variable "cloud" {
  type        = string
  description = "Cloud provider where Flink compute pool is running (AWS, AZURE, GCP)"
  default     = "AWS"
}

variable "region" {
  type        = string
  description = "Cloud region where Flink compute pool is running (e.g., us-east-1, us-west-2)"
}

variable "kafka_cluster_name" {
  type        = string
  description = "Name of the Kafka cluster (used as database in Flink)"
  default     = "Vehicle Monitoring"
}
