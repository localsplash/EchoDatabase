-- 008_microsoft_identity.sql
--
-- Microsoft (Entra ID) joins Google as a login provider. Same shape as the
-- Google identity: subject = the OIDC `sub`, which Microsoft issues per
-- (application, user) and keeps stable across renames.

ALTER TABLE auth_tbl_Identity
  MODIFY COLUMN provider ENUM('google','magic_link','uisp','microsoft') NOT NULL;
