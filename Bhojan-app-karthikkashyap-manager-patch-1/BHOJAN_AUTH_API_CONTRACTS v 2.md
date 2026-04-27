# Bhojan — API Contracts

## Module 1: Authentication \& User Management

**Covers:** User App · Vendor App · Admin App  


Table of Contents

1. [Global Standards](#1-global-standards)
2. [Endpoint Index](#2-endpoint-index)
3. [User App — AUTH Endpoints](#3-user-app--auth-endpoints)
4. [Vendor App — AUTH Endpoints](#4-vendor-app--auth-endpoints)
5. [Admin App — AUTH Endpoints](#5-admin-app--auth-endpoints)
6. [Public Tenant Discovery Endpoints](#6-public-tenant-discovery-endpoints)
7. [Appendix A — DB Tables Referenced](#appendix-a--db-tables-referenced)
8. [Appendix B — What Changed from Old Contracts](#appendix-b--what-changed-from-old-contracts-v21--v42)

\---

## 1\. Global Standards

### 1.1 Standard Response Envelope

Every API response — success or error — must follow this exact structure.

**Success**

```json
{
  "success": true,
  "data": { },
  "message": "optional human-readable string"
}
```

**Error**

```json
{
  "success": false,
  "error": {
    "code": "ERROR\_CODE\_ENUM",
    "message": "Human readable description",
    "details": \[ ]
  }
}
```

> `details` is optional — only included for validation errors (field-level breakdown).

\---

### 1.2 JWT Payload Structure

Every protected endpoint validates a JWT. The payload contains exactly:

```json
{
  "sub":         "user-uuid",
  "role":        "USER | GUEST | VENDOR | SUPER\_ADMIN | OPS\_ADMIN | TECH\_ADMIN",
  "tenant\_id":   "tenant-uuid | null",
  "is\_employee": true,
  "iat":         1713456000,
  "exp":         1713456900
}
```

**Key rules:**

* `tenant\_id` is `null` for **GUEST** users only. SET for USER, VENDOR, and all admin roles.
* `is\_employee` is `true` only for USER role. `false` for GUEST, VENDOR, ADMIN.
* Access token TTL: **15 minutes**
* Refresh token TTL: **7 days** (rotation enforced — single use)

\---

### 1.3 Authentication Header

All protected endpoints require:

```
Authorization: Bearer <access\_token>
```

\---

### 1.4 OTP Global Rules

|Rule|Value|
|-|-|
|OTP Length|6 digits|
|OTP TTL|5 minutes|
|Max Wrong Attempts|3 → account locked for 15 minutes|
|Rate Limit|Max 3 OTP requests per phone per 15 minutes|
|Storage|**Redis ONLY** — NOT PostgreSQL. No `otp\_verifications` table exists.|
|Delivery|SMS to phone number only. Phone is always the identifier.|

\---

### 1.5 Lockout Rules

|Rule|Limit|Duration|Redis Key|
|-|-|-|-|
|OTP wrong attempts|3 wrong OTPs|15 min lockout|`otp:{phone}` attempt counter|
|OTP rate limit|3 requests / 15 min|15 min|`otp\_limit:{phone}`|
|Password wrong attempts|5 wrong passwords|15 min lockout|`login\_attempts:{phone}`|

\---

### 1.6 Redis Key Reference

|Key|TTL|Purpose|
|-|-|-|
|`otp:{phone}`|5 min|OTP for login / registration|
|`otp\_limit:{phone}`|15 min|OTP rate limit counter|
|`login\_attempts:{phone}`|15 min|Password fail counter (max 5)|
|`reg\_pending:{phone}`|10 min|Temporary registration data before OTP verified|
|`blacklist:{token}`|Remaining token life|Revoked access tokens|
|`activation:{uuid}`|24 hours|Vendor one-time account activation token|
|`delegate:{userId}:{module}`|Until `expires\_at`|Active delegation cache|
|`otp\_old:{requestId}`|5 min|Contact change — OTP sent to old contact|
|`otp\_new:{requestId}`|5 min|Contact change — OTP sent to new contact|

\---

### 1.7 Full Error Code Reference

|Error Code|HTTP|When It Occurs|
|-|-|-|
|`VALIDATION\_ERROR`|400|Request body has missing or malformed fields|
|`OTP\_INVALID`|400|OTP does not match Redis value|
|`OTP\_EXPIRED`|400|OTP TTL has passed|
|`OTP\_MAX\_ATTEMPTS`|400|3 wrong OTP attempts — temporary lockout|
|`OTP\_RATE\_LIMIT`|429|More than 3 OTP requests in 15 minutes|
|`ACCOUNT\_LOCKED`|429|5 wrong passwords — locked 15 minutes|
|`USER\_NOT\_FOUND`|404|No user exists with this phone|
|`USER\_ALREADY\_EXISTS`|409|Phone or email already registered|
|`ACCOUNT\_DEACTIVATED`|403|`users.is\_active = false` (offboarded employee)|
|`ACCOUNT\_SUSPENDED`|403|`users.is\_suspended = true`|
|`ACCOUNT\_DELETED`|403|`users.is\_deleted = true` (DPDP soft-delete)|
|`EMAIL\_NOT\_VERIFIED`|403|Vendor has not activated account yet|
|`EMPLOYEE\_ID\_NOT\_FOUND`|409|`employee\_id` not found in `employee\_roster`|
|`ALREADY\_EMPLOYEE`|409|Guest user is already linked to a company|
|`TENANT\_MISMATCH`|403|JWT `tenant\_id` does not match resource `tenant\_id`|
|`TENANT\_CLOSED`|403|Tenant is not accepting new registrations|
|`PERMISSION\_DENIED`|403|Role does not have access to this route|
|`TOKEN\_EXPIRED`|401|Access token expired — client should refresh|
|`REFRESH\_TOKEN\_INVALID`|401|Refresh token not found, revoked, or expired|
|`REFRESH\_TOKEN\_REUSED`|401|Refresh token already used (rotation violation)|
|`SSO\_DOMAIN\_MISMATCH`|403|SSO email domain not in any tenant's domain list|
|`SSO\_PROVIDER\_ERROR`|502|Google / Microsoft OAuth returned an error|
|`DELEGATION\_EXPIRED`|403|Delegation record has passed its `expires\_at`|
|`INTERNAL\_ERROR`|500|Unexpected server error — check Sentry|
|`UNAUTHORIZED`|401|No Bearer token or token malformed|

\---

### 1.8 Priority Legend

|Priority|Meaning|
|-|-|
|`P0`|Must have — blocks launch|
|`P1`|Important — next sprint|
|`P2`|Optional / Enhancement|

\---

## 2\. Endpoint Index

|EP#|Method|Path|Feature|Auth|Priority|
|-|-|-|-|-|-|
|EP-01|POST|`/auth/register`|AUTH-01 — Registration (Guest + Employee)|None|**P0**|
|EP-02|POST|`/auth/otp/verify`|AUTH-01 — OTP Verify (Registration + OTP Login)|None|**P0**|
|EP-03|POST|`/auth/login/password`|AUTH-01 — Password Login|None|**P0**|
|EP-04|POST|`/auth/token/refresh`|AUTH-04 — Token Refresh|Refresh token|**P0**|
|EP-05|POST|`/auth/logout`|AUTH-04 — Logout|Bearer|**P0**|
|EP-06|GET|`/auth/me`|AUTH-07 — Get Profile|Bearer|**P0**|
|EP-07|PUT|`/auth/profile`|AUTH-07 — Update Profile|Bearer|**P1**|
|EP-08|POST|`/auth/profile/avatar`|AUTH-07 — Avatar Upload|Bearer|**P1**|
|EP-09|POST|`/auth/password/reset-request`|AUTH-05 — Password Reset OTP|None|**P1**|
|EP-10|POST|`/auth/password/reset-verify`|AUTH-05 — Set New Password|None|**P1**|
|EP-11|POST|`/auth/contact/change`|AUTH-07b — Contact Change Init|Bearer|**P1**|
|EP-12|POST|`/auth/contact/verify`|AUTH-07b — Contact Change Confirm|Bearer|**P1**|
|EP-13|DELETE|`/auth/account`|AUTH-07a — Account Deletion (DPDP)|Bearer|**P2**|
|EP-14|POST|`/auth/upgrade-to-employee`|AUTH-01c — Guest → Employee Upgrade|Bearer|**P1**|
|EP-15|GET|`/auth/sso/google`|AUTH-10 — Google SSO Redirect|None|**P2**|
|EP-16|GET|`/auth/sso/google/callback`|AUTH-10 — Google SSO Callback|None|**P2**|
|EP-17|POST|`/vendor/auth/activate`|AUTH-02 — Vendor Account Activation|None|**P0**|
|EP-18|POST|`/vendor/auth/login`|AUTH-03 — Vendor Login|None|**P0**|
|EP-19|PUT|`/vendor/auth/profile`|AUTH-07 — Vendor Profile Update|Bearer|**P1**|
|EP-20|POST|`/admin/auth/login`|AUTH-03 — Admin Login|None|**P0**|
|EP-21|GET|`/admin/auth/permissions`|AUTH-03a — Admin Permissions|Bearer|**P0**|
|EP-22|GET|`/admin/audit-logs`|AUTH-09 — Audit Log Query|Bearer|**P0**|
|EP-23|GET|`/admin/audit-logs/export`|AUTH-09 — Audit Log CSV Export (async)|Bearer|**P1**|
|EP-24|POST|`/admin/employees/bulk-upload`|AUTH-06b — Bulk Employee Upload|Bearer|**P0**|
|EP-25|GET|`/admin/employees/bulk-upload/:id`|AUTH-06b — Upload Status Poll|Bearer|**P0**|
|EP-26|POST|`/admin/employees/:id/offboard`|AUTH-06a — Employee Offboarding|Bearer|**P0**|
|EP-27|POST|`/admin/vendors`|AUTH-02 — Vendor Onboarding|Bearer|**P0**|
|EP-28|POST|`/admin/vendors/:id/suspend`|AUTH-12 — Vendor Suspend|Bearer|**P0**|
|EP-29|POST|`/admin/vendors/:id/reactivate`|AUTH-12 — Vendor Reactivate|Bearer|**P0**|
|EP-30|POST|`/admin/delegations`|AUTH-11 — Create Delegation|Bearer|**P1**|
|EP-31|GET|`/admin/delegations`|AUTH-11 — List Delegations|Bearer|**P1**|
|EP-32|DELETE|`/admin/delegations/:id`|AUTH-11 — Revoke Delegation|Bearer|**P1**|
|EP-33|GET|`/admin/sessions`|AUTH-04 — View Sessions|Bearer|**P1**|
|EP-34|DELETE|`/admin/sessions/:id`|AUTH-04 — Revoke Session|Bearer|**P1**|
|EP-35|GET|`/tenants`|TENANT-01 — Tenant Discovery \& Selection|None|**P0**|
|EP-36|GET|`/tenants/:id/settings`|TENANT-02 — Tenant Configuration Fetch|None|**P0**|
|EP-37|POST|`/tenants/validate`|TENANT-03 — Pre-Registration Validation|None|**P0**|

\---

## 3\. User App — AUTH Endpoints

\---

### EP-01 · POST `/auth/register`

**Feature:** AUTH-01 — User Registration (Guest and Employee flows)  
**Auth:** None (public) | **Priority:** P0

Initiates registration for a new user. Behaviour is completely different based on `user\_type`. Sends OTP to phone. **User record is NOT created yet** — created only after OTP is verified in EP-02.

**Headers**

|Header|Value|Required|
|-|-|-|
|`Content-Type`|application/json|Yes|

**Request Body — when `user\_type = "GUEST"`**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`user\_type`|string|Yes|Must be `"GUEST"`|—|
|`full\_name`|string|Yes|User's full name|`users.full\_name`|
|`phone`|string|Yes|Format: `+91XXXXXXXXXX`|`users.phone`|
|`password`|string|Yes|Min 8 chars, 1 uppercase, 1 number, 1 special char|`users.password\_hash`|

**Request Body — when `user\_type = "EMPLOYEE"`**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`user\_type`|string|Yes|Must be `"EMPLOYEE"`|—|
|`full\_name`|string|Yes|User's full name|`users.full\_name`|
|`phone`|string|Yes|Format: `+91XXXXXXXXXX`|`users.phone`|
|`email`|string|Yes|Work email address|`users.email`|
|`employee\_id`|string|Yes|Company employee ID — validated against roster|`users.employee\_id`|
|`password`|string|Yes|Min 8 chars, 1 uppercase, 1 number, 1 special char|`users.password\_hash`|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "otp\_reference": "ref-uuid",
    "expires\_in": 300
  }
}
```

> `otp\_reference` is an internal tracking UUID — not the OTP value itself.

**Backend Workflow — GUEST**

1. Validate `full\_name`, `phone` format, password strength
2. Check `phone` not already registered in `users` → 409 `USER\_ALREADY\_EXISTS`
3. Check OTP rate limit: `otp\_limit:{phone}` → 429 `OTP\_RATE\_LIMIT` if exceeded
4. Hash password with bcrypt (salt: 12)
5. Store temp data in Redis: `reg\_pending:{phone}` TTL 10 min → `{ full\_name, password\_hash, user\_type: "GUEST" }`
6. Generate OTP → store in Redis: `otp:{phone}` TTL 5 min
7. Send OTP via SMS (Firebase FCM)
8. Log `AuditAction.OTP\_REQUESTED`
9. Return 200 with `otp\_reference`

**Backend Workflow — EMPLOYEE**

1. Validate all fields: `full\_name`, `phone`, `email` format, `employee\_id`, password strength
2. Check `phone` not already registered → 409 `USER\_ALREADY\_EXISTS`
3. Check `email` not already registered → 409 `USER\_ALREADY\_EXISTS`
4. Check OTP rate limit
5. Look up `employee\_id` in `employee\_roster` WHERE `is\_active = true` → 409 `EMPLOYEE\_ID\_NOT\_FOUND` if not found
6. Extract `tenant\_id` from matching roster row — **do NOT trust any client-provided tenant\_id**
7. Hash password (bcrypt, salt: 12)
8. Store temp data in Redis: `reg\_pending:{phone}` TTL 10 min → `{ full\_name, password\_hash, email, employee\_id, tenant\_id, user\_type: "EMPLOYEE" }`
9. Generate OTP → store in Redis: `otp:{phone}` TTL 5 min
10. Send OTP via SMS
11. Log `AuditAction.OTP\_REQUESTED`
12. Return 200 with `otp\_reference`

**DB Fields Touched**

* `employee\_roster` (READ — employee validation, EMPLOYEE only)
* `users.phone`, `users.email` (READ — duplicate check)
* `audit\_logs` (WRITE)

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|400|`VALIDATION\_ERROR`|Missing/invalid fields or phone format|
|409|`USER\_ALREADY\_EXISTS`|Phone or email already registered|
|409|`EMPLOYEE\_ID\_NOT\_FOUND`|`employee\_id` not in roster (EMPLOYEE only)|
|429|`OTP\_RATE\_LIMIT`|More than 3 OTP requests in 15 min (`Retry-After: 900s`)|

\---

### EP-02 · POST `/auth/otp/verify`

**Feature:** AUTH-01 — OTP Verification  
**Auth:** None (public) | **Priority:** P0

Dual-purpose endpoint — handles both **registration completion** (new user) and **OTP login** (existing user). Backend determines which path to take by checking for `reg\_pending:{phone}` in Redis.

**Headers**

|Header|Value|Required|
|-|-|-|
|`Content-Type`|application/json|Yes|

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`phone`|string|Yes|Phone used in EP-01 or on OTP login screen|`users.phone`|
|`otp`|string|Yes|6-digit OTP from SMS|Redis|

**Success Response — 201 Created (new user) / 200 OK (existing user)**

```json
{
  "success": true,
  "data": {
    "access\_token": "eyJ...",
    "refresh\_token": "eyJ...",
    "user": {
      "id": "uuid",
      "phone": "+91XXXXXXXXXX",
      "full\_name": "Name",
      "role": "USER | GUEST",
      "tenant\_id": "uuid | null",
      "is\_employee": true,
      "is\_verified": true
    }
  }
}
```

**Backend Workflow — REGISTRATION PATH** *(when `reg\_pending:{phone}` exists in Redis)*

1. Retrieve `reg\_pending:{phone}` — if not found, fall through to Login Path
2. Retrieve `otp:{phone}` from Redis → 400 `OTP\_EXPIRED` if not found
3. Compare OTP → 400 `OTP\_INVALID`, increment attempt counter → 400 `OTP\_MAX\_ATTEMPTS` after 3 failures
4. Create `users` record from Redis temp data:

   * `user\_type = "GUEST"` → `role = GUEST`, `tenant\_id = NULL`, `is\_employee = false`
   * `user\_type = "EMPLOYEE"` → `role = USER`, `tenant\_id = from\_roster`, `is\_employee = true`, `email = work\_email`, `employee\_id = input`
5. Set `is\_verified = true`, `is\_active = true`
6. Delete `reg\_pending:{phone}` and `otp:{phone}` from Redis (one-time use)
7. Supabase trigger `auto\_create\_user\_profile` auto-creates `user\_profiles` record — do NOT manually insert
8. Generate JWT access + refresh tokens
9. Create `sessions` record
10. Log `AuditAction.USER\_REGISTER` (EMPLOYEE) or `AuditAction.GUEST\_REGISTER` (GUEST)
11. Return 201

**Backend Workflow — OTP LOGIN PATH** *(when `reg\_pending:{phone}` does NOT exist in Redis)*

1. Look up user by `phone` in `users` table → 404 `USER\_NOT\_FOUND`
2. Check `is\_active`, `is\_suspended`, `is\_deleted` → 403 accordingly
3. Retrieve `otp:{phone}` from Redis → 400 `OTP\_EXPIRED` if not found
4. Compare OTP → 400 `OTP\_INVALID`, increment attempt counter
5. Delete `otp:{phone}` from Redis (one-time use)
6. Generate JWT access + refresh tokens
7. Create `sessions` record
8. Update `users.last\_login\_at`
9. Log `AuditAction.USER\_LOGIN`
10. Return 200

**DB Fields Touched**

* `users` (READ + conditional WRITE — create on registration)
* `user\_profiles` (WRITE — auto via Supabase trigger on INSERT)
* `sessions` (WRITE)
* `audit\_logs` (WRITE)

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|400|`OTP\_INVALID`|Wrong OTP entered|
|400|`OTP\_EXPIRED`|OTP TTL passed|
|400|`OTP\_MAX\_ATTEMPTS`|3 wrong attempts|
|404|`USER\_NOT\_FOUND`|Login path — phone not registered|
|403|`ACCOUNT\_DEACTIVATED`|Login path — `is\_active = false`|
|403|`ACCOUNT\_SUSPENDED`|Login path — `is\_suspended = true`|
|403|`ACCOUNT\_DELETED`|Login path — `is\_deleted = true`|

\---

### EP-03 · POST `/auth/login/password`

**Feature:** AUTH-01 — Password Login (Guest and Employee)  
**Auth:** None (public) | **Priority:** P0

Login using phone + password. Works for both GUEST and USER roles. Phone is always the login identifier — email is never used for login.

**Headers**

|Header|Value|Required|
|-|-|-|
|`Content-Type`|application/json|Yes|

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`phone`|string|Yes|Format: `+91XXXXXXXXXX`|`users.phone`|
|`password`|string|Yes|User's password|`users.password\_hash`|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "access\_token": "eyJ...",
    "refresh\_token": "eyJ...",
    "user": {
      "id": "uuid",
      "phone": "+91XXXXXXXXXX",
      "full\_name": "Name",
      "role": "USER | GUEST",
      "tenant\_id": "uuid | null",
      "is\_employee": true
    }
  }
}
```

**Backend Workflow**

1. Look up user by `phone` → 404 `USER\_NOT\_FOUND`
2. Check `is\_active`, `is\_suspended`, `is\_deleted` flags → 403 accordingly
3. Check `login\_attempts:{phone}` in Redis → 429 `ACCOUNT\_LOCKED` if ≥ 5
4. bcrypt compare password → if mismatch, increment Redis counter → 401 `AUTH\_LOGIN\_FAILED`
5. Log `AuditAction.AUTH\_LOGIN\_FAILED` with `metadata: { attempt\_count }` on each failure
6. From the 3rd failed attempt, include "X attempts remaining" in the response `message` field
7. On success: delete `login\_attempts:{phone}` counter
8. Generate JWT access + refresh tokens
9. Create `sessions` record
10. Update `users.last\_login\_at`
11. Log `AuditAction.USER\_LOGIN`

**DB Fields Touched**

* `users` (READ + UPDATE `last\_login\_at`)
* `sessions` (WRITE)
* `audit\_logs` (WRITE)

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|400|`VALIDATION\_ERROR`|Missing fields|
|404|`USER\_NOT\_FOUND`|Phone not registered|
|403|`ACCOUNT\_DEACTIVATED`|`is\_active = false`|
|403|`ACCOUNT\_SUSPENDED`|`is\_suspended = true`|
|403|`ACCOUNT\_DELETED`|`is\_deleted = true`|
|401|`AUTH\_LOGIN\_FAILED`|Wrong password|
|429|`ACCOUNT\_LOCKED`|5 failed attempts — locked 15 min|

\---

### EP-04 · POST `/auth/token/refresh`

**Feature:** AUTH-04 — Token Refresh  
**Auth:** Refresh token (in body) | **Priority:** P0

Exchange a valid refresh token for a new access + refresh token pair. Old refresh token is immediately revoked (rotation enforced — single use).

**Request Body**

|Field|Type|Required|Description|
|-|-|-|-|
|`refresh\_token`|string|Yes|Current valid refresh token|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "access\_token": "eyJ...",
    "refresh\_token": "eyJ..."
  }
}
```

**Backend Workflow**

1. Find session in `sessions` WHERE `refresh\_token = request.refresh\_token` AND `is\_revoked = false`
2. If not found or `is\_revoked = true` → 401 `REFRESH\_TOKEN\_INVALID`
3. If already used → 401 `REFRESH\_TOKEN\_REUSED` (security alert — potential token theft)
4. Check `expires\_at` not past → 401 `REFRESH\_TOKEN\_INVALID`
5. Validate user flags (`is\_active`, `is\_suspended`, `is\_deleted`)
6. Revoke old session: `SET is\_revoked = true`
7. Add old refresh token to Redis blacklist: `blacklist:{old\_token}` TTL = 7d
8. Issue new access token (15 min) + new refresh token (7 days)
9. Create new `sessions` record
10. Log `AuditAction.TOKEN\_REFRESH`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|401|`REFRESH\_TOKEN\_INVALID`|Token not found, expired, or revoked|
|401|`REFRESH\_TOKEN\_REUSED`|Token already used — rotation violation|
|403|`ACCOUNT\_DEACTIVATED`|User deactivated between refresh calls|

\---

### EP-05 · POST `/auth/logout`

**Feature:** AUTH-04 — Logout  
**Auth:** Bearer | **Priority:** P0

Logout current session. Revokes the session and blacklists both tokens in Redis.

**Headers**

|Header|Value|Required|
|-|-|-|
|`Authorization`|Bearer <access\_token>|Yes|
|`Content-Type`|application/json|Yes|

**Request Body**

|Field|Type|Required|Description|
|-|-|-|-|
|`refresh\_token`|string|Yes|Current session's refresh token to revoke|

**Success Response — 200 OK**

```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

**Backend Workflow**

1. Validate Bearer access token
2. Find session WHERE `refresh\_token = request.refresh\_token` AND `user\_id = jwt.sub`
3. SET `sessions.is\_revoked = true`
4. Add access token to Redis blacklist: `blacklist:{access\_token}` TTL = remaining token life
5. Add refresh token to Redis blacklist: `blacklist:{refresh\_token}` TTL = 7d
6. Log `AuditAction.USER\_LOGOUT`

> Even if access token is expired, allow logout if refresh token is valid — always let users log out.  
> Client must discard both tokens from local storage after this call.

\---

### EP-06 · GET `/auth/me`

**Feature:** AUTH-07 — Get Profile  
**Auth:** Bearer | **Priority:** P0

Returns the authenticated user's full profile. Works for USER and GUEST roles.

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "phone": "+91XXXXXXXXXX",
      "email": "work@company.com | null",
      "full\_name": "Name",
      "role": "USER | GUEST",
      "tenant\_id": "uuid | null",
      "is\_employee": true,
      "employee\_id": "EMP001 | null",
      "last\_login\_at": "ISO8601"
    },
    "profile": {
      "avatar\_url": "https://storage.googleapis.com/...",
      "department": "Engineering | null",
      "floor": "3 | null",
      "building": "Block A | null",
      "preferences": {
        "dietary": "VEG",
        "notifications": { "order": true, "promo": false },
        "language": "en"
      }
    }
  }
}
```

**DB Fields Touched**

* `users` (READ)
* `user\_profiles` (READ)

\---

### EP-07 · PUT `/auth/profile`

**Feature:** AUTH-07 — Update Profile  
**Auth:** Bearer | **Priority:** P1

Partial update of the user's profile. Only provided fields are updated.

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`full\_name`|string|No|Display name|`users.full\_name` + `user\_profiles.full\_name`|
|`department`|string|No|Office department|`user\_profiles.department`|
|`floor`|string|No|Floor number|`user\_profiles.floor`|
|`building`|string|No|Building name|`user\_profiles.building`|
|`preferences`|object|No|`{ dietary, notifications, language }`|`user\_profiles.preferences`|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "profile": { }
  }
}
```

**Backend Workflow**

1. Validate Bearer token
2. Partial UPDATE `user\_profiles` WHERE `user\_id = jwt.sub`
3. If `full\_name` provided, also sync to `users.full\_name`
4. Log `AuditAction.PROFILE\_UPDATED`

> Phone and email changes → EP-11 / EP-12. Password change → EP-09 / EP-10.

\---

### EP-08 · POST `/auth/profile/avatar`

**Feature:** AUTH-07 — Avatar Upload  
**Auth:** Bearer | **Priority:** P1

Upload a profile avatar. Stored in Google Cloud Storage.

**Request** — `multipart/form-data`

|Field|Type|Required|Description|
|-|-|-|-|
|`avatar`|file|Yes|JPEG/PNG, max 5MB|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "avatar\_url": "https://storage.googleapis.com/bhojan-avatars/uuid.jpg"
  }
}
```

**DB Fields Touched** — `user\_profiles.avatar\_url` (UPDATE)

\---

### EP-09 · POST `/auth/password/reset-request`

**Feature:** AUTH-05 — Password Reset OTP  
**Auth:** None (public) | **Priority:** P1

Initiate a password reset. Sends OTP to registered phone. **Always returns 200** regardless of whether account exists — prevents account enumeration attacks.

**Request Body**

|Field|Type|Required|Description|
|-|-|-|-|
|`phone`|string|Yes|Registered phone number|

**Success Response — 200 OK (always)**

```json
{
  "success": true,
  "message": "If an account exists, an OTP has been sent"
}
```

**Backend Workflow**

1. Look up user by `phone` — if not found, **return 200 silently** (do NOT reveal)
2. If found but `is\_deleted = true`, **return 200 silently**
3. Check OTP rate limit → 429 `OTP\_RATE\_LIMIT` if exceeded
4. Store OTP in Redis: `otp:{phone}` TTL 5 min with type tag `PASSWORD\_RESET` (prevents cross-type OTP reuse — a login OTP cannot reset password)
5. Send OTP via SMS
6. Log `AuditAction.PASSWORD\_RESET\_REQUESTED`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|429|`OTP\_RATE\_LIMIT`|Rate limit exceeded|

> Never return `USER\_NOT\_FOUND` from this endpoint.

\---

### EP-10 · POST `/auth/password/reset-verify`

**Feature:** AUTH-05 — Set New Password  
**Auth:** None (public) | **Priority:** P1

Verify OTP and set a new password. All existing sessions are revoked after reset.

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`phone`|string|Yes|Registered phone number|`users.phone`|
|`otp`|string|Yes|6-digit OTP|Redis|
|`new\_password`|string|Yes|Min 8 chars, 1 uppercase, 1 number, 1 special|`users.password\_hash`|

**Success Response — 200 OK**

```json
{
  "success": true,
  "message": "Password reset successful. Please log in again."
}
```

**Backend Workflow**

1. Look up user by `phone` → 404 `USER\_NOT\_FOUND`
2. Verify OTP from Redis `otp:{phone}` — validate type tag = `PASSWORD\_RESET` → 400 `OTP\_INVALID` / `OTP\_EXPIRED`
3. Validate `new\_password` strength
4. Hash new password (bcrypt, salt: 12)
5. UPDATE `users.password\_hash`
6. Revoke ALL sessions: `SET is\_revoked = true` WHERE `user\_id = user.id`
7. Add all active refresh tokens to Redis blacklist
8. Delete `otp:{phone}` from Redis
9. Log `AuditAction.PASSWORD\_RESET` + `AuditAction.ALL\_SESSIONS\_REVOKED`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|404|`USER\_NOT\_FOUND`|Phone not registered|
|400|`OTP\_INVALID`|Wrong OTP|
|400|`OTP\_EXPIRED`|OTP TTL passed|
|400|`VALIDATION\_ERROR`|Password doesn't meet requirements|

\---

### EP-11 · POST `/auth/contact/change`

**Feature:** AUTH-07b — Contact Change Initiation  
**Auth:** Bearer | **Priority:** P1

Initiate a phone or email change. Sends OTP to both old and new contact for dual verification (anti-hijack).

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`type`|string|Yes|`"EMAIL"` or `"PHONE"`|`contact\_change\_requests.type`|
|`new\_value`|string|Yes|New phone `+91...` or email address|`contact\_change\_requests.new\_value`|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "request\_id": "uuid",
    "message": "OTP sent to both current and new contact"
  }
}
```

**Backend Workflow**

1. Validate Bearer token
2. Validate `new\_value` format
3. Check `new\_value` not already taken → 409 `USER\_ALREADY\_EXISTS`
4. Fetch user's current value from `users` (old contact)
5. Create `contact\_change\_requests` record: `status = PENDING`
6. Generate two OTPs — one for old contact, one for new contact
7. Store: `otp\_old:{request\_id}` TTL 5 min, `otp\_new:{request\_id}` TTL 5 min
8. Send OTP to OLD contact (proves requester owns account)
9. Send OTP to NEW contact (proves new contact is accessible by requester)
10. Log `AuditAction.OTP\_REQUESTED`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|400|`VALIDATION\_ERROR`|Invalid email/phone format|
|409|`USER\_ALREADY\_EXISTS`|New contact already registered|
|401|`UNAUTHORIZED`|Invalid token|

\---

### EP-12 · POST `/auth/contact/verify`

**Feature:** AUTH-07b — Contact Change Confirm  
**Auth:** Bearer | **Priority:** P1

Submit both OTPs to complete the contact change. Both must be correct. On success, all sessions revoked and new JWT issued.

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`request\_id`|string|Yes|UUID from EP-11 response|`contact\_change\_requests.id`|
|`otp\_old`|string|Yes|OTP sent to OLD contact|Redis|
|`otp\_new`|string|Yes|OTP sent to NEW contact|Redis|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "access\_token": "eyJ...",
    "refresh\_token": "eyJ...",
    "message": "Contact updated. All sessions revoked."
  }
}
```

**Backend Workflow**

1. Validate Bearer token
2. Fetch `contact\_change\_requests` WHERE `id = request\_id` AND `user\_id = jwt.sub` AND `status = PENDING`
3. Verify `otp\_old` from Redis `otp\_old:{request\_id}` → 400 `OTP\_INVALID` if mismatch
4. Verify `otp\_new` from Redis `otp\_new:{request\_id}` → 400 `OTP\_INVALID` if mismatch
5. Both must pass — if either fails, do not apply change
6. UPDATE `users.email` or `users.phone` with `new\_value`
7. UPDATE `contact\_change\_requests`: `status = COMPLETED`, `otp\_verified = true`, `completed\_at = now()`
8. Revoke ALL existing sessions
9. Delete Redis OTP keys
10. Issue new JWT with updated contact
11. Log `AuditAction.EMAIL\_CHANGED` or `AuditAction.PHONE\_CHANGED`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|400|`OTP\_INVALID`|Either OTP is wrong — both must be correct|
|400|`OTP\_EXPIRED`|Either OTP has expired — restart from EP-11|
|401|`UNAUTHORIZED`|Invalid token|

\---

### EP-13 · DELETE `/auth/account`

**Feature:** AUTH-07a — Account Deletion (DPDP Act 2023)  
**Auth:** Bearer | **Priority:** P2

Soft-delete the user account. PII is anonymised. Order history is retained for tax compliance.

**Request Body**

|Field|Type|Required|Description|
|-|-|-|-|
|`otp`|string|Yes|OTP sent to phone for deletion confirmation|
|`reason`|string|No|Optional reason for deletion|

**Success Response — 200 OK**

```json
{
  "success": true,
  "message": "Account deletion processed. You have been logged out."
}
```

**Backend Workflow**

1. Validate Bearer token
2. Verify OTP from Redis `otp:{phone}`
3. Create `account\_deletion\_requests` record: `status = PENDING`
4. SET `users.is\_deleted = true`, `users.deleted\_at = now()` — login blocked immediately
5. SET `users.is\_active = false`
6. Anonymise PII:

   * `users.email` → `deleted\_{uuid}@bhojan.deleted`
   * `users.phone` → `deleted\_{uuid}` (**NOT NULL** — phone is non-nullable per schema v4.2)
   * `user\_profiles.full\_name` → `Deleted User`
   * `user\_profiles.avatar\_url`, `department`, `floor`, `building` → NULL
7. Revoke ALL sessions
8. UPDATE `account\_deletion\_requests`: `status = ANONYMIZED` → `status = COMPLETED`
9. Log `AuditAction.ACCOUNT\_DELETED` + `AuditAction.ACCOUNT\_ANONYMIZED`

> Order history rows (`user\_id` FK) are retained — required for tax compliance. Only PII is removed.

\---

### EP-14 · POST `/auth/upgrade-to-employee`

**Feature:** AUTH-01c — Guest → Employee Upgrade  
**Auth:** Bearer (GUEST role only) | **Priority:** P1

A guest user who later gets a company employee ID can upgrade their existing account without creating a new one. Subsidy and benefits activated immediately.

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`employee\_id`|string|Yes|Company employee ID|`users.employee\_id`|
|`work\_email`|string|Yes|Work email — validated against roster|`users.email`|
|`otp`|string|Yes|OTP sent to registered phone for confirmation|Redis|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "access\_token": "eyJ...",
    "refresh\_token": "eyJ...",
    "user": {
      "id": "uuid",
      "role": "USER",
      "tenant\_id": "uuid",
      "is\_employee": true
    },
    "message": "Account upgraded. Subsidy and benefits activated."
  }
}
```

**Backend Workflow**

1. Validate Bearer token — must have `role = GUEST` → 403 `PERMISSION\_DENIED` otherwise
2. Check user is not already an employee → 409 `ALREADY\_EMPLOYEE`
3. Look up `employee\_id` in `employee\_roster` WHERE `is\_active = true` (across any tenant)
4. If not found → 409 `EMPLOYEE\_ID\_NOT\_FOUND`
5. Verify `work\_email` matches `employee\_roster.email` for the matched row → 400 `VALIDATION\_ERROR` if mismatch
6. Verify OTP from Redis `otp:{phone}`
7. Create `guest\_upgrade\_requests` record: `status = PENDING`
8. UPDATE `users`:

   * `role = USER`, `tenant\_id = found tenant`, `is\_employee = true`
   * `employee\_id = input`, `email = work\_email`
9. UPDATE `guest\_upgrade\_requests`: `status = COMPLETED`
10. Revoke all old sessions (tenant scope changed — old JWTs are now invalid)
11. Issue new JWT with updated `tenant\_id`, `role = USER`, `is\_employee = true`
12. Log `AuditAction.PROFILE\_UPGRADED`

**DB Fields Touched**

* `employee\_roster` (READ)
* `users` (UPDATE)
* `guest\_upgrade\_requests` (WRITE)
* `sessions` (UPDATE all + WRITE new)
* `audit\_logs` (WRITE)

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|403|`PERMISSION\_DENIED`|Non-GUEST token used|
|409|`ALREADY\_EMPLOYEE`|User already linked to a company|
|409|`EMPLOYEE\_ID\_NOT\_FOUND`|`employee\_id` not in any roster|
|400|`VALIDATION\_ERROR`|`work\_email` doesn't match roster email|
|400|`OTP\_INVALID`|Wrong OTP|
|401|`UNAUTHORIZED`|Invalid token|

\---

### EP-15 · GET `/auth/sso/google`

**Feature:** AUTH-10 — Google SSO Redirect  
**Auth:** None (public) | **Priority:** P2

Redirects to Google OAuth consent page for employee SSO login.

**Success:** 302 Redirect to Google OAuth URL — no JSON response.

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|502|`SSO\_PROVIDER\_ERROR`|Google OAuth configuration error|

\---

### EP-16 · GET `/auth/sso/google/callback`

**Feature:** AUTH-10 — Google SSO Callback  
**Auth:** None (OAuth callback) | **Priority:** P2

Google redirects here after authentication. Creates or logs in the user.

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "access\_token": "eyJ...",
    "refresh\_token": "eyJ...",
    "user": {
      "id": "uuid",
      "email": "user@company.com",
      "role": "USER",
      "tenant\_id": "uuid",
      "is\_employee": true
    }
  }
}
```

**Backend Workflow**

1. NestJS Passport exchanges Google auth code for user info (email, name, sub)
2. Validate email domain against `tenants.domain` → 403 `SSO\_DOMAIN\_MISMATCH` if not found
3. Extract `tenant\_id` from matching tenant row
4. Check if user exists by `email` in `users`
5. **New user:** Create record (`role = USER`, `is\_verified = true`, `is\_employee = true`, `sso\_provider = GOOGLE`, `sso\_provider\_id = Google sub`, `tenant\_id` from domain match)
6. **Existing user:** Validate `is\_active`, `is\_suspended`, `is\_deleted`
7. Generate JWT tokens, create `sessions` record
8. Update `users.last\_login\_at`
9. Log `AuditAction.SSO\_LOGIN` with `metadata: { provider: 'GOOGLE' }`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|403|`SSO\_DOMAIN\_MISMATCH`|Email domain not in any tenant|
|502|`SSO\_PROVIDER\_ERROR`|Google returned error|
|403|`ACCOUNT\_DEACTIVATED`|Existing user is deactivated|

\---

## 4\. Vendor App — AUTH Endpoints

> \*\*Critical:\*\* Vendor registration is \*\*admin-created only\*\*. No public self-registration. Ops Admin creates the vendor account (EP-27). Vendor receives activation email and activates via EP-17.

\---

### EP-17 · POST `/vendor/auth/activate`

**Feature:** AUTH-02 / AUTH-02a — Vendor Account Activation  
**Auth:** None (public) | **Priority:** P0

Vendor activates their account using the one-time token from the activation email. Sets password. Marks account as verified.

**Headers**

|Header|Value|Required|
|-|-|-|
|`Content-Type`|application/json|Yes|

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`activation\_token`|string|Yes|One-time token from activation email|Redis: `activation:{uuid}` TTL 24h|
|`password`|string|Yes|Min 8 chars, 1 uppercase, 1 number, 1 special|`users.password\_hash`|

**Success Response — 200 OK**

```json
{
  "success": true,
  "message": "Account activated. Please log in."
}
```

**Backend Workflow**

1. Look up `activation:{token}` in Redis → 401 `UNAUTHORIZED` if not found or expired (24h TTL)
2. Retrieve `user\_id` from token value
3. Fetch user WHERE `id = user\_id` AND `role = VENDOR`
4. Validate password strength
5. Hash password (bcrypt, salt: 12)
6. UPDATE `users`: `password\_hash`, `is\_verified = true`, `is\_active = true`
7. Delete activation token from Redis (one-time use)
8. Log `AuditAction.VENDOR\_ACTIVATED` + `AuditAction.EMAIL\_VERIFIED`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|400|`VALIDATION\_ERROR`|Password too weak|
|401|`UNAUTHORIZED`|Token not found in Redis (expired or already used)|

\---

### EP-18 · POST `/vendor/auth/login`

**Feature:** AUTH-03 — Vendor Login  
**Auth:** None (public) | **Priority:** P0

Vendor login using phone + password. Phone is the login identifier (consistent with all roles per schema v4.2).

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`phone`|string|Yes|Vendor's registered phone number|`users.phone`|
|`password`|string|Yes|Vendor's password|`users.password\_hash`|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "access\_token": "eyJ...",
    "refresh\_token": "eyJ...",
    "user": {
      "id": "uuid",
      "phone": "+91XXXXXXXXXX",
      "role": "VENDOR",
      "tenant\_id": "uuid",
      "is\_verified": true
    }
  }
}
```

**Backend Workflow**

1. Look up user by `phone` WHERE `role = VENDOR` → 404 `USER\_NOT\_FOUND`
2. Check `is\_verified = true` → 403 `EMAIL\_NOT\_VERIFIED` (vendor hasn't completed EP-17 yet)
3. Check `is\_active`, `is\_suspended`, `is\_deleted` → 403 accordingly
4. Check `login\_attempts:{phone}` counter → 429 `ACCOUNT\_LOCKED` if ≥ 5
5. bcrypt compare password → 401 `AUTH\_LOGIN\_FAILED` if mismatch, increment counter
6. On success: delete `login\_attempts:{phone}` counter
7. Generate JWT tokens
8. Create `sessions` record
9. Update `users.last\_login\_at`
10. Log `AuditAction.VENDOR\_LOGIN`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|404|`USER\_NOT\_FOUND`|Phone not found|
|403|`EMAIL\_NOT\_VERIFIED`|Vendor has not completed activation (EP-17)|
|403|`ACCOUNT\_SUSPENDED`|Vendor suspended by admin|
|403|`ACCOUNT\_DEACTIVATED`|Vendor deactivated|
|401|`AUTH\_LOGIN\_FAILED`|Wrong password|
|429|`ACCOUNT\_LOCKED`|5 failed attempts|

\---

### EP-19 · PUT `/vendor/auth/profile`

**Feature:** AUTH-07 — Vendor Profile Update  
**Auth:** Bearer (VENDOR role) | **Priority:** P1

Update vendor profile fields. Partial update — only provided fields change.

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`business\_name`|string|No|Outlet display name|`vendor\_profiles.business\_name`|
|`business\_address`|string|No|Physical address|`vendor\_profiles.business\_address`|
|`city`|string|No|City|`vendor\_profiles.city`|
|`logo\_url`|string|No|Outlet logo GCS URL|`vendor\_profiles.logo\_url`|
|`fssai\_number`|string|No|FSSAI license number|`vendor\_profiles.fssai\_number`|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "vendor\_profile": { }
  }
}
```

**Backend Workflow**

1. Validate Bearer token — must have `role = VENDOR`
2. Partial UPDATE `vendor\_profiles` WHERE `user\_id = jwt.sub`
3. Log `AuditAction.PROFILE\_UPDATED`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|401|`UNAUTHORIZED`|Invalid token|
|403|`PERMISSION\_DENIED`|Non-VENDOR token used|

> `bank\_name`, `account\_number`, `ifsc\_code` updates are restricted in Phase 1 — require admin approval in Phase 2.

\---

## 5\. Admin App — AUTH Endpoints

> Roles: `SUPER\_ADMIN`, `OPS\_ADMIN`, `TECH\_ADMIN` — \*\*Sub Admin is NOT in Phase 1.\*\*

\---

### EP-20 · POST `/admin/auth/login`

**Feature:** AUTH-03 — Admin Login  
**Auth:** None (public) | **Priority:** P0

Admin login via email + OTP. Admins use **email** to log in (not phone). Role fetched from DB after authentication.

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`email`|string|Yes|Admin's registered email|`users.email`|
|`otp`|string|Yes|6-digit OTP sent to admin email|Redis|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "access\_token": "eyJ...",
    "refresh\_token": "eyJ...",
    "user": {
      "id": "uuid",
      "email": "admin@bhojan.com",
      "role": "SUPER\_ADMIN | OPS\_ADMIN | TECH\_ADMIN",
      "tenant\_id": "uuid"
    }
  }
}
```

**Backend Workflow**

1. Look up user by `email` WHERE `role IN (SUPER\_ADMIN, OPS\_ADMIN, TECH\_ADMIN)` → 404 `USER\_NOT\_FOUND`
2. Check `is\_active`, `is\_deleted`
3. Verify OTP from Redis `otp:{email}`
4. Generate JWT tokens, create `sessions` record
5. Update `users.last\_login\_at`
6. Log `AuditAction.ADMIN\_LOGIN`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|404|`USER\_NOT\_FOUND`|No admin with this email|
|400|`OTP\_INVALID`|Wrong OTP|
|400|`OTP\_EXPIRED`|OTP TTL passed|
|403|`ACCOUNT\_DEACTIVATED`|Admin deactivated|

\---

### EP-21 · GET `/admin/auth/permissions`

**Feature:** AUTH-03a — Admin Permissions  
**Auth:** Bearer (any admin role) | **Priority:** P0

Returns full RBAC permission matrix for the authenticated admin's role plus any active delegations. Frontend uses this to show/hide menu items.

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "role": "OPS\_ADMIN",
    "permissions": \[
      {
        "module": "VENDOR",
        "can\_create": true,
        "can\_read": true,
        "can\_update": true,
        "can\_delete": false
      }
    ],
    "delegations": \[
      {
        "module": "FINANCE",
        "expires\_at": "2026-04-30T18:00:00Z"
      }
    ]
  }
}
```

**Backend Workflow**

1. Validate Bearer token — role must be admin
2. Fetch `role\_permissions` WHERE `role = jwt.role`
3. Check Redis for active delegation keys: `delegate:{userId}:{module}`
4. Merge base permissions + delegation grants

\---

### EP-22 · GET `/admin/audit-logs`

**Feature:** AUTH-09 — Audit Log Query  
**Auth:** Bearer (all admin roles) | **Priority:** P0

Query audit logs with filters. `SUPER\_ADMIN` + `TECH\_ADMIN` see all tenants. `OPS\_ADMIN` sees own tenant only (enforced by Supabase RLS).

**Query Parameters**

|Param|Type|Required|Description|
|-|-|-|-|
|`page`|number|No|Page number (default: 1)|
|`limit`|number|No|Records per page (default: 50, max: 200)|
|`user\_id`|string|No|Filter by actor UUID|
|`action`|string|No|Filter by `AuditAction` enum value|
|`module`|string|No|Filter by `AuditModule` enum value|
|`tenant\_id`|string|No|SUPER\_ADMIN / TECH\_ADMIN only|
|`from\_date`|string|No|ISO8601 start date|
|`to\_date`|string|No|ISO8601 end date|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "logs": \[
      {
        "id": "uuid",
        "user\_id": "uuid",
        "tenant\_id": "uuid",
        "action": "USER\_LOGIN",
        "module": "AUTH",
        "target\_id": null,
        "ip\_address": "192.168.1.1",
        "device": "Flutter/iOS",
        "metadata": { },
        "created\_at": "2026-04-01T10:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 50,
      "total": 1240,
      "total\_pages": 25
    }
  }
}
```

**Backend Workflow**

1. Validate Bearer — must be admin role
2. `OPS\_ADMIN`: force `tenant\_id = jwt.tenant\_id` (RLS — cannot query other tenants)
3. `SUPER\_ADMIN` / `TECH\_ADMIN`: allow any `tenant\_id`
4. Build query with filters, ordered by `created\_at DESC`, apply pagination

> Use URL query params: `/admin/audit-logs?action=USER\_LOGIN\&from\_date=2026-01-01\&page=2`

\---

### EP-23 · GET `/admin/audit-logs/export`

**Feature:** AUTH-09 — Audit Log CSV Export (Async)  
**Auth:** Bearer (all admin roles) | **Priority:** P1

Export filtered audit logs as CSV. **Async** — returns `job\_id` immediately. Poll the same endpoint with `job\_id` for status.

**Query Parameters** — Same filters as EP-22. Add `job\_id` when polling.

**Initial Request Response — 202 Accepted**

```json
{
  "success": true,
  "data": {
    "job\_id": "uuid",
    "status": "PENDING",
    "message": "Export queued. Poll /admin/audit-logs/export?job\_id={uuid} for status."
  }
}
```

**Poll Response — 200 OK** (when completed)

```json
{
  "success": true,
  "data": {
    "job\_id": "uuid",
    "status": "COMPLETED",
    "download\_url": "https://storage.googleapis.com/exports/{tenant\_id}/{job\_id}.csv",
    "expires\_in": 3600
  }
}
```

**Backend Workflow**

1. Queue async Bull job
2. Return `job\_id` immediately (202)
3. Background worker: query `audit\_logs` → generate CSV → upload to GCS `exports/{tenant\_id}/{job\_id}.csv` → generate 1-hour signed URL → update job status

\---

### EP-24 · POST `/admin/employees/bulk-upload`

**Feature:** AUTH-06b — Bulk Employee Upload  
**Auth:** Bearer (`OPS\_ADMIN` or `SUPER\_ADMIN`) | **Priority:** P0

Upload a CSV to bulk-add/update employees in a tenant's roster. Processed async via Bull Queue.

**Request** — `multipart/form-data`

|Field|Type|Required|Description|
|-|-|-|-|
|`file`|CSV|Yes|Max 10MB. Columns: `employee\_id`, `email`, `full\_name`, `department` (optional)|
|`tenant\_id`|string|SUPER\_ADMIN only|`OPS\_ADMIN` uses `jwt.tenant\_id` automatically|

**CSV Format**

```
employee\_id,email,full\_name,department
EMP001,john@infosys.com,John Doe,Engineering
EMP002,jane@infosys.com,Jane Smith,Finance
```

**Success Response — 202 Accepted**

```json
{
  "success": true,
  "data": {
    "upload\_id": "uuid",
    "status": "PENDING",
    "total\_rows": 245,
    "message": "Upload queued. Poll /admin/employees/bulk-upload/{upload\_id} for status."
  }
}
```

**Backend Workflow**

1. Validate token — `OPS\_ADMIN` or `SUPER\_ADMIN`
2. Validate file — `.csv` extension, max 10MB
3. Upload CSV to GCS: `bulk\_uploads/{tenant\_id}/{uuid}.csv`
4. Create `bulk\_upload\_logs` record: `status = PENDING`, `gcs\_path`
5. Enqueue Bull job with `upload\_id`
6. Return 202 with `upload\_id` immediately

**Bull Worker:** Parse rows → UPSERT into `employee\_roster` (unique: `tenant\_id + employee\_id`) → track `success\_count`, `failed\_count`, `error\_details` → UPDATE status to `COMPLETED` or `FAILED` → Log `AuditAction.BULK\_EMPLOYEE\_UPLOAD`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|400|`VALIDATION\_ERROR`|Not a CSV or file too large (>10MB)|
|403|`PERMISSION\_DENIED`|Non SUPER\_ADMIN / OPS\_ADMIN|

\---

### EP-25 · GET `/admin/employees/bulk-upload/:id`

**Feature:** AUTH-06b — Upload Status Poll  
**Auth:** Bearer (`OPS\_ADMIN` or `SUPER\_ADMIN`) | **Priority:** P0

Poll the status of a bulk upload job.

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "upload\_id": "uuid",
    "status": "PROCESSING | COMPLETED | FAILED",
    "total\_records": 500,
    "success\_count": 497,
    "failed\_count": 3,
    "error\_details": \[
      { "row": 47, "employee\_id": "EMP047", "reason": "Duplicate employee\_id" }
    ]
  }
}
```

\---

### EP-26 · POST `/admin/employees/:id/offboard`

**Feature:** AUTH-06a — Employee Offboarding  
**Auth:** Bearer (`OPS\_ADMIN` or `SUPER\_ADMIN`) | **Priority:** P0

Offboard an employee immediately — deactivates user account, marks roster inactive, revokes all sessions.

**Request Body**

|Field|Type|Required|Description|
|-|-|-|-|
|`reason`|string|Yes|Reason for offboarding|

**Success Response — 200 OK**

```json
{
  "success": true,
  "message": "Employee offboarded successfully."
}
```

**Backend Workflow**

1. Validate token
2. Fetch target user WHERE `role = USER`
3. `OPS\_ADMIN`: validate `user.tenant\_id = jwt.tenant\_id` → 403 `TENANT\_MISMATCH`
4. `SUPER\_ADMIN`: can offboard from any tenant
5. UPDATE `users`: `is\_active = false`, `deactivated\_at = now()`
6. UPDATE `employee\_roster`: `is\_active = false` WHERE `tenant\_id = user.tenant\_id` AND `employee\_id = user.employee\_id`
7. Revoke ALL active sessions (bulk UPDATE + Redis blacklist)
8. Log `AuditAction.OFFBOARDING\_DEACTIVATION` with `metadata: { performed\_by, reason }` + `AuditAction.EMPLOYEE\_OFFBOARDED`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|404|`USER\_NOT\_FOUND`|Target user not found|
|403|`TENANT\_MISMATCH`|OPS\_ADMIN trying to offboard from different tenant|
|403|`PERMISSION\_DENIED`|Non SUPER\_ADMIN / OPS\_ADMIN|

\---

### EP-27 · POST `/admin/vendors`

**Feature:** AUTH-02 — Vendor Onboarding  
**Auth:** Bearer (`OPS\_ADMIN` or `SUPER\_ADMIN`) | **Priority:** P0

Create a new vendor account. Sends activation email. Vendor activates via EP-17.

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`email`|string|Yes|Vendor's business email (activation link sent here)|`users.email`|
|`phone`|string|Yes|Vendor's phone number|`users.phone`|
|`full\_name`|string|Yes|Contact person name|`users.full\_name`|
|`business\_name`|string|Yes|Outlet / kitchen name|`vendor\_profiles.business\_name`|
|`tenant\_id`|string|Yes|Which tenant this vendor serves|`users.tenant\_id`|
|`business\_address`|string|Yes|Full address|`vendor\_profiles.business\_address`|
|`city`|string|Yes|City|`vendor\_profiles.city`|
|`state`|string|Yes|State|`vendor\_profiles.state`|
|`pincode`|string|Yes|Pincode|`vendor\_profiles.pincode`|
|`gstin`|string|No|GST Identification Number|`vendor\_profiles.gstin`|

**Success Response — 201 Created**

```json
{
  "success": true,
  "data": {
    "vendor\_id": "uuid",
    "message": "Vendor account created. Activation email sent."
  }
}
```

**Backend Workflow**

1. Validate token — `OPS\_ADMIN` or `SUPER\_ADMIN`
2. Check `phone` not already registered → 409 `USER\_ALREADY\_EXISTS`
3. Check `email` not already registered → 409 `USER\_ALREADY\_EXISTS`
4. Create `users` record: `role = VENDOR`, `is\_active = false`, `is\_verified = false`, `tenant\_id = request.tenant\_id`
5. Create `vendor\_profiles` record
6. Generate activation UUID, store in Redis: `activation:{uuid}` → `user\_id` TTL 24h
7. Send activation email: `{APP\_URL}/vendor/activate?token={uuid}`
8. Log `AuditAction.VENDOR\_REGISTER`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|409|`USER\_ALREADY\_EXISTS`|Phone or email already registered|
|403|`PERMISSION\_DENIED`|Non SUPER\_ADMIN / OPS\_ADMIN|
|400|`VALIDATION\_ERROR`|Missing required fields|

> Vendor is NOT active until they complete EP-17 (account activation).

\---

### EP-28 · POST `/admin/vendors/:id/suspend`

**Feature:** AUTH-12 — Vendor Suspend  
**Auth:** Bearer (`OPS\_ADMIN` or `SUPER\_ADMIN`) | **Priority:** P0

Suspend a vendor account immediately. Revokes all sessions. Vendor cannot log in while suspended.

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`reason`|string|Yes|Mandatory reason|`users.suspend\_reason`, `vendor\_suspension\_logs.reason`|

**Success Response — 200 OK**

```json
{
  "success": true,
  "message": "Vendor account suspended."
}
```

**Backend Workflow**

1. Validate token
2. Fetch user WHERE `role = VENDOR` → 404 `USER\_NOT\_FOUND`
3. If already suspended → 400 `VALIDATION\_ERROR` ("Vendor is already suspended")
4. UPDATE `users`: `is\_suspended = true`, `suspend\_reason = reason` — **Trigger 4 auto-sets `suspended_at`**
5. Revoke ALL active sessions + blacklist refresh tokens in Redis
6. Create `vendor\_suspension\_logs` record: `action = SUSPENDED`, `reason`, `actioned\_by = jwt.sub`
7. Log `AuditAction.VENDOR\_SUSPENDED`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|404|`USER\_NOT\_FOUND`|No vendor with this ID|
|400|`VALIDATION\_ERROR`|`reason` missing or vendor already suspended|
|403|`PERMISSION\_DENIED`|Non SUPER\_ADMIN / OPS\_ADMIN|

\---

### EP-29 · POST `/admin/vendors/:id/reactivate`

**Feature:** AUTH-12 — Vendor Reactivate  
**Auth:** Bearer (`OPS\_ADMIN` or `SUPER\_ADMIN`) | **Priority:** P0

Reactivate a previously suspended vendor.

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`reason`|string|Yes|Mandatory reason for reactivation|`vendor\_suspension\_logs.reason`|

**Success Response — 200 OK**

```json
{
  "success": true,
  "message": "Vendor account reactivated."
}
```

**Backend Workflow**

1. Validate token
2. Fetch vendor — verify `is\_suspended = true` → 400 `VALIDATION\_ERROR` if not suspended
3. UPDATE `users`: `is\_suspended = false`, `suspend\_reason = NULL` — **Trigger 4 auto-sets `reactivated_at`**
4. Create `vendor\_suspension\_logs` record: `action = REACTIVATED`, `reason`, `actioned\_by = jwt.sub`
5. Log `AuditAction.VENDOR\_REACTIVATED`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|404|`USER\_NOT\_FOUND`|Vendor not found|
|400|`VALIDATION\_ERROR`|Vendor is not currently suspended|

\---

### EP-30 · POST `/admin/delegations`

**Feature:** AUTH-11 — Create Delegation  
**Auth:** Bearer (`SUPER\_ADMIN` only) | **Priority:** P1

Grant another admin temporary access to a specific module. `expires\_at` is mandatory — no open-ended delegations.

**Request Body**

|Field|Type|Required|Description|DB Field|
|-|-|-|-|-|
|`delegatee\_id`|string|Yes|Admin UUID receiving access|`delegations.delegatee\_id`|
|`module`|string|Yes|`AppModule` enum: `AUTH \| VENDOR \| ORDER \| MENU \| REPORT \| SETTINGS \| EMPLOYEE \| DELEGATION \| TENANT \| SESSION \| FINANCE`|`delegations.module`|
|`expires\_at`|string|Yes|ISO8601 — must be in the future|`delegations.expires\_at`|
|`starts\_at`|string|No|ISO8601 — default: now|`delegations.starts\_at`|
|`reason`|string|No|Why delegating|`delegations.reason`|

**Success Response — 201 Created**

```json
{
  "success": true,
  "data": {
    "delegation\_id": "uuid",
    "expires\_at": "ISO8601"
  }
}
```

**Backend Workflow**

1. Validate token — `SUPER\_ADMIN` only → 403 `PERMISSION\_DENIED`
2. Validate `delegatee\_id` is an active admin user
3. Validate `expires\_at` is in the future
4. Create `delegations` record: `is\_active = true`
5. Cache in Redis: `delegate:{delegateeId}:{module}` → `"1"` TTL = seconds until `expires\_at`
6. Log `AuditAction.DELEGATE\_GRANTED` with `metadata: { module, delegatee\_id }`

> NestJS cron (every 5 min): finds `delegations` WHERE `expires\_at < NOW()` AND `is\_active = true` → SET `is\_active = false` → deletes Redis key → logs `AuditAction.DELEGATE\_REVOKED`.

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|403|`PERMISSION\_DENIED`|Non-SUPER\_ADMIN caller|
|404|`USER\_NOT\_FOUND`|`delegatee\_id` not found|
|400|`VALIDATION\_ERROR`|`expires\_at` is in the past or missing|

\---

### EP-31 · GET `/admin/delegations`

**Feature:** AUTH-11 — List Delegations  
**Auth:** Bearer (`SUPER\_ADMIN`) | **Priority:** P1

List all delegations with optional filters.

**Query Parameters**

|Param|Type|Description|
|-|-|-|
|`is\_active`|boolean|Filter by active status|
|`delegatee\_id`|string|Filter by recipient|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "delegations": \[
      {
        "id": "uuid",
        "delegator": { "id": "uuid", "email": "super@bhojan.com" },
        "delegatee": { "id": "uuid", "email": "ops@bhojan.com" },
        "module": "FINANCE",
        "is\_active": true,
        "starts\_at": "2026-04-01T00:00:00Z",
        "expires\_at": "2026-04-30T18:00:00Z",
        "reason": "Finance review coverage"
      }
    ]
  }
}
```

\---

### EP-32 · DELETE `/admin/delegations/:id`

**Feature:** AUTH-11 — Revoke Delegation  
**Auth:** Bearer (`SUPER\_ADMIN`) | **Priority:** P1

Manually revoke an active delegation before expiry.

**Success Response — 200 OK**

```json
{ "success": true, "message": "Delegation revoked." }
```

**Backend Workflow**

1. Validate token — `SUPER\_ADMIN` only
2. Fetch delegation by `:id`
3. UPDATE `delegations`: `is\_active = false`
4. Delete Redis key: `delegate:{delegateeId}:{module}`
5. Log `AuditAction.DELEGATE\_REVOKED`

\---

### EP-33 · GET `/admin/sessions`

**Feature:** AUTH-04 — View Active Sessions  
**Auth:** Bearer (`SUPER\_ADMIN` or `TECH\_ADMIN`) | **Priority:** P1

List sessions for security monitoring.

**Query Parameters**

|Param|Type|Description|
|-|-|-|
|`user\_id`|string|Filter sessions for a specific user|
|`is\_active`|boolean|Filter by active/revoked (default: true — active only)|

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "sessions": \[
      {
        "id": "uuid",
        "user\_id": "uuid",
        "user\_email": "user@infosys.com",
        "device": "Flutter/Android",
        "ip\_address": "192.168.1.1",
        "is\_revoked": false,
        "created\_at": "2026-04-01T08:00:00Z",
        "expires\_at": "2026-04-08T08:00:00Z"
      }
    ]
  }
}
```

\---

### EP-34 · DELETE `/admin/sessions/:id`

**Feature:** AUTH-04 — Revoke Session  
**Auth:** Bearer (`SUPER\_ADMIN` or `TECH\_ADMIN`) | **Priority:** P1

Force-revoke a specific user session. User is immediately logged out on that device.

**Success Response — 200 OK**

```json
{ "success": true, "message": "Session revoked." }
```

**Backend Workflow**

1. Validate token — `SUPER\_ADMIN` or `TECH\_ADMIN`
2. Fetch session by `:id` → 404 if not found
3. UPDATE `sessions`: `is\_revoked = true`
4. Add associated refresh token to Redis blacklist
5. Log `AuditAction.SESSION\_REVOKED`

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|404|`USER\_NOT\_FOUND`|Session ID not found|
|403|`PERMISSION\_DENIED`|Non SUPER\_ADMIN / TECH\_ADMIN|

\---

## 6\. Public Tenant Discovery Endpoints

\---

### EP-35 · GET `/tenants`

**Feature:** TENANT-01 — Tenant Discovery \& Selection  
**Auth:** None (public) | **Priority:** P0

Returns active tenants for the onboarding selector. `city` and `location` fields do not exist in the `tenants` table — frontend groups/labels tenants using `name` only.

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Capgemini",
      "logo_url": "https://...",
      "has_active_cafeteria": true
    },
    {
      "id": "uuid",
      "name": "Infosys",
      "logo_url": "https://...",
      "has_active_cafeteria": true
    }
  ]
}
```

**Backend Workflow**

1. `SELECT id, name, logo_url, is_active FROM tenants WHERE is_active = true`
2. Join with `tenant_settings` (if needed) to compute cafeteria/meal-window availability
3. Return flat tenant list (`id`, `name`, `logo_url`, `has_active_cafeteria` only — no city/location in schema)

\---

### EP-36 · GET `/tenants/:id/settings`

**Feature:** TENANT-02 — Tenant Configuration Fetch  
**Auth:** None (public) | **Priority:** P0

Returns the selected tenant's subsidy rules, meal windows, and wallet configuration.

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "tenant_id": "uuid",
    "subsidy_per_meal": 80.00,
    "meal_window_start": "07:00",
    "meal_window_end": "22:00",
    "wallet_enabled": true,
    "max_wallet_balance": 500.00
  }
}
```

**Backend Workflow**

1. Validate `:id` is a well-formed tenant UUID
2. Fetch tenant by `id` with `is_active = true` from `tenants`
3. Fetch config from `tenant_settings` by `tenant_id`
4. Return normalized config payload for onboarding and pricing logic

**Error Responses**

|HTTP|Error Code|Trigger|
|-|-|-|
|404|`TENANT\_NOT\_FOUND`|Tenant ID not found / inactive tenant|

\---

### EP-37 · POST `/tenants/validate`

**Feature:** TENANT-03 — Pre-Registration Validation  
**Auth:** None (public) | **Priority:** P0

Validates whether a tenant is currently accepting registrations.

**Request Body**

```json
{ "tenant_id": "uuid" }
```

**Success Response — 200 OK**

```json
{
  "success": true,
  "data": {
    "is_open": true,
    "message": "Tenant accepting registrations"
  }
}
```

**Error Response — 403 Forbidden**

```json
{
  "success": false,
  "error": {
    "code": "TENANT_CLOSED",
    "message": "Registrations paused for this location"
  }
}
```

**Backend Workflow**

1. Validate request body (`tenant_id` required, UUID format)
2. Fetch tenant + settings by `tenant_id`
3. Evaluate open/closed status based on active flags and registration controls
4. Return 200 with `is_open=true` when open; else 403 with `TENANT\_CLOSED`

\---

## Appendix A — DB Tables Referenced

|Table|Prisma Model|Used By|
|-|-|-|
|`users`|`User`|All endpoints|
|`user\_profiles`|`UserProfile`|EP-01, EP-02, EP-06, EP-07, EP-08, EP-13|
|`vendor\_profiles`|`VendorProfile`|EP-17, EP-18, EP-19, EP-27|
|`sessions`|`Session`|EP-02, EP-03, EP-04, EP-05, EP-16, EP-18, EP-20, EP-33, EP-34|
|`tenants`|`Tenant`|EP-16, EP-20, EP-22, EP-35, EP-36, EP-37|
|`tenant\_settings`|`TenantSettings`|EP-35, EP-36, EP-37, Cart module (later phases)|
|`employee\_roster`|`EmployeeRoster`|EP-01, EP-14, EP-24, EP-25, EP-26|
|`role\_permissions`|`RolePermission`|EP-21|
|`delegations`|`Delegation`|EP-21, EP-30, EP-31, EP-32|
|`audit\_logs`|`AuditLog`|All write endpoints|
|`bulk\_upload\_logs`|`BulkUploadLog`|EP-24, EP-25|
|`vendor\_suspension\_logs`|`VendorSuspensionLog`|EP-28, EP-29|
|`account\_deletion\_requests`|`AccountDeletionRequest`|EP-13|
|`contact\_change\_requests`|`ContactChangeRequest`|EP-11, EP-12|
|`guest\_upgrade\_requests`|`GuestUpgradeRequest`|EP-14|

\---

## Appendix B — What Changed from Old Contracts (v2.1 → v4.2)

|#|Change|Details|
|-|-|-|
|1|**Guest + Employee split in EP-01**|`user\_type` field added. Completely separate request body and backend logic for GUEST vs EMPLOYEE. GUEST has no `email` or `employee\_id` fields.|
|2|**EP-02 dual-purpose documented**|Explicitly covers both Registration path (creates user record) and OTP Login path (issues tokens for existing user). Differentiated by `reg\_pending:{phone}` in Redis.|
|3|**New EP-03 — Password Login**|`POST /auth/login/password` is now a dedicated endpoint separate from OTP flow.|
|4|**New EP-14 — Guest → Employee Upgrade**|`POST /auth/upgrade-to-employee` added for AUTH-01c.|
|5|**New EP-25 — Bulk Upload Poll**|`GET /admin/employees/bulk-upload/:id` added as explicit status poll endpoint.|
|6|**EP numbers updated**|EP-03 (old = token refresh) is now EP-04. All subsequent EPs shifted +1. This is the canonical numbering — no work started yet.|
|7|**JWT payload updated**|`tenant\_id` explicitly nullable for guests. `is\_employee` added. `GUEST` role added to enum.|
|8|**EP-09 security fix**|Password reset always returns 200 — never exposes `USER\_NOT\_FOUND` to prevent account enumeration.|
|9|**EP-13 deletion fix**|`users.phone` anonymised to `deleted\_{uuid}` — NOT set to NULL (phone is non-nullable per schema v4.2).|
|10|**EP-23 export made async**|Audit log export is now async: 202 + `job\_id` + poll. Was incorrectly a direct streaming response.|
|11|**EP-27 fields restored**|`state`, `pincode` restored as required. `gstin` restored as optional. `phone` added as required.|
|12|**EP-18 vendor login uses phone**|Schema v4.2 confirms phone is the primary login identifier for ALL roles. Not email.|
|13|**No `otp\_verifications` table**|All OTPs are Redis-only. Old contracts referenced this table which no longer exists.|
|14|**Audit actions corrected**|EP-17 (vendor activate) logs `VENDOR\_ACTIVATED` + `EMAIL\_VERIFIED`. `VENDOR\_REGISTER` is only logged by EP-27 (admin creates vendor).|
|15|**Error codes updated**|Added: `ALREADY\_EMPLOYEE`, `ACCOUNT\_LOCKED`, `AUTH\_LOGIN\_FAILED`.|
|16|**Query param names consistent**|Audit log uses `from\_date` / `to\_date` throughout.|
|17|**EP-30/31/32 path corrected**|Backend implemented as `/admin/delegations` (not `/admin/delegates`). Index table and section headings updated to match.|
|18|**EP-35 response shape corrected**|`data` is a flat array of tenant objects — not wrapped in `{ tenants: [...] }`. Updated success response example to match actual implementation.|

\---


