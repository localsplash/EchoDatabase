# EchoDatabase

This repository owns Echo's application schema and its ordered `init/*.sql`
files. The full stack and upgrade runner live in
[EchoOrchestrator](https://github.com/localsplash/EchoOrchestrator).

## Legacy settings retirement

`init/009_settings.sql` is a released migration. Its comments describe the
historical design. Runtime settings now move to NocoDB
`PlatformConfig/cfg_tbl_Setting` under `*`, `echo`, `echo-web` and `echo-service`.
EchoMedia currently reads only deployment environment variables (`PORT` and
`MEDIA_ROOT`); it has no SQL settings reader to replace.

**Keep `echo_tbl_Settings` and its values through migration, deployment
verification and the agreed rollback window.** This change deliberately adds no
DROP migration and does not alter the released seed file. Explicit legacy modes
in EchoWeb/EchoService and old deployed images may still read the table.

[Issue #8](https://github.com/localsplash/EchoDatabase/issues/8) remains the gate
for a later destructive migration. Attach evidence for every item before that
migration is proposed:

1. EchoService and EchoWeb's PlatformConfig implementations are merged and the
   deployed image/commit and `SETTINGS_MODE=platform` are recorded for each.
2. Reviewed source rows are copied to the correct scopes (legacy `*` usually
   becomes `echo`, `web` becomes `echo-web`, `service` becomes `echo-service`),
   preserving secrets outside ordinary logs and keeping source values intact.
3. Verify cold startup, refresh, failure behavior, settings-dependent requests,
   carrier webhooks, outgoing messages, browser access and media retrieval in the
   real deployment. Record results without customer content or credentials.
4. Inventory all other SQL readers, scripts and deployment overrides. Confirm
   that none requires this table after retirement. EchoMedia's absence of a SQL
   reader is implementation evidence, not a substitute for testing its deployment.
5. Agree a rollback deadline and demonstrate recovery using the retained table,
   prior images and protected deployment configuration. Let the window expire
   before removing the compatibility reader and proposing the DROP release.
6. Take a consistent `mysqldump --single-transaction --routines` and a protected
   PlatformConfig export; rehearse restore before applying the later migration.

Do not equate merged code with deployment evidence. No live verification or
rollback-window completion is claimed by this documentation.

`echo_tbl_SchemaMigration` stays: EchoOrchestrator uses it as its migration
ledger. Identity owns its separate platform schema and shared-number registry.
The installed OfficePulse/Asterisk PBX owns extensions, queues and applied DID
routes; EchoDatabase must not copy or migrate vendor PBX tables. POC PBX reads go
through the OfficePulse integration API.

## Local development

`docker compose up -d` creates a local MySQL instance and applies `init/` only to
an empty volume. For an existing database, use EchoOrchestrator's documented
migration workflow; do not replay all released files manually. Local example
credentials are not production configuration.
