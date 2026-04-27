// Bhojan API Test Suite — Sprint 2, 3 & 4
// Covers EP-17, 18, 20, 21, 22, 26, 27, 07, 09, 10, 11, 12, 14, 33, 34
// EP-08 (avatar) skipped — requires manual Supabase bucket setup
import Redis from 'ioredis';
import { PrismaClient } from '@prisma/client';

const BASE = 'http://localhost:3000';
const redis = new Redis('redis://localhost:6379');
const prisma = new PrismaClient();

let passed = 0, failed = 0;

// ── Helpers ────────────────────────────────────────────────────────────────────

function log(label, ok, detail = '') {
  const icon = ok ? '✅' : '❌';
  console.log(`${icon} ${label}${detail ? ' — ' + detail : ''}`);
  ok ? passed++ : failed++;
}

async function post(path, body, token) {
  const r = await fetch(`${BASE}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token && { Authorization: `Bearer ${token}` }) },
    body: JSON.stringify(body),
  });
  return { status: r.status, body: await r.json() };
}

async function put(path, body, token) {
  const r = await fetch(`${BASE}${path}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', ...(token && { Authorization: `Bearer ${token}` }) },
    body: JSON.stringify(body),
  });
  return { status: r.status, body: await r.json() };
}

async function get(path, token) {
  const r = await fetch(`${BASE}${path}`, {
    headers: { ...(token && { Authorization: `Bearer ${token}` }) },
  });
  return { status: r.status, body: await r.json() };
}

async function del(path, token, body) {
  const r = await fetch(`${BASE}${path}`, {
    method: 'DELETE',
    headers: {
      ...(token && { Authorization: `Bearer ${token}` }),
      ...(body && { 'Content-Type': 'application/json' }),
    },
    ...(body && { body: JSON.stringify(body) }),
  });
  return { status: r.status, body: await r.json() };
}

async function getOtp(identifier) {
  const raw = await redis.get(`otp:${identifier}`);
  return raw ? JSON.parse(raw).otp : null;
}

// ── Server health check ───────────────────────────────────────────────────────

console.log('\n═══════════════════════════════════════════');
console.log('  BHOJAN API TEST SUITE — Sprint 2, 3 & 4');
console.log('═══════════════════════════════════════════\n');

try {
  await fetch(`${BASE}/tenants`);
} catch {
  console.error('❌ Server is not running. Start with: npm run start:dev');
  await redis.quit(); await prisma.$disconnect();
  process.exit(1);
}
console.log('✅ Server is up\n');

// ── Seed test data ────────────────────────────────────────────────────────────

console.log('── Seeding test data ────────────────────────');

const tenant = await prisma.tenant.upsert({
  where: { domain: 'test.bhojan.app' },
  update: {},
  create: { name: 'Test Corp', domain: 'test.bhojan.app', is_active: true },
});
console.log(`   Tenant: ${tenant.id} (${tenant.name})`);

const adminUser = await prisma.user.upsert({
  where: { email: 'superadmin@bhojan.app' },
  update: { is_active: true },
  create: {
    phone: '+916000000001', email: 'superadmin@bhojan.app',
    full_name: 'Super Admin', role: 'SUPER_ADMIN',
    is_active: true, is_verified: true, can_place_orders: false,
  },
});
console.log(`   Admin: ${adminUser.id}`);

await prisma.employeeRoster.upsert({
  where: { tenant_id_employee_id: { tenant_id: tenant.id, employee_id: 'EMP-UPGRADE-001' } },
  update: { is_active: true },
  create: {
    tenant_id: tenant.id, employee_id: 'EMP-UPGRADE-001',
    email: 'guestb_upgrade@testcorp.com', full_name: 'Guest B Employee', is_active: true,
  },
});
// Clean up any user left over from a previous upgrade test run (unique email constraint).
// CANNOT deleteMany — the DPDP trigger blocks cascade-delete of audit_logs.
// Instead: null the email + deactivate so EP-14 upgrade flow can re-use this email.
await prisma.user.updateMany({
  where: { email: 'guestb_upgrade@testcorp.com' },
  data: { email: null, is_active: false, is_deleted: true },
});
console.log(`   Roster (upgrade): EMP-UPGRADE-001 / guestb_upgrade@testcorp.com`);

const offboardUser = await prisma.user.upsert({
  where: { phone: '+916000000002' },
  update: { is_active: true, is_employee: true, tenant_id: tenant.id, employee_id: 'EMP-OFFBOARD-001', role: 'USER' },
  create: {
    phone: '+916000000002', full_name: 'Test Employee',
    role: 'USER', tenant_id: tenant.id,
    is_employee: true, employee_id: 'EMP-OFFBOARD-001',
    is_active: true, is_verified: true,
  },
});
await prisma.employeeRoster.upsert({
  where: { tenant_id_employee_id: { tenant_id: tenant.id, employee_id: 'EMP-OFFBOARD-001' } },
  update: { is_active: true },
  create: {
    tenant_id: tenant.id, employee_id: 'EMP-OFFBOARD-001',
    email: 'offboard@testcorp.com', full_name: 'Test Employee', is_active: true,
  },
});
console.log(`   Employee (offboard): ${offboardUser.id}\n`);

// ── Test state ────────────────────────────────────────────────────────────────

const ts = Date.now().toString().slice(-9);
const phoneA = `+916${ts}`;           // GUEST A
const emailA = `testa${ts}@bhojan.app`;
const phoneB = `+917${ts}`;           // GUEST B (for upgrade)
const vendorPhone = `+918${ts}`;
const vendorEmail = `vendor${ts}@testcorp.com`;
const newEmailA = `changed${ts}@bhojan.app`;

let adminToken;
let vendorToken, vendorUserId, vendorSessionId;
let guestAToken, guestBToken;

// ═══════════════════════════════════════════════════════════════════════════════
// SPRINT 2
// ═══════════════════════════════════════════════════════════════════════════════

console.log('── Sprint 2: Admin Auth ─────────────────────');

// EP-20 Step 1 — send OTP to admin email
{
  const r = await post('/admin/auth/login', { email: 'superadmin@bhojan.app' });
  const ok = r.status === 200 && r.body.data?.message?.includes('OTP');
  log('EP-20 Admin login step 1 (send OTP)', ok, `status=${r.status}`);
  if (!ok) console.log('   Body:', JSON.stringify(r.body));
}

// EP-20 Step 2 — verify OTP → tokens
{
  const otp = await getOtp('superadmin@bhojan.app');
  if (!otp) {
    log('EP-20 Admin login step 2 (verify)', false, 'OTP not in Redis');
  } else {
    const r = await post('/admin/auth/login', { email: 'superadmin@bhojan.app', otp });
    const ok = r.status === 200 && !!r.body.data?.access_token;
    log('EP-20 Admin login step 2 (verify → tokens)', ok, `status=${r.status}`);
    if (ok) adminToken = r.body.data.access_token;
    else console.log('   Body:', JSON.stringify(r.body));
  }
}

// EP-20 — wrong OTP → 400
{
  const r = await post('/admin/auth/login', { email: 'superadmin@bhojan.app', otp: '000000' });
  const ok = r.status === 400;
  log('EP-20 Wrong OTP → 400', ok, `status=${r.status}`);
}

// EP-21 — admin permissions
{
  const r = await get('/admin/auth/permissions', adminToken);
  const ok = r.status === 200 && r.body.data?.role === 'SUPER_ADMIN' && Array.isArray(r.body.data?.permissions);
  log('EP-21 Admin permissions', ok, `status=${r.status} role=${r.body.data?.role}`);
  if (!ok) console.log('   Body:', JSON.stringify(r.body));
}

// EP-21 — no token → 401
{
  const r = await get('/admin/auth/permissions');
  const ok = r.status === 401;
  log('EP-21 No token → 401', ok, `status=${r.status}`);
}

console.log('\n── Sprint 2: Vendor ─────────────────────────');

// EP-27 — create vendor
{
  const r = await post('/admin/vendors', {
    email: vendorEmail, phone: vendorPhone, full_name: 'Test Vendor',
    business_name: 'Test Kitchen', tenant_id: tenant.id,
    business_address: '123 Test St', city: 'Mumbai', state: 'Maharashtra', pincode: '400001',
  }, adminToken);
  const ok = r.status === 201 && !!r.body.data?.vendor_id;
  log('EP-27 Create vendor', ok, `status=${r.status}`);
  if (ok) vendorUserId = r.body.data.vendor_id;
  else console.log('   Body:', JSON.stringify(r.body));
}

// EP-27 — duplicate phone/email → 409
{
  const r = await post('/admin/vendors', {
    email: vendorEmail, phone: vendorPhone, full_name: 'Dup Vendor',
    business_name: 'Dup Kitchen', tenant_id: tenant.id,
    business_address: '1 Dup St', city: 'Mumbai', state: 'Maharashtra', pincode: '400001',
  }, adminToken);
  const ok = r.status === 409;
  log('EP-27 Duplicate vendor → 409', ok, `status=${r.status}`);
}

// EP-17 — vendor activate
{
  const allKeys = await redis.keys('activation:*');
  let activated = false;
  for (const key of allKeys) {
    const uid = await redis.get(key);
    if (uid === vendorUserId) {
      const token = key.split(':')[1];
      const r = await post('/vendor/auth/activate', { activation_token: token, password: 'Vendor@1234' });
      const ok = r.status === 200;
      log('EP-17 Vendor activate', ok, `status=${r.status}`);
      if (!ok) console.log('   Body:', JSON.stringify(r.body));
      activated = true;
      break;
    }
  }
  if (!activated) log('EP-17 Vendor activate', false, 'activation token not found in Redis');
}

// EP-18 — vendor login
{
  const r = await post('/vendor/auth/login', { phone: vendorPhone, password: 'Vendor@1234' });
  const ok = r.status === 200 && !!r.body.data?.access_token;
  log('EP-18 Vendor login', ok, `status=${r.status}`);
  if (ok) vendorToken = r.body.data.access_token;
  else console.log('   Body:', JSON.stringify(r.body));
}

// EP-18 — wrong password → 401
{
  const r = await post('/vendor/auth/login', { phone: vendorPhone, password: 'WrongPass@1' });
  const ok = r.status === 401;
  log('EP-18 Vendor wrong password → 401', ok, `status=${r.status}`);
}

// ═══════════════════════════════════════════════════════════════════════════════
// GUEST A setup + Sprint 4 (user auth flows)
// ═══════════════════════════════════════════════════════════════════════════════

console.log('\n── GUEST A setup ────────────────────────────');

{
  const r = await post('/auth/register', {
    phone: phoneA, full_name: 'Guest A Test', password: 'GuestA@1234',
    user_type: 'GUEST', email: emailA,
  });
  log('Register GUEST A', r.status === 200 && !!r.body.data?.otp_reference, `status=${r.status}`);
  if (r.status !== 200) console.log('   Body:', JSON.stringify(r.body));
}
{
  const otp = await getOtp(phoneA);
  const r = await post('/auth/otp/verify', { phone: phoneA, otp });
  const ok = r.status === 201 && !!r.body.data?.access_token;
  log('OTP verify GUEST A', ok, `status=${r.status}`);
  if (ok) guestAToken = r.body.data.access_token;
  else console.log('   Body:', JSON.stringify(r.body));
}

console.log('\n── Sprint 4: Profile ────────────────────────');

// EP-07 — update profile fields
{
  const r = await put('/auth/profile', {
    department: 'Engineering', floor: '3', building: 'Block A',
    preferences: { dietary: 'VEG', language: 'en' },
  }, guestAToken);
  const ok = r.status === 200 && r.body.data?.profile?.department === 'Engineering';
  log('EP-07 Update profile (fields)', ok, `status=${r.status}`);
  if (!ok) console.log('   Body:', JSON.stringify(r.body));
}

// EP-07 — update full_name (syncs to users table)
{
  const r = await put('/auth/profile', { full_name: 'Guest A Updated' }, guestAToken);
  const ok = r.status === 200 && r.body.data?.profile?.full_name === 'Guest A Updated';
  log('EP-07 Update full_name', ok, `status=${r.status}`);
  if (!ok) console.log('   Body:', JSON.stringify(r.body));
}

// EP-07 — no token → 401
{
  const r = await put('/auth/profile', { department: 'Finance' });
  log('EP-07 No token → 401', r.status === 401, `status=${r.status}`);
}

// EP-08 — skipped (Supabase bucket required)
console.log('⏭️  EP-08 Avatar upload — SKIPPED (create "avatars" public bucket in Supabase first)');



console.log('\n── Sprint 4: Password Reset ─────────────────');

// EP-09 — send OTP (always 200)
{
  const r = await post('/auth/password/reset-request', { phone: phoneA });
  const ok = r.status === 200 && r.body.data?.message?.includes('account');
  log('EP-09 Password reset request', ok, `status=${r.status}`);
  if (!ok) console.log('   Body:', JSON.stringify(r.body));
}

// EP-09 — non-existent phone → still 200 (no enumeration)
{
  const r = await post('/auth/password/reset-request', { phone: '+919199999991' });
  log('EP-09 Non-existent phone → 200', r.status === 200, `status=${r.status}`);
}

// EP-10 — verify OTP + set new password
{
  const otp = await getOtp(phoneA);
  if (!otp) {
    log('EP-10 Password reset verify', false, 'OTP not in Redis');
  } else {
    const r = await post('/auth/password/reset-verify', { phone: phoneA, otp, new_password: 'NewPassA@5678' });
    const ok = r.status === 200 && r.body.data?.message?.includes('reset');
    log('EP-10 Password reset verify', ok, `status=${r.status}`);
    if (!ok) console.log('   Body:', JSON.stringify(r.body));
    else guestAToken = null; // sessions revoked
  }
}

// EP-10 — re-login with new password
{
  const r = await post('/auth/login/password', { phone: phoneA, password: 'NewPassA@5678' });
  const ok = r.status === 200 && !!r.body.data?.access_token;
  log('Re-login after password reset', ok, `status=${r.status}`);
  if (ok) guestAToken = r.body.data.access_token;
  else console.log('   Body:', JSON.stringify(r.body));
}

console.log('\n── Sprint 4: Contact Change ─────────────────');

// EP-11 — initiate email change
let contactRequestId;
{
  const r = await post('/auth/contact/change', { type: 'EMAIL', new_value: newEmailA }, guestAToken);
  const ok = r.status === 200 && !!r.body.data?.request_id;
  log('EP-11 Contact change initiate', ok, `status=${r.status}`);
  if (ok) contactRequestId = r.body.data.request_id;
  else console.log('   Body:', JSON.stringify(r.body));
}

// EP-11 — duplicate new_value → 409
{
  const r = await post('/auth/contact/change', { type: 'EMAIL', new_value: emailA }, guestAToken);
  log('EP-11 Duplicate contact → 409', r.status === 409, `status=${r.status}`);
}

// EP-12 — verify both OTPs → new tokens
{
  if (!contactRequestId) {
    log('EP-12 Contact change verify', false, 'no request_id from EP-11');
  } else {
    const otpOld = await redis.get(`otp_old:${contactRequestId}`);
    const otpNew = await redis.get(`otp_new:${contactRequestId}`);
    if (!otpOld || !otpNew) {
      log('EP-12 Contact change verify', false, `OTPs not in Redis (old=${!!otpOld} new=${!!otpNew})`);
    } else {
      const r = await post('/auth/contact/verify', {
        request_id: contactRequestId, otp_old: otpOld, otp_new: otpNew,
      }, guestAToken);
      const ok = r.status === 200 && !!r.body.data?.access_token;
      log('EP-12 Contact change verify → new tokens', ok, `status=${r.status}`);
      if (ok) guestAToken = r.body.data.access_token;
      else console.log('   Body:', JSON.stringify(r.body));
    }
  }
}

// EP-12 — wrong OTP → 400
{
  const r2 = await post('/auth/contact/change', { type: 'EMAIL', new_value: `wrong${ts}@bhojan.app` }, guestAToken);
  if (r2.status === 200 && r2.body.data?.request_id) {
    const r = await post('/auth/contact/verify', {
      request_id: r2.body.data.request_id, otp_old: '000000', otp_new: '000000',
    }, guestAToken);
    log('EP-12 Wrong OTPs → 400', r.status === 400, `status=${r.status}`);
  } else {
    log('EP-12 Wrong OTPs → 400', false, 'could not create second change request');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GUEST B + EP-14 Upgrade
// ─────────────────────────────────────────────────────────────────────────────

console.log('\n── Sprint 4: Guest → Employee Upgrade ───────');

{
  const r = await post('/auth/register', {
    phone: phoneB, full_name: 'Guest B Test', password: 'GuestB@1234', user_type: 'GUEST',
  });
  log('Register GUEST B', r.status === 200, `status=${r.status}`);
}
{
  const otp = await getOtp(phoneB);
  const r = await post('/auth/otp/verify', { phone: phoneB, otp });
  const ok = r.status === 201 && !!r.body.data?.access_token;
  log('OTP verify GUEST B', ok, `status=${r.status}`);
  if (ok) guestBToken = r.body.data.access_token;
}

// EP-14 Step 1 — validate roster + send OTP
{
  const r = await post('/auth/upgrade-to-employee', {
    employee_id: 'EMP-UPGRADE-001', work_email: 'guestb_upgrade@testcorp.com',
  }, guestBToken);
  const ok = r.status === 200 && r.body.data?.message?.includes('OTP');
  log('EP-14 Upgrade step 1 (send OTP)', ok, `status=${r.status}`);
  if (!ok) console.log('   Body:', JSON.stringify(r.body));
}

// EP-14 Step 1 — wrong employee_id → 409
{
  const r = await post('/auth/upgrade-to-employee', {
    employee_id: 'NONEXISTENT-EMP', work_email: 'guestb_upgrade@testcorp.com',
  }, guestBToken);
  log('EP-14 Bad employee_id → 409', r.status === 409, `status=${r.status}`);
}

// EP-14 Step 2 — verify OTP → USER role
{
  const otp = await getOtp(phoneB);
  if (!otp) {
    log('EP-14 Upgrade step 2 (verify)', false, 'OTP not in Redis');
  } else {
    const r = await post('/auth/upgrade-to-employee', {
      employee_id: 'EMP-UPGRADE-001', work_email: 'guestb_upgrade@testcorp.com', otp,
    }, guestBToken);
    const ok = r.status === 200 && r.body.data?.user?.role === 'USER' && r.body.data?.user?.is_employee === true;
    log('EP-14 Upgrade step 2 (verify → USER)', ok, `status=${r.status} role=${r.body.data?.user?.role}`);
    if (ok) guestBToken = r.body.data.access_token;
    else console.log('   Body:', JSON.stringify(r.body));
  }
}

// EP-14 — non-guest token → 403
{
  const r = await post('/auth/upgrade-to-employee', {
    employee_id: 'EMP-UPGRADE-001', work_email: 'guestb_upgrade@testcorp.com',
  }, guestBToken); // guestBToken is now a USER token
  log('EP-14 Non-GUEST token → 403', r.status === 403, `status=${r.status}`);
}

// ═══════════════════════════════════════════════════════════════════════════════
// SPRINT 3
// ═══════════════════════════════════════════════════════════════════════════════

console.log('\n── Sprint 3: Audit Logs & Offboarding ───────');

// EP-22 — list all logs
{
  const r = await get('/admin/audit-logs', adminToken);
  const ok = r.status === 200 && Array.isArray(r.body.data?.logs) && !!r.body.data?.pagination;
  log('EP-22 Audit logs (all)', ok, `status=${r.status} count=${r.body.data?.logs?.length ?? 'n/a'}`);
  if (!ok) console.log('   Body:', JSON.stringify(r.body));
}

// EP-22 — filter by action
{
  const r = await get('/admin/audit-logs?action=USER_LOGIN&limit=5&page=1', adminToken);
  const ok = r.status === 200 && Array.isArray(r.body.data?.logs);
  log('EP-22 Audit logs (filter action=USER_LOGIN)', ok, `count=${r.body.data?.logs?.length ?? 'n/a'}`);
}

// EP-22 — filter by date range
{
  const r = await get('/admin/audit-logs?from_date=2026-01-01&to_date=2026-12-31&limit=10', adminToken);
  const ok = r.status === 200;
  log('EP-22 Audit logs (date range)', ok, `status=${r.status}`);
}

// EP-22 — vendor token → 403
{
  const r = await get('/admin/audit-logs', vendorToken);
  log('EP-22 Vendor token → 403', r.status === 403, `status=${r.status}`);
}

// EP-26 — offboard employee
{
  const r = await post(`/admin/employees/${offboardUser.id}/offboard`, {
    reason: 'End of contract — automated test',
  }, adminToken);
  const ok = r.status === 200 && r.body.success === true;
  log('EP-26 Offboard employee', ok, `status=${r.status}`);
  if (!ok) console.log('   Body:', JSON.stringify(r.body));
}

// EP-26 — non-existent user → 404
{
  const r = await post('/admin/employees/00000000-0000-0000-0000-000000000000/offboard', {
    reason: 'test',
  }, adminToken);
  log('EP-26 Non-existent → 404', r.status === 404, `status=${r.status}`);
}

// EP-26 — vendor token → 403
{
  const r = await post(`/admin/employees/${offboardUser.id}/offboard`, { reason: 'test' }, vendorToken);
  log('EP-26 Vendor token → 403', r.status === 403, `status=${r.status}`);
}

// ─────────────────────────────────────────────────────────────────────────────
// Sprint 4: Admin Sessions (EP-33, EP-34)
// ─────────────────────────────────────────────────────────────────────────────

console.log('\n── Sprint 4: Admin Sessions ─────────────────');

// EP-33 — list active sessions
{
  const r = await get('/admin/sessions', adminToken);
  const ok = r.status === 200 && Array.isArray(r.body.data?.sessions);
  log('EP-33 List sessions', ok, `status=${r.status} count=${r.body.data?.sessions?.length ?? 'n/a'}`);
  if (ok && r.body.data.sessions.length > 0) {
    // Pick any non-admin session to revoke in EP-34
    const nonAdminSess = r.body.data.sessions.find(s => s.user_id !== adminUser.id);
    vendorSessionId = nonAdminSess?.id ?? r.body.data.sessions[0].id;
  }
  if (!ok) console.log('   Body:', JSON.stringify(r.body));
}

// EP-33 — filter by user_id
{
  const r = await get(`/admin/sessions?user_id=${adminUser.id}`, adminToken);
  log('EP-33 Filter by user_id', r.status === 200, `status=${r.status}`);
}

// EP-33 — include revoked (is_active=false)
{
  const r = await get('/admin/sessions?is_active=false', adminToken);
  log('EP-33 Revoked sessions (is_active=false)', r.status === 200, `status=${r.status}`);
}

// EP-33 — vendor token → 403
{
  const r = await get('/admin/sessions', vendorToken);
  log('EP-33 Vendor token → 403', r.status === 403, `status=${r.status}`);
}

// EP-34 — revoke session
{
  if (!vendorSessionId) {
    log('EP-34 Revoke session', false, 'no session_id available (no active sessions found)');
  } else {
    const r = await del(`/admin/sessions/${vendorSessionId}`, adminToken);
    const ok = r.status === 200 && r.body.success === true;
    log('EP-34 Revoke session', ok, `status=${r.status}`);
    if (!ok) console.log('   Body:', JSON.stringify(r.body));
  }
}

// EP-34 — non-existent → 404
{
  const r = await del('/admin/sessions/00000000-0000-0000-0000-000000000000', adminToken);
  log('EP-34 Non-existent → 404', r.status === 404, `status=${r.status}`);
}

// ═══════════════════════════════════════════════════════════════════════════════
// SPRINT 5 — EP-13: Account Deletion (DPDP)
// ═══════════════════════════════════════════════════════════════════════════════

console.log('\n── Sprint 5: Account Deletion (DPDP) ────────');

const phoneC = `+919${ts}`;
let guestCToken, guestCUserId;

// Register GUEST C
{
  const r = await post('/auth/register', {
    phone: phoneC, full_name: 'Guest C Delete', password: 'GuestC@1234', user_type: 'GUEST',
  });
  log('Register GUEST C', r.status === 200, `status=${r.status}`);
}
{
  const otp = await getOtp(phoneC);
  const r = await post('/auth/otp/verify', { phone: phoneC, otp });
  const ok = r.status === 201 && !!r.body.data?.access_token;
  log('OTP verify GUEST C', ok, `status=${r.status}`);
  if (ok) {
    guestCToken = r.body.data.access_token;
    guestCUserId = r.body.data.user?.id;
  }
}

// EP-13 — no token → 401
{
  const r = await del('/auth/account');
  log('EP-13 No token → 401', r.status === 401, `status=${r.status}`);
}

// EP-13 Step 1 — send OTP (no otp in body)
{
  const r = await del('/auth/account', guestCToken);
  const ok = r.status === 200 && r.body.data?.message?.includes('OTP');
  log('EP-13 Delete step 1 (send OTP)', ok, `status=${r.status}`);
  if (!ok) console.log('   Body:', JSON.stringify(r.body));
}

// EP-13 — wrong OTP → 400
{
  const r = await del('/auth/account', guestCToken, { otp: '000000' });
  log('EP-13 Wrong OTP → 400', r.status === 400, `status=${r.status}`);
}

// EP-13 Step 2 — verify OTP + delete account
{
  const otp = await getOtp(phoneC);
  if (!otp) {
    log('EP-13 Delete step 2 (verify + delete)', false, 'OTP not in Redis');
  } else {
    const r = await del('/auth/account', guestCToken, { otp, reason: 'Testing DPDP deletion flow' });
    const ok = r.status === 200 && r.body.success === true && r.body.message?.includes('deletion');
    log('EP-13 Delete step 2 (verify + delete)', ok, `status=${r.status}`);
    if (!ok) console.log('   Body:', JSON.stringify(r.body));
  }
}

// EP-13 — post-deletion: old token rejected (access token still valid for 15min but profile anonymised)
// Verify via DB that is_deleted=true and phone is anonymised
{
  if (guestCUserId) {
    const u = await prisma.user.findUnique({ where: { id: guestCUserId }, select: { is_deleted: true, phone: true, email: true } });
    const ok = u?.is_deleted === true && u?.phone?.startsWith('deleted_') && u?.email?.endsWith('@bhojan.deleted');
    log('EP-13 DB verify: PII anonymised', ok, `phone=${u?.phone?.slice(0, 15)}... email=${u?.email?.slice(0, 20)}...`);
  } else {
    log('EP-13 DB verify', false, 'no user ID available');
  }
}

// EP-13 — post-deletion: login with old phone → 404 (phone anonymised)
{
  const r = await post('/auth/login/password', { phone: phoneC, password: 'GuestC@1234' });
  log('EP-13 Login after deletion → 404', r.status === 404, `status=${r.status}`);
}


// ═══════════════════════════════════════════════════════════════════════════════
// BHRIGU'S ENDPOINTS — EP-28/29 (Vendor) · EP-30/31/32 (Delegation) · EP-23/24/25
// ═══════════════════════════════════════════════════════════════════════════════

console.log('\n── Bhrigu: Vendor Suspend / Reactivate ──────');

// EP-28 — suspend vendor
{
  if (!vendorUserId) {
    log('EP-28 Suspend vendor', false, 'no vendorUserId — EP-27 may have failed');
  } else {
    const r = await post(`/admin/vendors/${vendorUserId}/suspend`, { reason: 'Policy violation — automated test' }, adminToken);
    const ok = r.status === 200 && r.body.success === true;
    log('EP-28 Suspend vendor', ok, `status=${r.status}`);
    if (!ok) console.log('   Body:', JSON.stringify(r.body));
  }
}

// EP-28 — suspend already-suspended → 400
{
  if (vendorUserId) {
    const r = await post(`/admin/vendors/${vendorUserId}/suspend`, { reason: 'Already suspended' }, adminToken);
    log('EP-28 Already suspended → 400', r.status === 400, `status=${r.status}`);
  }
}

// EP-28 — non-existent vendor → 404
{
  const r = await post('/admin/vendors/00000000-0000-0000-0000-000000000000/suspend', { reason: 'test' }, adminToken);
  log('EP-28 Non-existent vendor → 404', r.status === 404, `status=${r.status}`);
}

// EP-29 — reactivate vendor
{
  if (!vendorUserId) {
    log('EP-29 Reactivate vendor', false, 'no vendorUserId');
  } else {
    const r = await post(`/admin/vendors/${vendorUserId}/reactivate`, { reason: 'Issue resolved — automated test' }, adminToken);
    const ok = r.status === 200 && r.body.success === true;
    log('EP-29 Reactivate vendor', ok, `status=${r.status}`);
    if (!ok) console.log('   Body:', JSON.stringify(r.body));
  }
}

// EP-29 — reactivate not-suspended → 400
{
  if (vendorUserId) {
    const r = await post(`/admin/vendors/${vendorUserId}/reactivate`, { reason: 'Not suspended' }, adminToken);
    log('EP-29 Not suspended → 400', r.status === 400, `status=${r.status}`);
  }
}

console.log('\n── Bhrigu: Delegation (EP-30/31/32) ────────');

// Seed: create an OPS_ADMIN user to be the delegatee
const opsAdmin = await prisma.user.upsert({
  where: { email: 'opsadmin@bhojan.app' },
  update: { is_active: true },
  create: {
    phone: '+916500000099', email: 'opsadmin@bhojan.app',
    full_name: 'Ops Admin', role: 'OPS_ADMIN',
    is_active: true, is_verified: true, can_place_orders: false,
  },
});
let delegationId;

// EP-30 — create delegation
{
  const expiresAt = new Date(Date.now() + 3600_000).toISOString(); // 1 hour from now
  const r = await post('/admin/delegations', {
    delegatee_id: opsAdmin.id,
    module: 'FINANCE',
    expires_at: expiresAt,
    reason: 'Test delegation',
  }, adminToken);
  const ok = r.status === 201 && !!r.body.data?.delegation_id;
  log('EP-30 Create delegation', ok, `status=${r.status}`);
  if (ok) delegationId = r.body.data.delegation_id;
  else console.log('   Body:', JSON.stringify(r.body));
}

// EP-30 — expired_at in the past → 400
{
  const r = await post('/admin/delegations', {
    delegatee_id: opsAdmin.id,
    module: 'FINANCE',
    expires_at: new Date(Date.now() - 3600_000).toISOString(),
  }, adminToken);
  log('EP-30 Past expires_at → 400', r.status === 400, `status=${r.status}`);
}

// EP-30 — non-existent delegatee → 404
{
  const r = await post('/admin/delegations', {
    delegatee_id: '00000000-0000-0000-0000-000000000000',
    module: 'AUTH',
    expires_at: new Date(Date.now() + 3600_000).toISOString(),
  }, adminToken);
  log('EP-30 Non-existent delegatee → 404', r.status === 404, `status=${r.status}`);
}

// EP-31 — list delegations
{
  const r = await get('/admin/delegations', adminToken);
  const ok = r.status === 200 && Array.isArray(r.body.data?.delegations);
  log('EP-31 List delegations', ok, `status=${r.status} count=${r.body.data?.delegations?.length ?? 'n/a'}`);
  if (!ok) console.log('   Body:', JSON.stringify(r.body));
}

// EP-31 — filter by delegatee_id
{
  const r = await get(`/admin/delegations?delegatee_id=${opsAdmin.id}`, adminToken);
  log('EP-31 Filter by delegatee_id', r.status === 200, `status=${r.status}`);
}

// EP-32 — revoke delegation
{
  if (!delegationId) {
    log('EP-32 Revoke delegation', false, 'no delegationId — EP-30 may have failed');
  } else {
    const r = await del(`/admin/delegations/${delegationId}`, adminToken);
    const ok = r.status === 200 && r.body.success === true;
    log('EP-32 Revoke delegation', ok, `status=${r.status}`);
    if (!ok) console.log('   Body:', JSON.stringify(r.body));
  }
}

// EP-32 — revoke already-revoked → 404
{
  if (delegationId) {
    const r = await del(`/admin/delegations/${delegationId}`, adminToken);
    log('EP-32 Already revoked → 404', r.status === 404, `status=${r.status}`);
  }
}

console.log('\n── Bhrigu: Audit Log Export (EP-23) ─────────');

let exportJobId;

// EP-23 — initial request → 200 with job_id + PENDING
{
  const r = await get('/admin/audit-logs/export', adminToken);
  const ok = r.status === 200 && r.body.data?.job_id && r.body.data?.status === 'PENDING';
  log('EP-23 Export initial request → PENDING', ok, `status=${r.status} job_id=${r.body.data?.job_id ?? 'n/a'}`);
  if (ok) exportJobId = r.body.data.job_id;
  else console.log('   Body:', JSON.stringify(r.body));
}

// EP-23 — poll for completion (wait up to 10s for Bull worker)
if (exportJobId) {
  let pollResult;
  for (let i = 0; i < 10; i++) {
    await new Promise(res => setTimeout(res, 1000));
    const r = await get(`/admin/audit-logs/export?job_id=${exportJobId}`, adminToken);
    if (r.body.data?.status === 'COMPLETED') {
      pollResult = r;
      break;
    }
    pollResult = r;
  }
  const ok = pollResult?.status === 200 && pollResult?.body.data?.status === 'COMPLETED';
  log('EP-23 Export poll → COMPLETED', ok, `status=${pollResult?.body.data?.status}`);
  if (!ok) console.log('   Body:', JSON.stringify(pollResult?.body));
}

// EP-23 — not found job_id → 404
{
  const r = await get('/admin/audit-logs/export?job_id=00000000-0000-0000-0000-000000000000', adminToken);
  log('EP-23 Unknown job_id → 404', r.status === 404, `status=${r.status}`);
}

// EP-23 — vendor token → 403
{
  const r = await get('/admin/audit-logs/export', vendorToken);
  log('EP-23 Vendor token → 403', r.status === 403, `status=${r.status}`);
}

console.log('\n── Bhrigu: Bulk Upload (EP-24/25) ───────────');

let uploadId;

// EP-24 — upload valid CSV
{
  const csv = 'employee_id,email,full_name,department\nEMP-BULK-001,bulk001@testcorp.com,Bulk User One,Engineering\nEMP-BULK-002,bulk002@testcorp.com,Bulk User Two,Finance';
  const FormData = (await import('node:buffer')).Blob; // use fetch FormData
  const form = new (await import('node:buffer')).Blob([csv], { type: 'text/csv' });

  // Use fetch directly with FormData for multipart
  const fd = new FormData([csv], { type: 'text/csv' });
  const boundary = '----BhojanBoundary' + Date.now();
  const body = [
    `--${boundary}`,
    `Content-Disposition: form-data; name="tenant_id"`,
    ``,
    tenant.id,
    `--${boundary}`,
    `Content-Disposition: form-data; name="file"; filename="employees.csv"`,
    `Content-Type: text/csv`,
    ``,
    csv,
    `--${boundary}--`
  ].join('\r\n');

  const r = await fetch('http://localhost:3000/admin/employees/bulk-upload', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${adminToken}`,
      'Content-Type': `multipart/form-data; boundary=${boundary}`,
    },
    body,
  });
  const rBody = await r.json();
  const ok = r.status === 202 && !!rBody.data?.upload_id;
  log('EP-24 Bulk upload CSV', ok, `status=${r.status}`);
  if (ok) uploadId = rBody.data.upload_id;
  else console.log('   Body:', JSON.stringify(rBody));
}

// EP-25 — poll upload status
{
  if (!uploadId) {
    log('EP-25 Bulk upload status', false, 'no uploadId — EP-24 may have failed');
  } else {
    // Wait for Bull worker to process
    let pollResult;
    for (let i = 0; i < 8; i++) {
      await new Promise(res => setTimeout(res, 1000));
      const r = await get(`/admin/employees/bulk-upload/${uploadId}`, adminToken);
      pollResult = r;
      if (r.body.data?.status === 'COMPLETED') break;
    }
    const ok = pollResult?.status === 200 && !!pollResult?.body.data?.upload_id;
    log('EP-25 Poll bulk upload status', ok, `status=${pollResult?.body.data?.status}`);
    if (!ok) console.log('   Body:', JSON.stringify(pollResult?.body));
  }
}

// EP-25 — non-existent → 404
{
  const r = await get('/admin/employees/bulk-upload/00000000-0000-0000-0000-000000000000', adminToken);
  log('EP-25 Non-existent upload → 404', r.status === 404, `status=${r.status}`);
}

// ── Summary ───────────────────────────────────────────────────────────────────

console.log('\n═══════════════════════════════════════════');
console.log(`  RESULTS: ${passed} passed, ${failed} failed`);
console.log(`  Total: ${passed + failed} tests`);
console.log('═══════════════════════════════════════════\n');
console.log('⏭️  EP-08 Avatar upload requires manual setup:');
console.log('   1. Go to Supabase dashboard → Storage');
console.log('   2. Create bucket named "avatars" (public)');
console.log('   3. Then test: POST /auth/profile/avatar with multipart file\n');

await redis.quit();
await prisma.$disconnect();
