# Echo canonical identity mappings

Migration 012 adds Echo-owned mappings while preserving every existing organization, person, membership, session and message row. Identity alone owns platform users, tenants, memberships and application browser sessions. There are no cross-database foreign keys or copies of Identity/vendor schemas.

`echo_tbl_PlatformOrgMap` captures an existing Echo organization, its canonical tenant ID and its current legacy business number. Several existing org/number mappings may belong to the same canonical tenant. Numbers are unique across mappings. Echo's current number format remains 10-digit US local numbering; international E.164 support is a separate migration.

`echo_tbl_PlatformUserMap` records local-to-canonical person provenance. Multiple historical local person rows may converge on one reviewed central user. EchoWeb does not use local users/memberships to grant access after cutover. Historical user maps are for reconciliation and audit, not authorization.

Before deployment:

1. Back up and restore-rehearse Echo and Identity databases, configuration and media. Inspect the existing `echo_tbl_SchemaMigration` ledger against the actual schema; the older orchestrator runner can incorrectly baseline unapplied SQL when its ledger is missing. Apply 012 explicitly if that precondition is not established.
2. Establish central people, tenants and memberships in Identity. Match existing identities using provider/subject and verified CRM relationships; never assume equal numeric IDs or email strings prove ownership.
3. Review a manifest containing `organizations:[{iOrgId,iTenantId,iBusinessNumber}]` and `users:[{iEchoUserId,iPlatformUserId}]`. Verify every central target through Identity's authenticated directory API and mirror provenance into Identity's legacy-map ledger.
4. With the mysql2 dependency installed (or using the EchoWeb development image), run `ECHO_DB_URL=... node scripts/import-platform-mappings.mjs manifest.json`. It validates all rows in a rolled-back transaction. `--apply` commits; existing conflicting bindings are never overwritten. Source Echo org IDs and numbers must match the manifest, and local FK checks apply. The tool does not independently assert that a central target exists; the reviewed directory verification in step 3 is mandatory.
5. Freeze legacy provisioning and number reassignment, import final mappings, deploy Identity v2 and EchoWeb's central-session reader together, and verify every existing business and account. Legacy Echo cookies are replaced through a fresh central SSO handoff; no history or local session rows are deleted.

EchoWeb validates current central membership and tenant enablement on every authenticated request, then resolves the selected tenant/number through these reviewed mappings. If an org's live number differs from its captured mapping, access fails closed. Number reassignment and mapping rewrites remain prohibited until message/media historical ownership is independently modeled. Keep raw EchoService/EchoMedia outside the end-user trust boundary; this migration does not make their legacy endpoints tenant-aware.

This replaces the approach in stale EchoDatabase PR #3: do not merge its Identity schema creation, shared database grants or auth table drops. Migration 012 neither changes the existing ledger nor removes `echo_tbl_Settings`; configuration consumers must cross their own release boundary before legacy settings can be retired.
