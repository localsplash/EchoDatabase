USE echo_db;

-- A user may link several Google accounts, and the stored subject is Google's
-- opaque `sub` — meaningless in a UI. Keep the address alongside it so the
-- account can actually be told apart from the others when linking/unlinking.
ALTER TABLE auth_tbl_Identity
  ADD COLUMN email VARCHAR(255) NULL AFTER subject;

-- Backfill rows that predate the column, but only where the answer is certain:
-- a user holding exactly one Google identity must have used that address. Users
-- with several are left blank rather than guessed at; each fills in on next use.
-- (The derived table is required — MySQL will not let an UPDATE subquery read
-- the table being updated directly.)
UPDATE auth_tbl_Identity i
  JOIN auth_tbl_User u ON u.iUserId = i.iUserId
  SET i.email = u.email
WHERE i.email IS NULL
  AND i.provider = 'google'
  AND u.email IS NOT NULL
  AND (
    SELECT COUNT(*) FROM (SELECT iUserId, provider FROM auth_tbl_Identity) x
     WHERE x.iUserId = i.iUserId AND x.provider = 'google'
  ) = 1;
