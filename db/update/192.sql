ALTER TABLE iptv_channels ADD COLUMN `channel_price_month` varchar(10) NOT NULL DEFAULT '0';
ALTER TABLE iptv_channels ADD COLUMN `channel_price_day` varchar(10) NOT NULL DEFAULT '0';

