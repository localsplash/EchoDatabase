-- 011_echoweb_identity_to_id.sql
--
-- EchoWeb no longer performs OAuth itself: login is delegated to the `id`
-- app (id.<parent-domain>), which owns users, identities, and SSO sessions
-- in id_db. Echo keeps only what is Echo's business — orgs, memberships,
-- and its own application sessions — and maps them to id users.
--
-- Deliberately breaking for existing OAuth users: identities are not
-- migrated (accounts re-bind on first login through id, matched by UISP
-- clientId or CRM contact email exactly as before).

USE echo_db;

-- Echo users are now projections of id users.
ALTER TABLE auth_tbl_User
  ADD COLUMN iIdUserId BIGINT NULL AFTER iUserId,
  ADD UNIQUE INDEX uq_id_user (iIdUserId);

-- "Forever until revoked": NULL dtExpires = never expires. Sessions end via
-- logout or super-admin revocation, not by the clock.
ALTER TABLE auth_tbl_Session
  MODIFY COLUMN dtExpires DATETIME(3) NULL;

-- Login methods and SSO replay nonces live in id_db now.
DROP TABLE IF EXISTS auth_tbl_Identity;
DROP TABLE IF EXISTS auth_tbl_SsoNonce;
