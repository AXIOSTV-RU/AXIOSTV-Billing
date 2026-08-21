SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for accident_notifications
-- ----------------------------
DROP TABLE IF EXISTS `accident_notifications`;
CREATE TABLE `accident_notifications` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `accident_id` int(11) NOT NULL,
  `uid` int(11) NOT NULL,
  `notify_type` varchar(10) NOT NULL,
  `sent_time` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `accident_id` (`accident_id`,`uid`,`notify_type`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Accident - лог отосланных аварий абонентам';

SET FOREIGN_KEY_CHECKS = 1;

ALTER TABLE accident_equipments MODIFY date datetime DEFAULT current_timestamp();
ALTER TABLE accident_equipments MODIFY end_date datetime DEFAULT '0000-00-00 00:00:00';

