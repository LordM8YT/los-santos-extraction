CREATE DATABASE IF NOT EXISTS `los_santos_extraction`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `los_santos_extraction`;

CREATE TABLE IF NOT EXISTS `lsx_players` (
    `identifier` varchar(80) NOT NULL,
    `inventory` longtext DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT current_timestamp(),
    `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`identifier`)
);

CREATE TABLE IF NOT EXISTS `lsx_vehicles` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `plate` varchar(12) DEFAULT NULL,
    `glovebox` longtext DEFAULT NULL,
    `trunk` longtext DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `plate` (`plate`)
);

CREATE TABLE IF NOT EXISTS `ox_inventory` (
    `owner` varchar(60) DEFAULT NULL,
    `name` varchar(100) NOT NULL,
    `data` longtext DEFAULT NULL,
    `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    UNIQUE KEY `owner` (`owner`, `name`)
);
