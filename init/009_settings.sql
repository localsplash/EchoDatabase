-- 009_settings.sql
--
-- Runtime settings for the Echo applications.
--
-- Echo settings belong in the Echo database, next to the data they describe —
-- not in a NocoDB base of their own. The one value the Echo apps read from
-- outside this database is `trustedCIDR`, which lives in the IdentityBase
-- NocoDB base because it is a platform-wide network policy that every
-- application (identity included) has to agree on.
--
-- `sApp` is what keeps general and app-specific settings in one table instead
-- of one table per app:
--
--   '*'        every Echo app reads it
--   'web'      EchoWeb only
--   'service'  EchoService only
--   'media'    EchoMedia only
--
-- An app reads `sApp IN ('*', <its own name>)`, with its own row winning over
-- the general one. Adding a per-app setting is a row, never a new table.
--
-- Empty `sValue` means "not set": an app treats it as missing rather than as
-- an empty string, so a blank row never shadows a real value.

USE echo_db;

CREATE TABLE IF NOT EXISTS echo_tbl_Settings (
  iSettingId   BIGINT AUTO_INCREMENT PRIMARY KEY,
  sApp         VARCHAR(32)  NOT NULL DEFAULT '*',
  sKey         VARCHAR(128) NOT NULL,
  sValue       TEXT         NULL,
  sDescription VARCHAR(512) NULL,
  dtUpdated    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                            ON UPDATE CURRENT_TIMESTAMP(3),
  UNIQUE INDEX uq_app_key (sApp, sKey)
) ENGINE=InnoDB;

-- Seed the menu of settings with EMPTY values, so an admin sees what can be
-- set without having to guess key names, and so nothing is invented for a
-- database being created for the first time. INSERT IGNORE keeps a re-run and
-- an existing deployment untouched.

INSERT IGNORE INTO echo_tbl_Settings (sApp, sKey, sValue, sDescription) VALUES
  ('*', 'MEDIA_BASE_URL', '',
   'Browser-facing base URL for media files, e.g. https://media.echo.X.TLD.'),
  ('*', 'UISP_BASE_URL', '',
   'UISP instance base URL, e.g. https://my.wisp.net.'),
  ('*', 'UISP_CRM_APP_KEY_READ', '',
   'Read-only UISP CRM App Key. Read-only on purpose: Echo only reads clients.'),

  ('web', 'APP_BASE_URL', '',
   'Public base URL of EchoWeb, e.g. https://echo.X.TLD. Used to build the OAuth callback URIs.'),
  ('web', 'ECHO_SERVICE_BASE_URL', '',
   'Where EchoWeb reaches EchoService, e.g. http://echo-service:8080.'),
  ('web', 'GOOGLE_CLIENT_ID', '', 'Google OAuth 2.0 client ID.'),
  ('web', 'GOOGLE_CLIENT_SECRET', '', 'Google OAuth 2.0 client secret.'),
  ('web', 'MICROSOFT_CLIENT_ID', '', 'Microsoft Entra ID application (client) ID.'),
  ('web', 'MICROSOFT_CLIENT_SECRET', '', 'Microsoft Entra ID client secret.'),
  ('web', 'MICROSOFT_TENANT', '',
   'Entra authority segment: common accepts any account, a tenant GUID restricts sign-in to that tenant.'),
  ('web', 'UISP_SSO_SECRET', '',
   'HMAC-SHA256 hex secret shared with the UISP bridge plugin. Must match the plugin exactly.'),
  ('web', 'UISP_PLUGIN_URL', '',
   'The UISP bridge plugin public URL (UCRM generates it at install). The ISP login button is hidden until it is set.'),

  ('service', 'CORS_ORIGINS', '',
   'Extra browser origins EchoService accepts, comma-separated, beyond the hosts it already allows.'),
  ('service', 'WEBHOOK_BASIC_USER', '',
   'Basic-auth user for the carrier webhook endpoints. Callers from inside trustedCIDR do not need it.'),
  ('service', 'WEBHOOK_BASIC_PASS', '', 'Basic-auth password for the carrier webhook endpoints.'),
  ('service', 'MEDIA_ROOT', '', 'Filesystem root for stored media inside the container.'),
  ('service', 'BANDWIDTH_ACCOUNT_ID', '',
   'Bandwidth account. A per-business row in sms_tbl_CarrierApplication wins over this.'),
  ('service', 'BANDWIDTH_API_TOKEN', '', 'Bandwidth API token.'),
  ('service', 'BANDWIDTH_API_SECRET', '', 'Bandwidth API secret.'),
  ('service', 'BANDWIDTH_APPLICATION_ID', '', 'Bandwidth messaging application id.'),
  ('service', 'BANDWIDTH_MESSAGING_API_BASE_URL', '',
   'Bandwidth messaging API base. Empty means the public default.');
