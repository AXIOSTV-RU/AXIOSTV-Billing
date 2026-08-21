ALTER TABLE `internet_online` DROP INDEX IF EXISTS `framed_ip_address`;
ALTER TABLE `internet_online` ADD UNIQUE KEY `framed_ip_address` (`framed_ip_address`);
