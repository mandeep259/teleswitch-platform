USE kamailio;

CREATE TABLE IF NOT EXISTS dispatcher (
  id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  setid INT(11) NOT NULL DEFAULT 0,
  destination VARCHAR(192) NOT NULL DEFAULT '',
  flags INT(11) NOT NULL DEFAULT 0,
  priority INT(11) NOT NULL DEFAULT 0,
  attrs VARCHAR(128) NOT NULL DEFAULT '',
  description VARCHAR(64) NOT NULL DEFAULT ''
);

CREATE INDEX dispatcher_setid_idx ON dispatcher(setid);
