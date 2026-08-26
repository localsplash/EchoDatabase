-- 013_echoweb_id_cursor.sql
--
-- How far EchoWeb has got through id's event log.
--
-- Webhook retries cover a brief outage; an app down longer than the retry
-- schedule would still have a hole. On boot EchoWeb reads forward from this
-- cursor (GET id/api/events?since=) and applies whatever it missed. Single
-- row by construction — iCursorId is always 1.

USE echo_db;

CREATE TABLE IF NOT EXISTS auth_tbl_IdCursor (
  iCursorId    TINYINT UNSIGNED PRIMARY KEY,
  iLastEventId BIGINT NOT NULL DEFAULT 0,
  dtUpdated    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                 ON UPDATE CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB;

INSERT IGNORE INTO auth_tbl_IdCursor (iCursorId, iLastEventId) VALUES (1, 0);
