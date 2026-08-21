ALTER TABLE users_pi ADD COLUMN `place_of_birth` varchar(255) NOT NULL DEFAULT '';
ALTER TABLE `users_pi` MODIFY COLUMN `pasport_grant` VARCHAR(255) NOT NULL DEFAULT '';
ALTER TABLE users_pi MODIFY COLUMN `place_of_birth` varchar(255) NOT NULL DEFAULT '' AFTER birth_date;
