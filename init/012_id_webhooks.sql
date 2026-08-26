-- 012_id_webhooks.sql
--
-- The integration channel between id and the applications under the parent
-- domain. Each app's session is its own, so a revocation at id only means
-- something if the apps are told — these tables are how id tells them, and
-- how it knows whether anyone is listening.
--
-- Canonical copy; id also creates these idempotently at boot (ensureSchema).

USE id_db;

-- ─── Registered / discovered applications ────────────────────────────────────
-- A row appears one of two ways: the app self-registers its receiver
-- endpoint (dtRegistered set), or id notices it redeeming handoff codes and
-- records the origin unprompted (dtDiscovered only). The second is what
-- lets the dashboard name an app that does login but never listens for
-- revocations, with nobody maintaining a list by hand.
CREATE TABLE IF NOT EXISTS id_tbl_App (
  sOrigin              VARCHAR(255) PRIMARY KEY,
  sName                VARCHAR(128) NULL,
  sWebhookUrl          VARCHAR(1024) NULL,
  sSecret              CHAR(64) NULL,
  dtDiscovered         DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  dtRegistered         DATETIME(3) NULL,
  dtLastTokenExchange  DATETIME(3) NULL,
  dtLastDeliveryOk     DATETIME(3) NULL,
  dtLastDeliveryFail   DATETIME(3) NULL,
  sLastError           VARCHAR(512) NULL,
  iConsecutiveFailures INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- ─── Event log ───────────────────────────────────────────────────────────────
-- Durable and ordered: an app down past the retry schedule catches up from
-- iEventId at boot rather than silently missing a revocation.
CREATE TABLE IF NOT EXISTS id_tbl_Event (
  iEventId  BIGINT AUTO_INCREMENT PRIMARY KEY,
  sType     VARCHAR(64) NOT NULL,
  jsonData  JSON NOT NULL,
  dtCreated DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  INDEX idx_event_created (dtCreated)
) ENGINE=InnoDB;

-- ─── Delivery attempts ───────────────────────────────────────────────────────
-- One row per (event, app), retried with backoff by id's ticker. Durable so
-- a restart mid-retry resumes instead of dropping the event.
CREATE TABLE IF NOT EXISTS id_tbl_Delivery (
  iDeliveryId   BIGINT AUTO_INCREMENT PRIMARY KEY,
  iEventId      BIGINT NOT NULL,
  sOrigin       VARCHAR(255) NOT NULL,
  iAttempts     INT NOT NULL DEFAULT 0,
  dtNextAttempt DATETIME(3) NULL,
  dtDelivered   DATETIME(3) NULL,
  dtAbandoned   DATETIME(3) NULL,
  sLastError    VARCHAR(512) NULL,
  dtCreated     DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX uq_event_app (iEventId, sOrigin),
  INDEX idx_delivery_due (dtNextAttempt),
  CONSTRAINT fk_delivery_event
    FOREIGN KEY (iEventId) REFERENCES id_tbl_Event(iEventId) ON DELETE CASCADE
) ENGINE=InnoDB;
