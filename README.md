# EchoDatabase

Echo owns the active messaging/media/carrier schema in `init/*.sql`.
Identity owns users, tenants, memberships, sessions and tenant-number access;
PlatformConfig owns runtime settings. The ordered upgrade runner lives in
[EchoOrchestrator](https://github.com/localsplash/EchoOrchestrator).

## Disposable Dev retirement

The current Dev decision intentionally deletes obsolete configuration and local
authentication/provenance data. No backup, rollback copy or preservation window
is required for this cleanup. Deploy the matching EchoWeb/EchoService revisions
with environment-provided NocoDB credentials first, then apply
`init/013_retire_legacy_configuration_and_auth.sql`.

The migration drops exactly these tables, with foreign-key enforcement kept on:

- `echo_tbl_Settings`
- `echo_tbl_PlatformOrgMap`, `echo_tbl_PlatformUserMap`
- `auth_tbl_Identity`, `auth_tbl_Membership`
- `auth_tbl_Session`, `auth_tbl_SsoNonce`
- `auth_tbl_User`, `auth_tbl_Org`

Child tables are dropped before their parents; `DROP TABLE IF EXISTS` allows
safe repeat execution after an interrupted run. No `sms_*` table/routine or
`echo_tbl_SchemaMigration` ledger is removed. Their data is still in active use.
No Identity `platform_db` or OfficePulse/Asterisk vendor object is changed here.

The old init files 005–009 and 012 are removed, together with the unused mapping
importer, so a fresh database never recreates obsolete objects. EchoOrchestrator's
ledger records filenames, not checksums; old ledger rows may remain as execution
history, and existing databases receive the new numbered 013 migration. There
is no technical dependency requiring the deleted seed files to stay in `init/`.

Before applying the migration, inspect the target database's foreign keys and
stored routines for unexpected references to the listed objects. Current source
has no active consumer: EchoWeb's unused legacy helper/import scripts are removed,
EchoService and EchoWeb read only PlatformConfig, and messaging schema foreign
keys reference only messaging/carrier objects. Stop legacy images before cleanup.

Track exact deployed versions, applied SQL, table absence, startup and tenant
access checks in [issue #8](https://github.com/localsplash/EchoDatabase/issues/8)
and [EchoOrchestrator #11](https://github.com/localsplash/EchoOrchestrator/issues/11).
This supersedes the earlier preservation and rollback-window plan.

## Validation

EchoWeb's `src/platform.integration.test.ts`, with this checkout provided as
`ECHO_DATABASE_SOURCE` and a disposable MySQL 8.4 `TEST_DB_URL`, initializes the
complete current fresh schema and exercises a messaging routine. It then creates
populated legacy tables with foreign keys, applies migration 013 twice, and
checks table removal, active messaging/ledger retention, and central session
access without local auth/mapping tables. It recreates only `echo_platform_test`.

## Local development

`docker compose up -d` creates a MySQL instance and applies current `init/` files
only to an empty volume. Existing databases use EchoOrchestrator's ordered
migration runner. Application DB coordinates stay deployment bootstrap; EchoMedia
still needs only its port and media mount path. Asterisk/OfficePulse own extensions,
queues, memberships and applied DID routes; POC PBX reads use its integration API.
