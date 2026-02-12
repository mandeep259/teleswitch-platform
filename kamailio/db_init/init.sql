-- 1. Create the base Kamailio Database
CREATE DATABASE IF NOT EXISTS kamailio;
USE kamailio;

-- 2. Create the Version Table (Kamailio uses this to verify schema)
CREATE TABLE IF NOT EXISTS version (
    table_name VARCHAR(32) NOT NULL,
    table_version INT UNSIGNED DEFAULT 0 NOT NULL,
    CONSTRAINT table_name_idx UNIQUE (table_name)
);

-- 3. Create the Dispatcher Table (The routing brain)
CREATE TABLE IF NOT EXISTS dispatcher (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    setid INT DEFAULT 0 NOT NULL,
    destination VARCHAR(192) DEFAULT '' NOT NULL,
    flags INT DEFAULT 0 NOT NULL,
    priority INT DEFAULT 0 NOT NULL,
    attrs VARCHAR(128) DEFAULT '' NOT NULL,
    description VARCHAR(64) DEFAULT '' NOT NULL
);

-- 4. Register the table version for Kamailio 5.8+
INSERT INTO version (table_name, table_version) VALUES ('dispatcher', 4)
ON DUPLICATE KEY UPDATE table_version=4;

-- 5. Add FreeSWITCH (teleswitch) to the load balancer
-- setid 1 = Your FreeSWITCH cluster
-- destination = Internal Docker DNS name of your service
INSERT INTO dispatcher (setid, destination, flags, priority, description)
VALUES (1, 'sip:teleswitch:5060', 0, 1, 'Primary FreeSWITCH Media Server');