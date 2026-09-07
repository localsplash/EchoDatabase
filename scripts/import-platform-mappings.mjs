#!/usr/bin/env node
import fs from 'node:fs';
import mysql from 'mysql2/promise';
const filename = process.argv[2],
  apply = process.argv.includes('--apply');
if (!filename || !process.env.ECHO_DB_URL)
  throw new Error(
    'Set ECHO_DB_URL and pass a reviewed mapping manifest; default dry run, --apply commits',
  );
const manifest = JSON.parse(fs.readFileSync(filename, 'utf8'));
if (!Array.isArray(manifest.organizations) || !Array.isArray(manifest.users))
  throw new Error('Expected {organizations:[],users:[]}');
function id(value) {
  if (!Number.isSafeInteger(value) || value < 1)
    throw new Error('Mapping IDs must be positive safe integers');
  return value;
}
const conn = await mysql.createConnection(process.env.ECHO_DB_URL);
try {
  await conn.beginTransaction();
  for (const row of manifest.organizations) {
    const org = id(row.iOrgId),
      tenant = id(row.iTenantId);
    if (
      row.iBusinessNumber !== null &&
      (!Number.isSafeInteger(row.iBusinessNumber) ||
        !/^\d{10}$/.test(String(row.iBusinessNumber)))
    )
      throw new Error(
        'Legacy Echo business numbers must be 10-digit US numbers or null',
      );
    const [source] = await conn.query(
      'SELECT iBusinessNumber FROM auth_tbl_Org WHERE iOrgId=? FOR UPDATE',
      [org],
    );
    if (
      source.length !== 1 ||
      (source[0].iBusinessNumber === null
        ? null
        : Number(source[0].iBusinessNumber)) !== row.iBusinessNumber
    )
      throw new Error(
        'Source organization number differs from reviewed mapping',
      );
    const [existing] = await conn.query(
      'SELECT iTenantId,iBusinessNumber FROM echo_tbl_PlatformOrgMap WHERE iOrgId=? FOR UPDATE',
      [org],
    );
    if (existing.length) {
      if (
        Number(existing[0].iTenantId) !== tenant ||
        (existing[0].iBusinessNumber === null
          ? null
          : Number(existing[0].iBusinessNumber)) !== row.iBusinessNumber
      )
        throw new Error('Immutable organization mapping conflict');
    } else
      await conn.query(
        'INSERT INTO echo_tbl_PlatformOrgMap (iOrgId,iTenantId,iBusinessNumber) VALUES (?,?,?)',
        [org, tenant, row.iBusinessNumber],
      );
  }
  for (const row of manifest.users) {
    const local = id(row.iEchoUserId),
      central = id(row.iPlatformUserId);
    const [existing] = await conn.query(
      'SELECT iPlatformUserId FROM echo_tbl_PlatformUserMap WHERE iEchoUserId=? FOR UPDATE',
      [local],
    );
    if (existing.length) {
      if (Number(existing[0].iPlatformUserId) !== central)
        throw new Error('Immutable user mapping conflict');
    } else
      await conn.query(
        'INSERT INTO echo_tbl_PlatformUserMap (iEchoUserId,iPlatformUserId) VALUES (?,?)',
        [local, central],
      );
  }
  if (apply) await conn.commit();
  else await conn.rollback();
  console.log(
    `${manifest.organizations.length} organizations and ${manifest.users.length} users validated; ${apply ? 'committed' : 'rolled back (dry run)'}`,
  );
} catch (e) {
  await conn.rollback();
  throw e;
} finally {
  await conn.end();
}
