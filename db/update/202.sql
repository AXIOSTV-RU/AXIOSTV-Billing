ALTER TABLE `users` ADD COLUMN `is_company` BOOL NOT NULL DEFAULT false AFTER `company_id`;
ALTER TABLE `users_pi` ADD COLUMN `company_name` VARCHAR(100) NOT NULL DEFAULT '' AFTER `fio3`;
ALTER TABLE `users_pi` ADD COLUMN `inn` BIGINT(12) UNSIGNED NOT NULL DEFAULT 0 AFTER `company_name`;
ALTER TABLE `users_pi` ADD COLUMN `kpp` INT(9) UNSIGNED NOT NULL DEFAULT 0 AFTER `inn`;
ALTER TABLE `users_pi` ADD COLUMN `ogrn` BIGINT(13) UNSIGNED NOT NULL DEFAULT 0 AFTER `kpp`;
ALTER TABLE `users_pi` ADD COLUMN `okpo` VARCHAR(8) NOT NULL DEFAULT '' AFTER `ogrn`;
ALTER TABLE `users_pi` ADD COLUMN `bank_bic` VARCHAR(10) NOT NULL DEFAULT '' AFTER `okpo`;
ALTER TABLE `users_pi` ADD COLUMN `bank_name` VARCHAR(150) NOT NULL DEFAULT '' AFTER `bank_bic`;
ALTER TABLE `users_pi` ADD COLUMN `bank_account` VARCHAR(25) NOT NULL DEFAULT '' AFTER `bank_name`;
ALTER TABLE `users_pi` ADD COLUMN `cor_bank_account` VARCHAR(25) NOT NULL DEFAULT '' AFTER `bank_account`;
ALTER TABLE `SPECTECH_ABONENT` CHANGE COLUMN `COMPANY_ID` `IS_COMPANY` BOOL NOT NULL DEFAULT false;
ALTER TABLE `MFISOFT_ABONENT` CHANGE COLUMN `COMPANY_ID` `IS_COMPANY` BOOL NOT NULL DEFAULT false;
ALTER TABLE `CITADEL_ABONENT` CHANGE COLUMN `COMPANY_ID` `IS_COMPANY` BOOL NOT NULL DEFAULT false;
ALTER TABLE `SORM_ABONENT` CHANGE COLUMN `COMPANY_ID` `IS_COMPANY` BOOL NOT NULL DEFAULT false;
ALTER TABLE `NORSI_ABONENT` CHANGE COLUMN `COMPANY_ID` `IS_COMPANY` BOOL NOT NULL DEFAULT false;

UPDATE `users` SET `is_company` = true WHERE `company_id` > 0;
UPDATE `users_pi` pi
  INNER JOIN `users` u ON u.uid = pi.uid
  INNER JOIN `companies` c ON c.id = u.company_id
SET pi.`company_name` = c.`name`,
    pi.`inn` = c.`tax_number`,
    pi.`kpp` = c.`kpp`,
    pi.`ogrn` = c.`ogrn`,
    pi.`okpo` = c.`okpo`,
    pi.`bank_bic` = c.`bank_bic`,
    pi.`bank_name` = c.`bank_name`,
    pi.`bank_account` = c.`bank_account`,
    pi.`cor_bank_account` = c.`cor_bank_account`
WHERE u.`company_id` > 0;

UPDATE `admin_settings`
SET `setting` = CASE
  WHEN `setting` = 'LOGIN' THEN 'LOGIN, COMPANY_NAME'
  WHEN `setting` LIKE 'LOGIN, %' THEN CONCAT('LOGIN, COMPANY_NAME, ', SUBSTRING(`setting`, 8))
  WHEN `setting` LIKE '%, LOGIN, %' THEN CONCAT(SUBSTRING_INDEX(`setting`, ', LOGIN, ', 1), ', LOGIN, COMPANY_NAME, ', SUBSTRING_INDEX(`setting`, ', LOGIN, ', -1))
  WHEN `setting` LIKE '%, LOGIN' THEN CONCAT(SUBSTRING_INDEX(`setting`, ', LOGIN', 1), ', LOGIN, COMPANY_NAME')
  ELSE CONCAT('COMPANY_NAME, ', `setting`)
END
WHERE `object` = 'USERS_LIST'
  AND `setting` NOT REGEXP '(^|, *)COMPANY_NAME(,|$)';

DROP TABLE IF EXISTS `companie_admins`;
DROP TABLE IF EXISTS `companies`;

ALTER TABLE `users`
  DROP KEY `company_id`,
  DROP COLUMN `company_id`;
