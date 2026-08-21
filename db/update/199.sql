ALTER TABLE users_pi ADD COLUMN doc_type_id int(2) UNSIGNED AFTER citizenship;
ALTER TABLE users_pi ADD COLUMN doc_description varchar(20) NOT NULL DEFAULT '' AFTER doc_type_id;

