SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for nas_statuses
-- ----------------------------
DROP TABLE IF EXISTS `nas_statuses`;
CREATE TABLE `nas_statuses` (
  `ip_address` varchar(15) NOT NULL,
  `status` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`ip_address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

SET FOREIGN_KEY_CHECKS = 1;
