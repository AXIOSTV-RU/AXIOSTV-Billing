ALTER TABLE users_pi ADD COLUMN `pasport_series` varchar(4) NOT NULL DEFAULT '0000';
ALTER TABLE users_pi ADD COLUMN `pasport_number` varchar(6) NOT NULL DEFAULT '000000';
ALTER TABLE users_pi ADD COLUMN `pasport_code` TEXT NOT NULL;
