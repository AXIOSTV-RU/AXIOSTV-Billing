CREATE TABLE IF NOT EXISTS `building_statuses` (
  `id`         SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`       VARCHAR(50) NOT NULL DEFAULT '',
  `is_default` TINYINT(1)  UNSIGNED  NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8mb4
  COMMENT = 'Build statuses';

REPLACE INTO `building_statuses` (`id`, `name`, `is_default`) VALUES (1, '$lang{ENABLE}', 1), (2, '$lang{PLANNED_TO_CONNECT}', 0), (3, '$lang{CLOSED}', 0);
ALTER TABLE `builds` ADD COLUMN `status_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1;

ALTER TABLE `crm_competitor_geolocation` ADD KEY `competitor_id` (`competitor_id`);
ALTER TABLE `crm_competitor_geolocation` ADD KEY `district_id` (`district_id`);
ALTER TABLE `crm_competitor_geolocation` ADD KEY `street_id` (`street_id`);
ALTER TABLE `crm_competitor_geolocation` ADD KEY `build_id` (`build_id`);

ALTER TABLE `crm_competitor_tps_geolocation` ADD KEY `tp_id` (`tp_id`);
ALTER TABLE `crm_competitor_tps_geolocation` ADD KEY `district_id` (`district_id`);
ALTER TABLE `crm_competitor_tps_geolocation` ADD KEY `street_id` (`street_id`);
ALTER TABLE `crm_competitor_tps_geolocation` ADD KEY `build_id` (`build_id`);

ALTER TABLE `crm_leads` ADD COLUMN `floor` SMALLINT(3) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `crm_leads` ADD COLUMN `entrance` SMALLINT(3) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE `abon_tariffs` ADD COLUMN `hot_deal` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';

CREATE TABLE IF NOT EXISTS `portal_attachments`
(
  `id`                INT(10)     UNSIGNED NOT NULL AUTO_INCREMENT,
  `filename`          VARCHAR(255)         NOT NULL DEFAULT '',
  `file_type`         VARCHAR(50)          NOT NULL DEFAULT '',
  `file_size`         INT(10)     UNSIGNED NOT NULL DEFAULT 0,
  `uploaded_at`       TIMESTAMP            NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8mb4
  COMMENT = 'Portal attachments';


REPLACE INTO `crm_progressbar_steps` (`id`, `step_number`, `name`, `color`, `description`) VALUE
  ('1', '1', '$lang{NEW_LEAD}', '#5479e7', ''),
  ('2', '2', '$lang{CONTRACT_SIGNED}', '#25d2f1', ''),
  ('3', '3', '$lang{THE_WORKS}', '#ff8000', ''),
  ('4', '4', '$lang{CONVERSION}', '#f1233d', '');

REPLACE INTO `crm_leads_sources` (`id`, `name`, `comments`) VALUE
  ('1', '$lang{PHONE}', ''),
  ('2', 'E-mail', ''),
  ('3', '$lang{SOCIAL_NETWORKS}', ''),
  ('4', '$lang{REFERRALS}', '');

CREATE TABLE IF NOT EXISTS `crm_attachments` (
  `id`           INT(10)     UNSIGNED  NOT NULL AUTO_INCREMENT,
  `filename`     VARCHAR(255)          NOT NULL DEFAULT '',
  `file_size`    INT(10)      UNSIGNED NOT NULL DEFAULT 0,
  `content_type` VARCHAR(50)           NOT NULL DEFAULT '',
  `uploaded_at`  TIMESTAMP             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `message_id`   INT          UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8mb4
  COMMENT = 'Crm attachments table';

