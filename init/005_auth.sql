USE echo_db;

-- ─── Orgs (one per UISP client / business tenant) ────────────────────────────
-- uisp_client_id is the UISP CRM clientId; NULL for orgs not bound to UISP.
-- iBusinessNumber is the Echo/Bandwidth messaging phone number (E.164 as BIGINT).
CREATE TABLE IF NOT EXISTS auth_tbl_Org (
  iOrgId          BIGINT AUTO_INCREMENT PRIMARY KEY,
  uisp_client_id  VARCHAR(64) NULL,
  iBusinessNumber BIGINT NULL,
  displayName     VARCHAR(255) NULL,
  dtCreated       DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX uq_uisp_client     (uisp_client_id),
  INDEX          idx_business_num (iBusinessNumber)
) ENGINE=InnoDB;

-- ─── Users (humans) ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS auth_tbl_User (
  iUserId     BIGINT AUTO_INCREMENT PRIMARY KEY,
  email       VARCHAR(255) NULL,
  displayName VARCHAR(255) NULL,
  dtCreated   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  INDEX idx_email (email)
) ENGINE=InnoDB;

-- ─── Identities (login methods per user) ─────────────────────────────────────
-- provider = 'google' | 'magic_link' | 'uisp'
-- subject  = Google `sub` for google; email for magic_link; CRM clientId for uisp
CREATE TABLE IF NOT EXISTS auth_tbl_Identity (
  iIdentityId BIGINT AUTO_INCREMENT PRIMARY KEY,
  iUserId     BIGINT NOT NULL,
  provider    ENUM('google','magic_link','uisp') NOT NULL,
  subject     VARCHAR(255) NOT NULL,
  email       VARCHAR(255) NULL,
  dtCreated   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX uq_provider_subject (provider, subject),
  CONSTRAINT fk_identity_user
    FOREIGN KEY (iUserId) REFERENCES auth_tbl_User(iUserId) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ─── Memberships (user-to-org associations) ──────────────────────────────────
-- Only role='owner' is created via UISP SSO provisioning.
-- role='admin'|'member' are assigned by the owner via invite flow (future).
CREATE TABLE IF NOT EXISTS auth_tbl_Membership (
  iMembershipId BIGINT AUTO_INCREMENT PRIMARY KEY,
  iUserId       BIGINT NOT NULL,
  iOrgId        BIGINT NOT NULL,
  role          ENUM('owner','admin','member') NOT NULL DEFAULT 'member',
  status        ENUM('active','pending','invited') NOT NULL DEFAULT 'active',
  dtCreated     DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX uq_user_org (iUserId, iOrgId),
  CONSTRAINT fk_membership_user
    FOREIGN KEY (iUserId) REFERENCES auth_tbl_User(iUserId) ON DELETE CASCADE,
  CONSTRAINT fk_membership_org
    FOREIGN KEY (iOrgId) REFERENCES auth_tbl_Org(iOrgId) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ─── Sessions ────────────────────────────────────────────────────────────────
-- sSessionId  = 64-char hex (32 crypto-random bytes)
-- bIsSuperAdmin = 1 for @wisp.net Google logins (staff / back-door)
-- bIsProvisioning = 1 while a new UISP client is picking their sign-in method
-- jsonMeta holds provisioning context when bIsProvisioning=1:
--   { clientId, orgId, prefillEmail }
CREATE TABLE IF NOT EXISTS auth_tbl_Session (
  sSessionId      CHAR(64) PRIMARY KEY,
  iUserId         BIGINT   NULL,
  iOrgId          BIGINT   NULL,
  iBusinessNumber BIGINT   NULL,
  role            ENUM('owner','admin','member') NULL,
  bIsSuperAdmin   TINYINT(1) NOT NULL DEFAULT 0,
  bIsProvisioning TINYINT(1) NOT NULL DEFAULT 0,
  jsonMeta        JSON     NULL,
  dtExpires       DATETIME(3) NOT NULL,
  dtCreated       DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  INDEX idx_expires (dtExpires)
) ENGINE=InnoDB;

-- ─── SSO one-time nonces ──────────────────────────────────────────────────────
-- The UISP bridge plugin embeds a nonce in the signed code. Echo marks it
-- used on first redemption; a second redemption is rejected as a replay.
CREATE TABLE IF NOT EXISTS auth_tbl_SsoNonce (
  sNonce    CHAR(32) PRIMARY KEY,
  bUsed     TINYINT(1) NOT NULL DEFAULT 0,
  dtExpires DATETIME(3) NOT NULL,
  dtCreated DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  INDEX idx_expires (dtExpires)
) ENGINE=InnoDB;
