terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.11.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# Data source for the organization
data "confluent_organization" "main" {}

# Data source for the environment
data "confluent_environment" "iot_team" {
  id = var.environment_id
}

# Data source for the Flink region (to get rest_endpoint)
data "confluent_flink_region" "main" {
  cloud  = var.cloud
  region = var.region
}

# Local variables
locals {
  # Fully qualified prefix for table names: `catalog`.`database`
  fq_prefix = "`${data.confluent_environment.iot_team.display_name}`.`${var.kafka_cluster_name}`"
}

# Statement 1: Enable upsert mode for vehicle-vehicleinfo
resource "confluent_flink_statement" "alter_vehicleinfo" {
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = data.confluent_environment.iot_team.id
  }
  compute_pool {
    id = var.compute_pool_id
  }
  principal {
    id = var.service_account_id
  }
  statement     = "ALTER TABLE ${local.fq_prefix}.`vehicle-vehicleinfo` SET ('changelog.mode' = 'upsert');"
  rest_endpoint = data.confluent_flink_region.main.rest_endpoint
  credentials {
    key    = var.flink_api_key
    secret = var.flink_api_secret
  }
}

# Statement 2: Enable upsert mode for vehicle-driverinfo
resource "confluent_flink_statement" "alter_driverinfo" {
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = data.confluent_environment.iot_team.id
  }
  compute_pool {
    id = var.compute_pool_id
  }
  principal {
    id = var.service_account_id
  }
  statement     = "ALTER TABLE ${local.fq_prefix}.`vehicle-driverinfo` SET ('changelog.mode' = 'upsert');"
  rest_endpoint = data.confluent_flink_region.main.rest_endpoint
  credentials {
    key    = var.flink_api_key
    secret = var.flink_api_secret
  }
  depends_on = [confluent_flink_statement.alter_vehicleinfo]
}

# Statement 3: Create vehicle-info-driver-id table
resource "confluent_flink_statement" "vehicle_info_driver_id" {
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = data.confluent_environment.iot_team.id
  }
  compute_pool {
    id = var.compute_pool_id
  }
  principal {
    id = var.service_account_id
  }
  statement = <<-SQL
    CREATE TABLE ${local.fq_prefix}.`vehicle-info-driver-id`
    WITH (
      'key.format' = 'raw',
      'kafka.consumer.isolation-level' = 'read-uncommitted'
    )
    AS SELECT
        p.`key` AS `key`,
        p.`vehicle_id`,
        v.`make`,
        v.`model`,
        v.`plate`,
        p.`driver_id`,
        p.`$rowtime` AS `event_time`
    FROM ${local.fq_prefix}.`vehicle-positions` p
    JOIN ${local.fq_prefix}.`vehicle-vehicleinfo` FOR SYSTEM_TIME AS OF p.`$rowtime` AS v
        ON p.`key` = v.`key`;
  SQL
  rest_endpoint = data.confluent_flink_region.main.rest_endpoint
  credentials {
    key    = var.flink_api_key
    secret = var.flink_api_secret
  }
  depends_on = [confluent_flink_statement.alter_driverinfo]
}

# Statement 4: Create vehicle-speed-exceeded-count table
resource "confluent_flink_statement" "vehicle_speed_exceeded_count" {
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = data.confluent_environment.iot_team.id
  }
  compute_pool {
    id = var.compute_pool_id
  }
  principal {
    id = var.service_account_id
  }
  statement = <<-SQL
    CREATE TABLE ${local.fq_prefix}.`vehicle-speed-exceeded-count` (
      PRIMARY KEY (`key`) NOT ENFORCED
    )
    WITH (
      'changelog.mode' = 'upsert',
      'key.format' = 'raw',
      'kafka.consumer.isolation-level' = 'read-uncommitted'
    )
    AS SELECT
        CAST(`driver_id` AS VARBINARY) AS `key`,
        COUNT(*) AS `speed_exceeded_count`
    FROM ${local.fq_prefix}.`vehicle-positions`
    WHERE `speed` > 22.22
    GROUP BY `driver_id`;
  SQL
  rest_endpoint = data.confluent_flink_region.main.rest_endpoint
  credentials {
    key    = var.flink_api_key
    secret = var.flink_api_secret
  }
  depends_on = [confluent_flink_statement.vehicle_info_driver_id]
}

# Statement 5: Create vehicle-positions-sensors table
resource "confluent_flink_statement" "vehicle_positions_sensors" {
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = data.confluent_environment.iot_team.id
  }
  compute_pool {
    id = var.compute_pool_id
  }
  principal {
    id = var.service_account_id
  }
  statement = <<-SQL
    CREATE TABLE ${local.fq_prefix}.`vehicle-positions-sensors` (
      PRIMARY KEY (`key`) NOT ENFORCED
    )
    WITH (
      'key.format' = 'raw',
      'kafka.consumer.isolation-level' = 'read-uncommitted'
    )
    AS SELECT
        p.`key` AS `key`,
        p.`vehicle_id`,
        p.`driver_id`,
        p.`latitude`,
        p.`longitude`,
        p.`speed`,
        p.`acceleration`,
        p.`odometer`,
        s.`engine_temperature`,
        s.`average_rpm`,
        s.`pressure_tyre_1`,
        s.`pressure_tyre_2`,
        s.`pressure_tyre_3`,
        s.`pressure_tyre_4`,
        p.`$rowtime` AS `event_time`
    FROM ${local.fq_prefix}.`vehicle-positions` p, ${local.fq_prefix}.`vehicle-sensors` s
    WHERE p.`key` = s.`key`
    AND p.`$rowtime` = s.`$rowtime`;
  SQL
  rest_endpoint = data.confluent_flink_region.main.rest_endpoint
  credentials {
    key    = var.flink_api_key
    secret = var.flink_api_secret
  }
  depends_on = [confluent_flink_statement.vehicle_speed_exceeded_count]
}

# Statement 6: Create vehicle-info-driver-info table
resource "confluent_flink_statement" "vehicle_info_driver_info" {
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = data.confluent_environment.iot_team.id
  }
  compute_pool {
    id = var.compute_pool_id
  }
  principal {
    id = var.service_account_id
  }
  statement = <<-SQL
    CREATE TABLE ${local.fq_prefix}.`vehicle-info-driver-info` (
      PRIMARY KEY (`key`) NOT ENFORCED
    )
    WITH (
      'changelog.mode' = 'upsert',
      'key.format' = 'raw',
      'kafka.consumer.isolation-level' = 'read-uncommitted'
    )
    AS SELECT
        p.`key` AS `key`,
        p.`vehicle_id`,
        p.`make`,
        p.`model`,
        p.`plate`,
        p.`driver_id`,
        d.`firstname`,
        d.`lastname`,
        p.`event_time`
    FROM ${local.fq_prefix}.`vehicle-info-driver-id` p
    JOIN ${local.fq_prefix}.`vehicle-driverinfo` FOR SYSTEM_TIME AS OF p.`$rowtime` AS d
        ON p.`key` = d.`key`;
  SQL
  rest_endpoint = data.confluent_flink_region.main.rest_endpoint
  credentials {
    key    = var.flink_api_key
    secret = var.flink_api_secret
  }
  depends_on = [confluent_flink_statement.vehicle_positions_sensors]
}

# Statement 7: Create vehicle-driver-speed-exceeded-count table
resource "confluent_flink_statement" "vehicle_driver_speed_exceeded_count" {
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = data.confluent_environment.iot_team.id
  }
  compute_pool {
    id = var.compute_pool_id
  }
  principal {
    id = var.service_account_id
  }
  statement = <<-SQL
    CREATE TABLE ${local.fq_prefix}.`vehicle-driver-speed-exceeded-count` (
      PRIMARY KEY (`key`) NOT ENFORCED
    )
    WITH (
      'changelog.mode' = 'upsert',
      'key.format' = 'raw',
      'kafka.consumer.isolation-level'='read-uncommitted'
    )
    AS SELECT
        s.`key` AS `key`,
        d.`firstname`,
        d.`lastname`,
        s.`speed_exceeded_count`
    FROM ${local.fq_prefix}.`vehicle-speed-exceeded-count` s
    JOIN ${local.fq_prefix}.`vehicle-driverinfo` d
        ON s.`key` = d.`key`;
  SQL
  rest_endpoint = data.confluent_flink_region.main.rest_endpoint
  credentials {
    key    = var.flink_api_key
    secret = var.flink_api_secret
  }
  depends_on = [confluent_flink_statement.vehicle_info_driver_info]
}

# Statement 8: Create vehicle-all-data table
# Note: This depends on vehicle_driver_speed_exceeded_count to ensure proper ordering
resource "confluent_flink_statement" "vehicle_all_data" {
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = data.confluent_environment.iot_team.id
  }
  compute_pool {
    id = var.compute_pool_id
  }
  principal {
    id = var.service_account_id
  }
  statement = <<-SQL
    CREATE TABLE ${local.fq_prefix}.`vehicle-all-data` (
      PRIMARY KEY (`key`) NOT ENFORCED
    )
    WITH (
      'key.format' = 'raw',
      'kafka.consumer.isolation-level' = 'read-uncommitted'
    )
    AS SELECT
        p.`key` AS `key`,
        p.`vehicle_id`,
        p.`driver_id`,
        p.`latitude`,
        p.`longitude`,
        p.`speed`,
        p.`acceleration`,
        p.`odometer`,
        p.`engine_temperature`,
        p.`average_rpm`,
        p.`pressure_tyre_1`,
        p.`pressure_tyre_2`,
        p.`pressure_tyre_3`,
        p.`pressure_tyre_4`,
        v.`make`,
        v.`model`,
        v.`plate`,
        v.`regdate` AS `registration_date`,
        p.`event_time`
    FROM ${local.fq_prefix}.`vehicle-positions-sensors` p
    JOIN ${local.fq_prefix}.`vehicle-vehicleinfo` FOR SYSTEM_TIME AS OF p.`$rowtime` AS v
        ON p.`key` = v.`key`;
  SQL
  rest_endpoint = data.confluent_flink_region.main.rest_endpoint
  credentials {
    key    = var.flink_api_key
    secret = var.flink_api_secret
  }
  depends_on = [confluent_flink_statement.vehicle_driver_speed_exceeded_count]
}
