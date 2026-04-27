<<<<<<< HEAD
# Bhojan - First Time Setup Guide

This guide is for teammates who cloned or downloaded the project for the first time.

---

## 1) Prerequisites

Install these first:

- Node.js 20+ (recommended LTS)
- npm 10+
- PostgreSQL/Supabase database access
- Redis (local or remote)
- Flutter SDK 3.x (for frontend)
- Chrome (for Flutter web testing)

Check versions:

```bash
node -v
npm -v
flutter --version
=======
# 🍱 Bhojan Frontend

A Flutter Web application for the **Bhojan** cafeteria management platform.
This repo contains three sub-apps in one codebase: **User App**, **Vendor App**, and **Admin App**.

---

## 📦 Project Structure

```
lib/
├── app/                    # Router, theme, app entry
├── core/                   # API client, config, utils, theme
│   ├── api/                # Dio client, endpoints, interceptors
│   ├── config/             # AppConfig (toggle Mock ↔ Real API)
│   └── utils/              # StorageService (flutter_secure_storage)
├── features/               # User App screens & logic
│   ├── auth/               # Login, Register, OTP, Tenant selection
│   ├── home/               # Home/Dashboard
│   └── profile/            # Profile, Edit, Contact change, Delete, Upgrade
├── vendor_app/             # Vendor App screens & logic
│   ├── auth/               # Activate, Login, Register, Verify Phone
│   ├── dashboard/          # Vendor Dashboard
│   └── profile/            # Vendor Profile
└── admin_app/              # Admin App screens & logic
    ├── auth/               # Admin Login (Email → OTP), Role Selection
    ├── dashboard/          # Role-based Dashboard (Super/Ops/Tech Admin)
    ├── vendors/            # Vendor List, Create Vendor, Vendor Detail
    ├── employees/          # Bulk Upload, Employee Offboard
    ├── audit/              # Audit Logs with CSV export
    ├── delegation/         # Delegation Management
    ├── sessions/           # Active Sessions
    ├── permissions/        # Permission Matrix
    └── profile/            # Admin Profile & Settings
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
```

---

<<<<<<< HEAD
## 2) Get the Code

Use one of these:

```bash
# Option A: clone
git clone https://github.com/valueworkers/Bhojan-app.git
cd Bhojan-app

# Option B: existing clone
git fetch origin
git checkout karthikkashyap-manager-patch-1
git pull
```

If you downloaded ZIP, extract and open the `Bhojan-app` folder as workspace root.

---

## 3) Backend First-Time Setup

### 3.1 Install dependencies

```bash
cd backend
npm install
```

Important:

- Do **not** run `npx prisma ...` before `npm install`.
- Running `npx prisma` without local deps can auto-download Prisma 7 and break this Prisma 5 schema.

### 3.2 Create `.env` (required)

`.env` is not committed to git.

```bash
# Windows PowerShell
Copy-Item .env.example .env

# macOS/Linux
cp .env.example .env
```

Now open `backend/.env` and fill at least:

- `DATABASE_URL`
- `REDIS_URL` (or `REDIS_HOST`/`REDIS_PORT` if used by your setup)
- `JWT_SECRET`
- `JWT_REFRESH_SECRET`

Optional but used in OTP/email flows:

- `FAST2SMS_API_KEY`
- `SENDGRID_API_KEY`
- `SENDGRID_FROM_EMAIL`
- `FRONTEND_URL`

### 3.3 Prisma setup

```bash
npm run prisma:generate
npm run prisma:push
```

If you need sample data:

```bash
npm run seed
```

### 3.4 Start backend

```bash
npm run start:dev
```

Expected:

- `Nest application successfully started`
- `Bhojan backend running on http://localhost:3000`

---

## 4) Frontend First-Time Setup

### 4.1 Install dependencies

```bash
cd ../frontend
flutter pub get
```

### 4.2 Verify API mode

Open:

- `frontend/lib/core/config/app_config.dart`

Set:

- `useMockServices = false`
- `apiBaseUrl = 'http://localhost:3000'` (or your backend URL)

### 4.3 Run frontend

```bash
flutter run -d chrome
```

---

## 5) Smoke Test Checklist

After both services start:

1. Open app in browser.
2. Test OTP login.
3. Test guest signup.
4. Test employee signup using valid `employee_id` from DB roster.
5. Confirm home header shows user tenant (not hardcoded).

---

## 6) Common Errors and Fixes

### Error: `PrismaClientConstructorValidationError ... datasource "db" undefined`

Cause:

- `DATABASE_URL` missing in `backend/.env`.

Fix:

1. Copy `.env.example` to `.env`.
2. Fill `DATABASE_URL`.
3. Restart backend.

### Error: `P1012 ... datasource property url/directUrl is no longer supported`

Cause:

- Prisma 7 CLI was used on a Prisma 5 project (usually from running `npx prisma` before `npm install`).

Fix:

1. Install dependencies first: `npm install`.
2. Use project scripts instead of global `npx`:
   - `npm run prisma:generate`
   - `npm run prisma:push`

### Error: `EMPLOYEE_ID_NOT_FOUND`

Cause:

- Employee ID not present in active `employeeRoster`.

Fix:

- Use valid roster data (seeded/admin-uploaded), or seed DB first.

### OTP verify gives `VALIDATION_ERROR`

Fix:

- Ensure OTP is 6 digits.
- Ensure phone format is valid Indian number.
- Restart backend if recent DTO changes were pulled.

### Profile update gives `VALIDATION_ERROR`

Fix:

- Frontend must send custom settings under `preferences` object.

---

## 7) Useful Commands

Backend:

```bash
cd backend
npm run build
npm run test
npx prisma studio
```

Frontend:

```bash
cd frontend
flutter analyze
flutter test
=======
## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.x` — [Install Flutter](https://docs.flutter.dev/get-started/install)
- Dart SDK `>=3.x` (comes bundled with Flutter)
- Backend server running on `http://localhost:3000`

### Setup

```bash
# Install dependencies
flutter pub get

# Run on Chrome (recommended for development)
flutter run -d chrome
```

### Switching Between Mock & Real API

Open `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  // Set to false to connect to the real backend
  static const bool useMockServices = false;

  // Change this to your backend URL if not localhost
  static const String apiBaseUrl = 'http://localhost:3000';
}
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
```

---

<<<<<<< HEAD
## 8) Team Onboarding Rules

- Never commit `.env`.
- Always run `npm install` / `flutter pub get` after pulling.
- Run backend and frontend from separate terminals.
- If startup fails, verify env vars first before code changes.

=======
## 🌐 Backend API

The Flutter app talks to a **NestJS + PostgreSQL (Supabase)** backend.

> **API Contract Document:** `BHOJAN_AUTH_API_CONTRACTS v 2.md`

### Base URL
```
http://localhost:3000
```

### Authentication
- All protected endpoints require: `Authorization: Bearer <access_token>`
- Access token TTL: **15 minutes**
- Refresh token TTL: **7 days**
- On `401 TOKEN_EXPIRED` → silently call `POST /auth/token/refresh` → retry

---

## 📋 API Endpoints Summary

### User App (EP-01 to EP-16)

| EP | Method | Path | Description |
|----|--------|------|-------------|
| EP-01 | `POST` | `/auth/register` | Register (Guest or Employee) |
| EP-02 | `POST` | `/auth/otp/verify` | Verify OTP (Registration + OTP Login) |
| EP-03 | `POST` | `/auth/login/password` | Login with password |
| EP-04 | `POST` | `/auth/token/refresh` | Refresh access token |
| EP-05 | `POST` | `/auth/logout` | Logout |
| EP-06 | `GET`  | `/auth/me` | Get own profile |
| EP-07 | `PUT`  | `/auth/profile` | Update profile |
| EP-08 | `POST` | `/auth/profile/avatar` | Upload avatar (multipart) |
| EP-09 | `POST` | `/auth/password/reset-request` | Request password reset OTP |
| EP-10 | `POST` | `/auth/password/reset-verify` | Verify OTP + set new password |
| EP-11 | `POST` | `/auth/contact/change` | Initiate email/phone change |
| EP-12 | `POST` | `/auth/contact/verify` | Confirm contact change with dual OTPs |
| EP-13 | `DELETE` | `/auth/account` | Delete account (soft delete + PII anonymisation) |
| EP-14 | `POST` | `/auth/upgrade-to-employee` | Upgrade GUEST to employee |
| EP-15 | `GET`  | `/auth/sso/google` | Google SSO redirect |
| EP-16 | `GET`  | `/auth/sso/google/callback` | Google SSO callback |

### Vendor App (EP-17 to EP-19)

| EP | Method | Path | Description |
|----|--------|------|-------------|
| EP-17 | `POST` | `/vendor/auth/activate` | Activate vendor account via token |
| EP-18 | `POST` | `/vendor/auth/login` | Vendor login (phone + password) |
| EP-19 | `PUT`  | `/vendor/auth/profile` | Update vendor profile |

### Admin App (EP-20 to EP-34)

| EP | Method | Path | Description |
|----|--------|------|-------------|
| EP-20 | `POST` | `/admin/auth/login` | Admin login — Step 1: email → OTP, Step 2: email + OTP → tokens |
| EP-21 | `GET`  | `/admin/auth/permissions` | Get admin RBAC permissions |
| EP-22 | `GET`  | `/admin/audit-logs` | Query audit logs (filterable, paginated) |
| EP-23 | `GET`  | `/admin/audit-logs/export` | Async CSV export (returns `job_id`, poll same endpoint) |
| EP-24 | `POST` | `/admin/employees/bulk-upload` | Upload employee CSV (async, returns `upload_id`) |
| EP-25 | `GET`  | `/admin/employees/bulk-upload/:id` | Poll bulk upload status |
| EP-26 | `POST` | `/admin/employees/:id/offboard` | Offboard employee (revokes all sessions) |
| EP-27 | `POST` | `/admin/vendors` | Create vendor |
| EP-28 | `POST` | `/admin/vendors/:id/suspend` | Suspend vendor |
| EP-29 | `POST` | `/admin/vendors/:id/reactivate` | Reactivate vendor |
| EP-30 | `POST` | `/admin/delegations` | Create delegation |
| EP-31 | `GET`  | `/admin/delegations` | List delegations |
| EP-32 | `DELETE` | `/admin/delegations/:id` | Revoke delegation |
| EP-33 | `GET`  | `/admin/sessions` | List all active sessions |
| EP-34 | `DELETE` | `/admin/sessions/:id` | Force-revoke a session |

### Tenants — Public (EP-35 to EP-37)

| EP | Method | Path | Description |
|----|--------|------|-------------|
| EP-35 | `GET`  | `/tenants` | List all tenants |
| EP-36 | `GET`  | `/tenants/:id/settings` | Get tenant settings |
| EP-37 | `POST` | `/tenants/validate` | Validate if tenant is accepting registrations |

---

## 📱 App Routes

### User App
| Route | Screen |
|-------|--------|
| `/welcome` | Welcome / Landing |
| `/tenant-select` | Select Company |
| `/sign-up-type` | Guest or Employee choice |
| `/register/guest` | Guest Registration |
| `/register/employee` | Employee Registration |
| `/verify-otp` | OTP Verification |
| `/login-otp` | Login with OTP |
| `/login-password` | Login with Password |
| `/forgot-password` | Forgot Password |
| `/home` | Home Dashboard |
| `/profile` | Profile View |
| `/profile/edit` | Edit Profile |
| `/change-contact` | Change Email/Phone |
| `/upgrade-to-employee` | Guest → Employee Upgrade |
| `/delete-account` | Delete Account |

### Vendor App
| Route | Screen |
|-------|--------|
| `/vendor/welcome` | Vendor Welcome |
| `/vendor/register` | Vendor Registration |
| `/vendor/activate` | Account Activation |
| `/vendor/login` | Vendor Login |
| `/vendor/dashboard` | Vendor Dashboard |
| `/vendor/profile` | Vendor Profile |

### Admin App
| Route | Screen |
|-------|--------|
| `/admin/login` | Admin Login (Email step) |
| `/admin/verify-otp` | Admin OTP Verification |
| `/admin/dashboard` | Dashboard (role-based) |
| `/admin/vendors` | Vendor List |
| `/admin/vendors/create` | Create Vendor |
| `/admin/vendors/detail` | Vendor Detail (Suspend/Reactivate) |
| `/admin/employees/upload` | Bulk Employee Upload |
| `/admin/employees/offboard` | Employee Offboard |
| `/admin/logs` | Audit Logs |
| `/admin/delegation` | Delegation Management |
| `/admin/sessions` | Active Sessions |
| `/admin/permissions` | Permission Matrix |
| `/admin/profile` | Admin Profile & Settings |

---

## 🔐 Admin Roles

| Role | Description |
|------|-------------|
| `SUPER_ADMIN` | Full access — all tenants, delegations, sessions |
| `OPS_ADMIN` | Tenant-scoped — vendors, employees, bulk upload |
| `TECH_ADMIN` | Audit logs, sessions, config |

---

## 🗂️ Standard API Response Format

All endpoints return this envelope:

```json
// Success
{ "success": true, "data": { ... }, "message": "..." }

// Error
{ "success": false, "error": { "code": "ERROR_CODE", "message": "Human readable" } }
```

### Common Error Codes

| Error Code | Meaning |
|-----------|---------|
| `USER_ALREADY_EXISTS` | Phone or email already registered |
| `USER_NOT_FOUND` | No account found |
| `OTP_INVALID` | Wrong OTP |
| `OTP_EXPIRED` | OTP TTL passed |
| `OTP_MAX_ATTEMPTS` | 3 wrong attempts |
| `OTP_RATE_LIMIT` | Too many requests (15 min cooldown) |
| `ACCOUNT_LOCKED` | Too many wrong passwords |
| `ACCOUNT_SUSPENDED` | Account suspended |
| `ACCOUNT_DEACTIVATED` | Account deactivated |
| `EMPLOYEE_ID_NOT_FOUND` | Employee ID not in roster |
| `ALREADY_EMPLOYEE` | Account already linked to a company |
| `TENANT_MISMATCH` | Admin tried to access another tenant |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Web) |
| State Management | Riverpod |
| Navigation | GoRouter |
| HTTP Client | Dio |
| Secure Storage | flutter_secure_storage |
| Backend | NestJS + PostgreSQL (Supabase) |
| Cache | Redis |

---

## 📌 Notes for Backend Devs

1. **CORS** — Flutter Web runs on `localhost` during development. Ensure CORS allows `http://localhost:*`
2. **OTP Logging** — The backend logs OTPs to console: `[OTP] phone=+91... otp=XXXXXX`. Check terminal during testing.
3. **`.env` file** — Is git-ignored. Backend devs need to create their own from `.env.example`.
4. **Supabase trigger** — `auto_create_user_profile` must be active for user profile creation on registration.
5. **Employee Roster** — The `employee_roster` table must be seeded before testing employee registration (EP-01 EMPLOYEE path).
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
