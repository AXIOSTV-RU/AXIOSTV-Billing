ALTER TABLE companies ADD COLUMN `address_flat_alt` varchar(40) NOT NULL DEFAULT '';
ALTER TABLE companies MODIFY COLUMN `address_flat_alt` varchar(40) NOT NULL DEFAULT '' AFTER address_flat;
