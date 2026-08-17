USE echo_db;

-- Make the UISP client login a first-class identity.
--
-- Previously a UISP client had to bind a Google account before they could get
-- into Echo at all. The bridge already proves who they are, so 'uisp' becomes a
-- provider in its own right (subject = the CRM clientId) and linking Google is
-- an optional convenience rather than a gate.
ALTER TABLE auth_tbl_Identity
  MODIFY COLUMN provider ENUM('google','magic_link','uisp') NOT NULL;
