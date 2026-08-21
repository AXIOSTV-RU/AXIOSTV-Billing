ALTER TABLE nas ADD COLUMN `accident_check` tinyint(1) NOT NULL DEFAULT 0;
ALTER TABLE nas ADD COLUMN `check_count` int(11) NOT NULL DEFAULT 0;
ALTER TABLE accident_log MODIFY descr VARCHAR(1000);
