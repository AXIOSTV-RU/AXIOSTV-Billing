ALTER TABLE users_pi ADD COLUMN `address_flat_alt` varchar(40) NOT NULL DEFAULT '';
ALTER TABLE users_pi MODIFY COLUMN `address_flat_alt` varchar(40) NOT NULL DEFAULT '' AFTER address_flat;
