USE echo_db;

-- Identity owns platform_db; Echo retains historical IDs and immutable number
-- ownership mappings. No platform/vendor schema is created or changed here.
CREATE TABLE IF NOT EXISTS echo_tbl_PlatformOrgMap (
  iOrgId BIGINT NOT NULL PRIMARY KEY,
  iTenantId BIGINT NOT NULL,
  iBusinessNumber BIGINT NULL,
  dtCreated DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE KEY uq_platform_business_number (iBusinessNumber),
  KEY idx_platform_tenant (iTenantId),
  CONSTRAINT fk_platform_org FOREIGN KEY (iOrgId) REFERENCES auth_tbl_Org(iOrgId),
  CHECK (iTenantId BETWEEN 1 AND 9007199254740991)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS echo_tbl_PlatformUserMap (
  iEchoUserId BIGINT NOT NULL PRIMARY KEY,
  iPlatformUserId BIGINT NOT NULL,
  dtCreated DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  KEY idx_platform_user (iPlatformUserId),
  CONSTRAINT fk_platform_echo_user FOREIGN KEY (iEchoUserId) REFERENCES auth_tbl_User(iUserId),
  CHECK (iPlatformUserId BETWEEN 1 AND 9007199254740991)
) ENGINE=InnoDB;

-- Mapping rows are imported explicitly after verification with Identity. No
-- email matching, numeric-ID equality assumptions, backfill, deletion, or
-- membership/session copying runs automatically. Multiple historical Echo
-- users may map to one central person; multiple org/number bindings may map
-- to one canonical tenant. A number cannot belong to multiple mappings.
