ALTER TABLE companies RENAME COLUMN edrpou TO ogrn;
ALTER TABLE companies ADD COLUMN kpp varchar(12) NOT NULL DEFAULT '' AFTER tax_number;
ALTER TABLE companies ADD COLUMN okpo varchar(8) NOT NULL DEFAULT '' AFTER kpp;
ALTER TABLE companies ADD COLUMN company_email varchar(50) NOT NULL DEFAULT '' AFTER phone;
ALTER TABLE companies MODIFY COLUMN `ogrn` varchar(100) NOT NULL DEFAULT '' AFTER okpo;
ALTER TABLE companies ADD COLUMN resident varchar(1) NOT NULL DEFAULT '1';
