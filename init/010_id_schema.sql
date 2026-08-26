-- 010_id_schema.sql
--
-- Identity data for the `id` app (id.<parent-domain>) — the OAuth identity
-- processor every application under the parent domain delegates login to.
-- This is the canonical schema; the app also runs an identical idempotent
-- ensureSchema() at boot so a fresh database works in any start order.
--
-- Note 009_id_and_nocodb_databases.sh creates id_db and grants access.

USE id_db;

-- ─── Users (humans, domain-wide) ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS id_tbl_User (
  iUserId     BIGINT AUTO_INCREMENT PRIMARY KEY,
  email       VARCHAR(255) NULL,
  displayName VARCHAR(255) NULL,
  dtCreated   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  dtLastLogin DATETIME(3) NULL,
  INDEX idx_email (email)
) ENGINE=InnoDB;

-- ─── Identities (login methods per user) ─────────────────────────────────────
-- provider is VARCHAR, not ENUM: adding a provider must not need DDL.
-- subject = the provider's stable id (Google/Entra OIDC `sub`; UISP CRM clientId).
CREATE TABLE IF NOT EXISTS id_tbl_Identity (
  iIdentityId BIGINT AUTO_INCREMENT PRIMARY KEY,
  iUserId     BIGINT NOT NULL,
  provider    VARCHAR(32)  NOT NULL,
  subject     VARCHAR(255) NOT NULL,
  email       VARCHAR(255) NULL,
  dtCreated   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX uq_provider_subject (provider, subject),
  CONSTRAINT fk_id_identity_user
    FOREIGN KEY (iUserId) REFERENCES id_tbl_User(iUserId) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ─── Sessions ────────────────────────────────────────────────────────────────
-- No expiry column: a session persists forever and ends only when revoked
-- (logout, logout-everywhere, or an admin). Validity = dtRevoked IS NULL.
CREATE TABLE IF NOT EXISTS id_tbl_Session (
  sSessionId   CHAR(64) PRIMARY KEY,
  iUserId      BIGINT NOT NULL,
  bSuperAdmin  TINYINT(1) NOT NULL DEFAULT 0,
  sProvider    VARCHAR(32) NULL,
  sSubject     VARCHAR(255) NULL,
  dtCreated    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  dtLastSeen   DATETIME(3) NULL,
  dtRevoked    DATETIME(3) NULL,
  INDEX idx_session_user (iUserId),
  CONSTRAINT fk_id_session_user
    FOREIGN KEY (iUserId) REFERENCES id_tbl_User(iUserId) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ─── One-time handoff codes ──────────────────────────────────────────────────
-- Minted when id redirects back to an application; redeemed once at
-- POST /api/token, bound to the exact redirect_uri they were minted for.
CREATE TABLE IF NOT EXISTS id_tbl_AuthCode (
  sCode        CHAR(64) PRIMARY KEY,
  iUserId      BIGINT NOT NULL,
  sRedirectUri VARCHAR(1024) NOT NULL,
  sProvider    VARCHAR(32) NULL,
  sSubject     VARCHAR(255) NULL,
  bSuperAdmin  TINYINT(1) NOT NULL DEFAULT 0,
  dtExpires    DATETIME(3) NOT NULL,
  dtConsumed   DATETIME(3) NULL,
  dtCreated    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  INDEX idx_code_expires (dtExpires),
  CONSTRAINT fk_id_code_user
    FOREIGN KEY (iUserId) REFERENCES id_tbl_User(iUserId) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ─── UISP bridge nonces (replay guard) ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS id_tbl_SsoNonce (
  sNonce    CHAR(32) PRIMARY KEY,
  dtExpires DATETIME(3) NOT NULL,
  dtCreated DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  INDEX idx_nonce_expires (dtExpires)
) ENGINE=InnoDB;
