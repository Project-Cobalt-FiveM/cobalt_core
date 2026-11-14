CREATE TABLE IF NOT EXISTS `players` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `cid` INT DEFAULT NULL,
  `license` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `phone_number` VARCHAR(20) DEFAULT NULL,
  `money` JSON NOT NULL,
  `charinfo` JSON DEFAULT NULL,
  `position` JSON DEFAULT NULL,
  `metadata` JSON NOT NULL,
  `inventory` LONGTEXT DEFAULT NULL,
  `last_updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `lastname` VARCHAR(255) GENERATED ALWAYS AS (JSON_VALUE(`charinfo`, '$.lastname')) STORED,
  `fullname` VARCHAR(255) GENERATED ALWAYS AS (CONCAT_WS(' ', JSON_VALUE(`charinfo`, '$.firstname'), JSON_VALUE(`charinfo`, '$.lastname'))) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid` (`citizenid`),
  UNIQUE KEY `phone_number` (`phone_number`),
  KEY `license` (`license`),
  KEY `lastname` (`lastname`),
  KEY `fullname` (`fullname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `state_ids` (
  `state_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `license` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`state_id`),
  UNIQUE KEY `license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bans` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) DEFAULT NULL,
  `license` VARCHAR(255) DEFAULT NULL,
  `discord` VARCHAR(255) DEFAULT NULL,
  `steam` VARCHAR(255) DEFAULT NULL,
  `ip` VARCHAR(64) DEFAULT NULL,
  `reason` TEXT DEFAULT NULL,
  `expire` BIGINT DEFAULT NULL,
  `bannedby` VARCHAR(255) NOT NULL DEFAULT 'LeBanhammer',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `license` (`license`),
  KEY `discord` (`discord`),
  KEY `steam` (`steam`),
  KEY `ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `player_vehicles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `license` VARCHAR(255) DEFAULT NULL,
  `citizenid` VARCHAR(50) DEFAULT NULL,
  `vehicle` VARCHAR(50) DEFAULT NULL,
  `hash` VARCHAR(50) DEFAULT NULL,
  `mods` JSON DEFAULT NULL,
  `plate` VARCHAR(15) NOT NULL,
  `fakeplate` VARCHAR(15) DEFAULT NULL,
  `garage` VARCHAR(50) DEFAULT NULL,
  `fuel` INT DEFAULT 100,
  `engine` FLOAT DEFAULT 1000,
  `body` FLOAT DEFAULT 1000,
  `state` INT DEFAULT 1,
  `depotprice` INT NOT NULL DEFAULT 0,
  `drivingdistance` INT DEFAULT NULL,
  `status` JSON DEFAULT NULL,
  `trunk` LONGTEXT DEFAULT NULL,
  `glovebox` LONGTEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate` (`plate`),
  KEY `citizenid` (`citizenid`),
  KEY `license` (`license`),
  KEY `vehicle` (`vehicle`),
  KEY `garage_state` (`garage`, `state`),
  KEY `state` (`state`),
  CONSTRAINT `player_vehicles_citizenid_fk` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
