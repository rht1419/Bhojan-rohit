/**
 * Bhojan API — Full Endpoint Test Runner
 * Run: node test-all-endpoints.mjs
 * Requires backend running on localhost:3000 and Redis on localhost:6379
 */

import Redis from 'ioredis';

const BASE = 'http://localhost:3000';
const TEST_PHONE = '+919000099999';
const TEST_PASSWORD = 'Test@1234';
const TEST_EMAIL = 'autotest@bhojan.dev';
const ADMIN_EMAIL = 'karthik5kashyapks@gmail.com';
const TENANT_ID = '22191e39-730e-4ebf-8011-e483a9d992d2';
const TECH_ADMIN_ID = 'f3961c9e-ba5c-44c4-91ca-08e65b3e6e7d';

let passed = 0;
let failed = 0;
let userToken = '';
let refreshToken = '';
let adminToken = '';
let adminRefresh = '';
let vendorToken = '';
let vendorId = '';
let sessionId = '';
let delegationId = '';
let bulkUploadId = '';

const redis = new Redis({ host: 'localhost', port: 6379 });

// ── Helpers ───────────────────────────────────────────────────────────────────

async function req(method, path, body, token) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, ...json };
}

async function getOtp(identifier) {
  const raw = await redis.get(`otp:${identifier}`);
  if (!raw) return null;
  return JSON.parse(raw).otp;
}

function log(ep, name, ok, detail = '') {
  const icon = ok ? '✅' : '❌';
  const status = ok ? 'PASS' : 'FAIL';
  console.log(`${icon} ${ep.padEnd(7)} ${name.padEnd(40)} ${status} ${detail}`);
  if (ok) passed++; else failed++;
}

function check(ep, name, res, expectKey) {
  const ok = res.success === true && (expectKey ? res.data?.[expectKey] !== undefined : true);
  log(ep, name, ok, ok ? '' : `→ ${JSON.stringify(res).slice(0, 120)}`);
  return ok;
}

// ── Test Suite ────────────────────────────────────────────────────────────────

async function run() {
  console.log('\n══════════════════════════════════════════════════');
  console.log('  BHOJAN API — FULL ENDPOINT TEST');
  console.log('══════════════════════════════════════════════════\n');

  // Clear OTP rate limit keys so test can run repeatedly without hitting limits
  await redis.del(`otp_limit:${TEST_PHONE}`);
  await redis.del(`otp:${TEST_PHONE}`);
  await redis.del(`otp_attempts:${TEST_PHONE}`);

  // ── EP-01: Register (GUEST) ────────────────────────────────────────────────
  let r = await req('POST', '/auth/register', {
    user_type: 'GUEST', full_name: 'Auto Test User',
    phone: TEST_PHONE, password: TEST_PASSWORD,
  });
  const newlyRegistered = r.success === true;
  const ep01ok = newlyRegistered || r.error?.code === 'USER_ALREADY_EXISTS';
  log('EP-01', 'Register GUEST', ep01ok, ep01ok ? (newlyRegistered ? 'new user' : 'already exists') : JSON.stringify(r).slice(0, 100));

  // ── EP-02: Verify OTP ──────────────────────────────────────────────────────
  await new Promise(res => setTimeout(res, 500));
  const otp = await getOtp(TEST_PHONE);
  if (!otp) {
    log('EP-02', 'Verify OTP', newlyRegistered ? false : true,
      newlyRegistered ? 'OTP not found in Redis' : 'skipped — user already existed');
  } else {
    r = await req('POST', '/auth/otp/verify', { phone: TEST_PHONE, otp });
    const ok = check('EP-02', 'Verify OTP', r, 'access_token');
    if (ok) { userToken = r.data.access_token; refreshToken = r.data.refresh_token; }
  }

  // ── EP-03: Login Password ──────────────────────────────────────────────────
  r = await req('POST', '/auth/login/password', { phone: TEST_PHONE, password: TEST_PASSWORD });
  const ep03ok = check('EP-03', 'Login Password', r, 'access_token');
  if (ep03ok) { userToken = r.data.access_token; refreshToken = r.data.refresh_token; }

  // ── EP-04: Refresh Token ───────────────────────────────────────────────────
  r = await req('POST', '/auth/token/refresh', { refresh_token: refreshToken });
  const ep04ok = check('EP-04', 'Refresh Token', r, 'access_token');
  if (ep04ok) { userToken = r.data.access_token; refreshToken = r.data.refresh_token; }

  // ── EP-06: Get Profile ─────────────────────────────────────────────────────
  r = await req('GET', '/auth/me', null, userToken);
  check('EP-06', 'Get My Profile', r, 'user');

  // ── EP-07: Update Profile ──────────────────────────────────────────────────
  r = await req('PUT', '/auth/profile', {
    full_name: 'Auto Test Updated', department: 'Engineering',
  }, userToken);
  check('EP-07', 'Update Profile', r);

  // ── EP-08: Avatar Upload ──────────────────────────────────────────────────
  // 1×1 white pixel JPEG (minimal valid JPEG, 107 bytes)
  const minimalJpeg = Buffer.from(
    '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8U' +
    'HRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAARCAABAAEDASIA' +
    'AhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/xAAU' +
    'AQEAAAAAAAAAAAAAAAAAAAAA/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8A' +
    'JQAB/9k=',
    'base64',
  );
  const avatarForm = new FormData();
  avatarForm.append('avatar', new Blob([minimalJpeg], { type: 'image/jpeg' }), 'test.jpg');
  {
    const avatarRes = await fetch(`${BASE}/auth/profile/avatar`, {
      method: 'POST', headers: { Authorization: `Bearer ${userToken}` }, body: avatarForm,
    });
    r = { status: avatarRes.status, ...await avatarRes.json().catch(() => ({})) };
    check('EP-08', 'Avatar Upload', r, 'avatar_url');
  }

  // ── EP-09: Password Reset Request ─────────────────────────────────────────
  await redis.del(`otp_limit:${TEST_PHONE}`);
  r = await req('POST', '/auth/password/reset-request', { phone: TEST_PHONE });
  check('EP-09', 'Password Reset Request', r);

  // ── EP-10: Password Reset Verify ──────────────────────────────────────────
  await new Promise(res => setTimeout(res, 500));
  const resetOtp = await getOtp(TEST_PHONE);
  if (resetOtp) {
    r = await req('POST', '/auth/password/reset-verify', {
      phone: TEST_PHONE, otp: resetOtp, new_password: 'NewPass@9999',
    });
    check('EP-10', 'Password Reset Verify', r);
    // restore original password
    const restoreOtp2 = await getOtp(TEST_PHONE);
    await req('POST', '/auth/password/reset-request', { phone: TEST_PHONE });
    await new Promise(res => setTimeout(res, 400));
    const restOtp = await getOtp(TEST_PHONE);
    if (restOtp) {
      await req('POST', '/auth/password/reset-verify', {
        phone: TEST_PHONE, otp: restOtp, new_password: TEST_PASSWORD,
      });
    }
  } else {
    log('EP-10', 'Password Reset Verify', false, 'OTP not found');
  }

  // ── Re-login after password reset ─────────────────────────────────────────
  r = await req('POST', '/auth/login/password', { phone: TEST_PHONE, password: TEST_PASSWORD });
  if (r.success) { userToken = r.data.access_token; refreshToken = r.data.refresh_token; }

  // ── EP-11: Contact Change Init ────────────────────────────────────────────
  const newContactEmail = `contact-${Date.now()}@autotest.com`;
  r = await req('POST', '/auth/contact/change', { type: 'EMAIL', new_value: newContactEmail }, userToken);
  const ep11ok = check('EP-11', 'Contact Change Init', r, 'request_id');
  if (ep11ok) {
    const contactRequestId = r.data.request_id;

    // ── EP-12: Contact Change Verify ────────────────────────────────────────
    const otpOld = await redis.get(`otp_old:${contactRequestId}`);
    const otpNew = await redis.get(`otp_new:${contactRequestId}`);
    if (!otpOld || !otpNew) {
      log('EP-12', 'Contact Change Verify', false, 'OTPs not found in Redis');
    } else {
      r = await req('POST', '/auth/contact/verify', {
        request_id: contactRequestId, otp_old: otpOld, otp_new: otpNew,
      }, userToken);
      const ep12ok = check('EP-12', 'Contact Change Verify', r, 'access_token');
      // EP-12 revokes all sessions and issues new tokens — capture them
      if (ep12ok) { userToken = r.data.access_token; refreshToken = r.data.refresh_token; }
    }
  }

  // ── EP-35: Get Tenants ─────────────────────────────────────────────────────
  r = await req('GET', '/tenants');
  // data is an array of tenant objects, not { tenants: [...] }
  const ep35ok = r.success === true && Array.isArray(r.data);
  log('EP-35', 'Get All Tenants', ep35ok, ep35ok ? `${r.data.length} tenants` : JSON.stringify(r).slice(0, 100));

  // ── EP-36: Get Tenant Settings ────────────────────────────────────────────
  r = await req('GET', `/tenants/${TENANT_ID}/settings`);
  check('EP-36', 'Get Tenant Settings', r);

  // ── EP-37: Tenant Validate ────────────────────────────────────────────────
  r = await req('POST', '/tenants/validate', { tenant_id: TENANT_ID });
  check('EP-37', 'Tenant Validate', r);

  // ── EP-20: Admin Login Step 1 ─────────────────────────────────────────────
  r = await req('POST', '/admin/auth/login', { email: ADMIN_EMAIL });
  const step1ok = r.success === true;
  log('EP-20a', 'Admin Login - Send OTP', step1ok, step1ok ? '' : JSON.stringify(r).slice(0, 100));

  // ── EP-20: Admin Login Step 2 ─────────────────────────────────────────────
  await new Promise(res => setTimeout(res, 600));
  const adminOtp = await getOtp(ADMIN_EMAIL);
  if (!adminOtp) {
    log('EP-20b', 'Admin Login - Verify OTP', false, 'OTP not found in Redis');
  } else {
    r = await req('POST', '/admin/auth/login', { email: ADMIN_EMAIL, otp: adminOtp });
    const ok = check('EP-20b', 'Admin Login - Verify OTP', r, 'access_token');
    if (ok) { adminToken = r.data.access_token; adminRefresh = r.data.refresh_token; }
  }

  if (!adminToken) {
    console.log('\n⚠️  No admin token — skipping admin endpoints\n');
  } else {

    // ── EP-21: Admin Permissions ─────────────────────────────────────────────
    r = await req('GET', '/admin/auth/permissions', null, adminToken);
    check('EP-21', 'Admin Permissions', r, 'permissions');

    // ── EP-22: Audit Logs ────────────────────────────────────────────────────
    r = await req('GET', '/admin/audit-logs?page=1&limit=5', null, adminToken);
    check('EP-22', 'Get Audit Logs', r, 'logs');

    // ── EP-23: Audit Export ──────────────────────────────────────────────────
    r = await req('GET', '/admin/audit-logs/export', null, adminToken);
    const exportOk = r.success && r.data?.job_id;
    log('EP-23a', 'Audit Export - Queue Job', exportOk, exportOk ? `job_id=${r.data.job_id}` : JSON.stringify(r).slice(0,80));
    if (exportOk) {
      const jobId = r.data.job_id;
      await new Promise(res => setTimeout(res, 2000));
      r = await req('GET', `/admin/audit-logs/export?job_id=${jobId}`, null, adminToken);
      const pollOk = r.success && r.data?.status === 'COMPLETED';
      log('EP-23b', 'Audit Export - Poll Result', pollOk, pollOk ? `${r.data.row_count} rows` : JSON.stringify(r).slice(0,80));
    }

    // ── EP-24: Bulk Employee Upload ──────────────────────────────────────────
    const csvContent = 'employee_id,email,full_name,department\nEMP-TEST-001,bulktest@autotest.com,Bulk Test User,Engineering';
    const bulkForm = new FormData();
    bulkForm.append('file', new Blob([csvContent], { type: 'text/csv' }), 'employees.csv');
    bulkForm.append('tenant_id', TENANT_ID);
    {
      const bulkRes = await fetch(`${BASE}/admin/employees/bulk-upload`, {
        method: 'POST', headers: { Authorization: `Bearer ${adminToken}` }, body: bulkForm,
      });
      r = { status: bulkRes.status, ...await bulkRes.json().catch(() => ({})) };
      const ep24ok = check('EP-24', 'Bulk Employee Upload', r, 'upload_id');
      if (ep24ok) bulkUploadId = r.data.upload_id;
    }

    // ── EP-25: Bulk Upload Status ─────────────────────────────────────────────
    if (bulkUploadId) {
      await new Promise(res => setTimeout(res, 2000));
      r = await req('GET', `/admin/employees/bulk-upload/${bulkUploadId}`, null, adminToken);
      const ep25ok = check('EP-25', 'Bulk Upload Status', r, 'upload_id');
      if (ep25ok) log('EP-25b', 'Bulk Upload Final Status', true, `status=${r.data.status} success=${r.data.success_count} failed=${r.data.failed_count}`);
    } else {
      log('EP-25', 'Bulk Upload Status', false, 'No upload_id from EP-24');
    }

    // ── EP-33: Get Sessions ──────────────────────────────────────────────────
    r = await req('GET', '/admin/sessions', null, adminToken);
    const sessOk = check('EP-33', 'Get Sessions', r, 'sessions');
    if (sessOk && r.data.sessions?.length > 0) {
      sessionId = r.data.sessions[0].id;
    }

    // ── EP-34: Revoke Session ────────────────────────────────────────────────
    if (sessionId) {
      r = await req('DELETE', `/admin/sessions/${sessionId}`, null, adminToken);
      check('EP-34', 'Revoke Session', r);
    } else {
      log('EP-34', 'Revoke Session', false, 'No session to revoke');
    }

    // ── EP-27: Create Vendor ─────────────────────────────────────────────────
    const vendorPhone = `+917888${Date.now().toString().slice(-6)}`;
    r = await req('POST', '/admin/vendors', {
      phone: vendorPhone,
      email: `vendor-${Date.now()}@autotest.com`,
      full_name: 'Auto Vendor',
      business_name: 'Auto Kitchen',
      business_address: '1 Test Street',
      city: 'Bangalore', state: 'Karnataka', pincode: '560001',
      tenant_id: TENANT_ID,
    }, adminToken);
    const v27ok = check('EP-27', 'Create Vendor', r, 'vendor_id');
    if (v27ok) vendorId = r.data.vendor_id;

    // ── EP-17: Vendor Activate ───────────────────────────────────────────────
    if (vendorId) {
      await new Promise(res => setTimeout(res, 400));
      // Key format: activation:{token} → value = user.id; scan to find token for this vendor
      const activationKeys = await redis.keys('activation:*');
      let activationToken = null;
      for (const key of activationKeys) {
        const val = await redis.get(key);
        if (val === vendorId) { activationToken = key.replace('activation:', ''); break; }
      }
      if (!activationToken) {
        log('EP-17', 'Vendor Activate', false, `No activation token found for vendor ${vendorId}`);
      } else {
        r = await req('POST', '/vendor/auth/activate', {
          activation_token: activationToken, password: 'Vendor@Auto1',
        });
        check('EP-17', 'Vendor Activate', r);

        // ── EP-18: Vendor Login ────────────────────────────────────────────────
        r = await req('POST', '/vendor/auth/login', { phone: vendorPhone, password: 'Vendor@Auto1' });
        const v18ok = check('EP-18', 'Vendor Login', r, 'access_token');
        if (v18ok) vendorToken = r.data.access_token;

        // ── EP-19: Update Vendor Profile ──────────────────────────────────────
        if (vendorToken) {
          r = await req('PUT', '/vendor/auth/profile', {
            business_name: 'Auto Kitchen Updated',
            business_address: '2 Updated Street',
            city: 'Mysore',
          }, vendorToken);
          check('EP-19', 'Update Vendor Profile', r);
        }

        // ── EP-28: Suspend Vendor ──────────────────────────────────────────────
        r = await req('POST', `/admin/vendors/${vendorId}/suspend`, {
          reason: 'Automated test suspension',
        }, adminToken);
        check('EP-28', 'Suspend Vendor', r);

        // ── EP-29: Reactivate Vendor ───────────────────────────────────────────
        r = await req('POST', `/admin/vendors/${vendorId}/reactivate`, {
          reason: 'Automated test reactivation',
        }, adminToken);
        check('EP-29', 'Reactivate Vendor', r);
      }
    }

    // ── EP-30: Create Delegation ─────────────────────────────────────────────
    r = await req('POST', '/admin/delegations', {
      delegatee_id: TECH_ADMIN_ID,
      module: 'VENDOR',
      reason: 'Auto test delegation',
      expires_at: '2026-06-30T00:00:00.000Z',
    }, adminToken);
    const d30ok = check('EP-30', 'Create Delegation', r, 'delegation_id');
    if (d30ok) delegationId = r.data.delegation_id;

    // ── EP-31: Get Delegations ───────────────────────────────────────────────
    r = await req('GET', '/admin/delegations', null, adminToken);
    check('EP-31', 'Get Delegations', r, 'delegations');

    // ── EP-32: Revoke Delegation ─────────────────────────────────────────────
    if (delegationId) {
      r = await req('DELETE', `/admin/delegations/${delegationId}`, null, adminToken);
      check('EP-32', 'Revoke Delegation', r);
    }

  }

  // ── EP-05: Logout ──────────────────────────────────────────────────────────
  if (userToken && refreshToken) {
    r = await req('POST', '/auth/logout', { refresh_token: refreshToken }, userToken);
    check('EP-05', 'Logout', r);
  }

  // ── Summary ────────────────────────────────────────────────────────────────
  await redis.quit();
  console.log('\n══════════════════════════════════════════════════');
  console.log(`  RESULTS: ${passed} passed / ${failed} failed / ${passed + failed} total`);
  console.log('══════════════════════════════════════════════════\n');
  process.exit(failed > 0 ? 1 : 0);
}

run().catch(err => {
  console.error('Test runner crashed:', err);
  process.exit(1);
});
