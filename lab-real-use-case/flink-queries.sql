-- Flink SQL Queries for the Vehicle Monitoring Application
-- Run these queries in the Confluent Cloud Flink SQL Workspace

-- Step 1: Verify topics are available as tables
SHOW TABLES;

-- Step 2: Inspect the schema of the vehicle-positions table
DESCRIBE `vehicle-positions`;

-- Step 3: Enable upsert mode for dimension tables (required for temporal joins)
ALTER TABLE `vehicle-vehicleinfo`
SET ('changelog.mode' = 'upsert');

ALTER TABLE `vehicle-driverinfo`
SET ('changelog.mode' = 'upsert');

-- Step 4: Create table to join vehicle positions with vehicle information
CREATE TABLE `vehicle-info-driver-id`
WITH (
  'key.format'  = 'raw',
  'kafka.consumer.isolation-level'='read-uncommitted'
  )
AS SELECT
    p.`key` AS `key`,
    p.`vehicle_id`,
    v.`make`,
    v.`model`,
    v.`plate`,
    p.`driver_id`,
    p.`$rowtime` AS `event_time`
FROM `vehicle-positions` p
JOIN `vehicle-vehicleinfo` FOR SYSTEM_TIME AS OF p.`$rowtime` AS v
    ON p.`key` = v.`key`;

-- Step 5: Create table to count speed limit violations per driver (80 km/h = 22.22 m/s)
CREATE TABLE `vehicle-speed-exceeded-count` (
  PRIMARY KEY (`key`) NOT ENFORCED
)
WITH (
  'changelog.mode' = 'upsert',
  'key.format'  = 'raw',
  'kafka.consumer.isolation-level'='read-uncommitted'
  )
AS SELECT
    CAST(`driver_id` AS VARBINARY) AS `key`,
    COUNT(*) AS `speed_exceeded_count`
FROM `vehicle-positions`
WHERE `speed` > 22.22
GROUP BY `driver_id`;

-- Step 6: Create table joining positions with sensors data
-- Note: This is an interval join between two streams (no primary key required on source)
CREATE TABLE `vehicle-positions-sensors` (
  PRIMARY KEY (`key`) NOT ENFORCED
)
WITH (
  'key.format'  = 'raw',
  'kafka.consumer.isolation-level'='read-uncommitted'
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
FROM `vehicle-positions` p, `vehicle-sensors` s
WHERE p.`key` = s.`key`
AND p.`$rowtime` = s.`$rowtime`;

-- Step 7: Create table enriching with driver information
CREATE TABLE `vehicle-info-driver-info` (
  PRIMARY KEY (`key`) NOT ENFORCED
)
WITH (
  'changelog.mode' = 'upsert',
  'key.format'  = 'raw',
  'kafka.consumer.isolation-level'='read-uncommitted'
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
FROM `vehicle-info-driver-id` p
JOIN `vehicle-driverinfo` FOR SYSTEM_TIME AS OF p.`$rowtime` AS d
    ON p.`key` = d.`key`;

-- Step 8: Create table joining speed exceeded count with driver information
CREATE TABLE `vehicle-driver-speed-exceeded-count` (
  PRIMARY KEY (`key`) NOT ENFORCED
)
WITH (
  'changelog.mode' = 'upsert',
  'key.format'  = 'raw',
  'kafka.consumer.isolation-level'='read-uncommitted'
  )
AS SELECT
    s.`key` AS `key`,
    d.`firstname`,
    d.`lastname`,
    s.`speed_exceeded_count`
FROM `vehicle-speed-exceeded-count` s
JOIN `vehicle-driverinfo` d
ON s.`key` = d.`key`;

-- Step 9: Create main output table combining all vehicle data
CREATE TABLE `vehicle-all-data` (
  PRIMARY KEY (`key`) NOT ENFORCED
)
WITH (
  'key.format'  = 'raw',
  'kafka.consumer.isolation-level'='read-uncommitted'
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
FROM `vehicle-positions-sensors` p
JOIN `vehicle-vehicleinfo` FOR SYSTEM_TIME AS OF p.`$rowtime` AS v
    ON p.`key` = v.`key`;

-- ============================================
-- Inspection Queries (run after creating tables)
-- ============================================

-- View current driver for a specific vehicle
SELECT
  `vehicle_id`,
  `make`,
  `model`,
  `plate`,
  `firstname` AS `current_driver_firstname`,
  `lastname` AS `current_driver_lastname`
FROM `vehicle-info-driver-info`
WHERE CAST(`key` AS STRING) = '23';

-- Check speed limit violations per driver
SELECT
  CAST(`key` AS STRING) AS `driver_id`,
  `firstname`,
  `lastname`,
  `speed_exceeded_count`
FROM `vehicle-driver-speed-exceeded-count`;

-- View complete vehicle data
SELECT * FROM `vehicle-all-data` LIMIT 1;
