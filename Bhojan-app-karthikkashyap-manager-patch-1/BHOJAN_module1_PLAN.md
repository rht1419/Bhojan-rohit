# Bhojan — Phase 5 Frontend Plan
## Rohit's Complete Guide · Module 1 Authentication & User Management

**Version:** v1.0 | **Updated:** April 2026  
**Owner:** Rohit (Frontend Lead) · Sakshi (Admin App support)  
**Apps:** User App · Vendor App · Admin App  
**API Contracts:** `BHOJAN_AUTH_API_CONTRACTS v 2.md` — this is your source of truth for all request/response shapes  
**Schema Ref:** v4.2 PRODUCTION LOCKED  

---

## How This Phase Works

You are starting **now**, in parallel with the backend team (Shreyas, Nandan, Bhrigu).

The approach is simple:

1. **Build everything against the API contracts** — all screens, models, service methods, error handling
2. **Use a mock service layer** — each API service has a `MockXxxService` that returns hardcoded contract-matching responses. You develop and test screens against these.
3. **Swap mock → real as endpoints go live** — when Shreyas deploys an endpoint to staging, you replace the mock implementation with the real `dio.get/post` call. The screen doesn't change — only the service implementation swaps.
4. **Never wait for backend** — if an endpoint isn't live yet, mock it. Keep building.

---

## Quick Start

```bash
# Clone the repo (if not already done)
git clone https://github.com/bhojan/bhojan-user-app.git   # or vendor-app / admin-app
cd bhojan-user-app
flutter pub get

# Run User App
flutter run --flavor user_app -t lib/app/flavors/user_app/main_user.dart

# Run Vendor App
flutter run --flavor vendor_app -t lib/app/flavors/vendor_app/main_vendor.dart

# Run Admin App
flutter run --flavor admin_app -t lib/app/flavors/admin_app/main_admin.dart
```

---

## API Base URLs

| Environment | URL | When to Use |
|-------------|-----|-------------|
| Mock | Local mock service | Now — while backend is being built |
| Staging | `https://staging-api.bhojan.app` | When Shreyas deploys P0 endpoints |
| Production | `https://api.bhojan.app` | Phase 6 only |

Set `API_BASE_URL` in your flavor config. Start with mock, switch to staging URL when ready.

---

## Mock Service Layer — How to Set It Up

Create a toggle in your flavor config or a simple constant:

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const bool useMockServices = true; // flip to false when connecting to real API
}
```

Each service has two implementations — mock and real — sharing the same abstract interface:

```dart
// lib/features/auth/services/auth_service.dart (abstract interface)
abstract class AuthService {
  Future<OtpReferenceResponse> register(RegisterRequest request);
  Future<AuthTokenResponse> verifyOtp(OtpVerifyRequest request);
  Future<AuthTokenResponse> loginWithPassword(PasswordLoginRequest request);
  Future<AuthTokenResponse> refreshToken(String refreshToken);
  Future<void> logout(String refreshToken);
  Future<UserProfileResponse> getProfile();
  // ... rest of EP-01 to EP-16
}

// lib/features/auth/services/mock_auth_service.dart
class MockAuthService implements AuthService {
  @override
  Future<OtpReferenceResponse> register(RegisterRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500)); // simulate network
    return OtpReferenceResponse(otpReference: 'mock-ref-uuid', expiresIn: 300);
  }
  // ... return hardcoded mock data matching API contract shapes
}

// lib/features/auth/services/real_auth_service.dart
class RealAuthService implements AuthService {
  final ApiClient _api;
  RealAuthService(this._api);

  @override
  Future<OtpReferenceResponse> register(RegisterRequest request) async {
    final response = await _api.post('/auth/register', data: request.toJson());
    return OtpReferenceResponse.fromJson(response.data['data']);
  }
  // ... real Dio calls
}
```

Wire them up in your Riverpod providers:

```dart
// lib/features/auth/providers/auth_provider.dart
final authServiceProvider = Provider<AuthService>((ref) {
  if (AppConfig.useMockServices) return MockAuthService();
  return RealAuthService(ref.read(apiClientProvider));
});
```

When Shreyas tells you "EP-01 is live on staging", you:
1. Set `useMockServices = false` (or selectively switch per service)
2. Done. Screen doesn't change.

---

## Standard Response Envelope

Every API response follows this shape. Your models must parse this:

```dart
// Success
{
  "success": true,
  "data": { },
  "message": "optional string"
}

// Error
{
  "success": false,
  "error": {
    "code": "ERROR_CODE_ENUM",
    "message": "Human readable description",
    "details": []  // optional — only for validation errors
  }
}
```

---

## Files to Update First (Already Exist — Need Changes)

Before building new screens, update these existing files:

### 1. `lib/core/api/api_endpoints.dart` — Add ALL 37 endpoint constants

```dart
class ApiEndpoints {
  // User App — Auth
  static const register            = '/auth/register';
  static const otpVerify           = '/auth/otp/verify';
  static const loginPassword       = '/auth/login/password';
  static const tokenRefresh        = '/auth/token/refresh';
  static const logout              = '/auth/logout';
  static const getProfile          = '/auth/me';
  static const updateProfile       = '/auth/profile';
  static const uploadAvatar        = '/auth/profile/avatar';
  static const passwordResetReq    = '/auth/password/reset-request';
  static const passwordResetVerify = '/auth/password/reset-verify';
  static const contactChange       = '/auth/contact/change';
  static const contactVerify       = '/auth/contact/verify';
  static const deleteAccount       = '/auth/account';
  static const upgradeToEmployee   = '/auth/upgrade-to-employee';
  static const ssoGoogle           = '/auth/sso/google';
  static const ssoGoogleCallback   = '/auth/sso/google/callback';

  // Vendor App — Auth
  static const vendorActivate      = '/vendor/auth/activate';
  static const vendorLogin         = '/vendor/auth/login';
  static const vendorProfile       = '/vendor/auth/profile';

  // Admin App — Auth
  static const adminLogin          = '/admin/auth/login';
  static const adminPermissions    = '/admin/auth/permissions';
  static const auditLogs           = '/admin/audit-logs';
  static const auditLogsExport     = '/admin/audit-logs/export';
  static const bulkUpload          = '/admin/employees/bulk-upload';
  static const employeeOffboard    = '/admin/employees/{id}/offboard';
  static const vendors             = '/admin/vendors';
  static const vendorSuspend       = '/admin/vendors/{id}/suspend';
  static const vendorReactivate    = '/admin/vendors/{id}/reactivate';
  static const delegates           = '/admin/delegates';
  static const sessions            = '/admin/sessions';

  // Tenants — Public
  static const tenants             = '/tenants';
  static const tenantSettings      = '/tenants/{id}/settings';
  static const tenantsValidate     = '/tenants/validate';
}
```

### 2. `lib/core/constants/error_codes.dart` — Add missing error codes

```dart
class ErrorCodes {
  static const validationError       = 'VALIDATION_ERROR';
  static const otpInvalid            = 'OTP_INVALID';
  static const otpExpired            = 'OTP_EXPIRED';
  static const otpMaxAttempts        = 'OTP_MAX_ATTEMPTS';
  static const otpRateLimit          = 'OTP_RATE_LIMIT';
  static const accountLocked         = 'ACCOUNT_LOCKED';       // NEW in v4.2
  static const userNotFound          = 'USER_NOT_FOUND';
  static const userAlreadyExists     = 'USER_ALREADY_EXISTS';
  static const accountDeactivated    = 'ACCOUNT_DEACTIVATED';
  static const accountSuspended      = 'ACCOUNT_SUSPENDED';
  static const accountDeleted        = 'ACCOUNT_DELETED';
  static const emailNotVerified      = 'EMAIL_NOT_VERIFIED';
  static const employeeIdNotFound    = 'EMPLOYEE_ID_NOT_FOUND';
  static const alreadyEmployee       = 'ALREADY_EMPLOYEE';     // NEW in v4.2
  static const tenantMismatch        = 'TENANT_MISMATCH';
  static const tenantClosed          = 'TENANT_CLOSED';        // NEW in v4.2
  static const permissionDenied      = 'PERMISSION_DENIED';
  static const tokenExpired          = 'TOKEN_EXPIRED';
  static const refreshTokenInvalid   = 'REFRESH_TOKEN_INVALID';
  static const refreshTokenReused    = 'REFRESH_TOKEN_REUSED';
  static const ssoDomainMismatch     = 'SSO_DOMAIN_MISMATCH';
  static const ssoProviderError      = 'SSO_PROVIDER_ERROR';
  static const delegationExpired     = 'DELEGATION_EXPIRED';
  static const internalError         = 'INTERNAL_ERROR';
  static const unauthorized          = 'UNAUTHORIZED';
  static const authLoginFailed       = 'AUTH_LOGIN_FAILED';

  static String getMessage(String code) {
    return {
      'VALIDATION_ERROR':        'Please check your input and try again.',
      'OTP_INVALID':             'Incorrect OTP. Please try again.',
      'OTP_EXPIRED':             'OTP has expired. Request a new one.',
      'OTP_MAX_ATTEMPTS':        'Too many wrong attempts. Try again in 15 minutes.',
      'OTP_RATE_LIMIT':          'Too many OTP requests. Wait 15 minutes before trying again.',
      'ACCOUNT_LOCKED':          'Account locked — too many failed attempts. Try again in 15 minutes.',
      'USER_NOT_FOUND':          'No account found with this number.',
      'USER_ALREADY_EXISTS':     'This phone number is already registered.',
      'ACCOUNT_DEACTIVATED':     'Your account has been deactivated. Contact support.',
      'ACCOUNT_SUSPENDED':       'Your account has been suspended. Contact support.',
      'ACCOUNT_DELETED':         'This account no longer exists.',
      'EMAIL_NOT_VERIFIED':      'Please activate your account first. Check your email.',
      'EMPLOYEE_ID_NOT_FOUND':   'Employee ID not found. Please contact your HR admin.',
      'ALREADY_EMPLOYEE':        'Your account is already linked to a company.',
      'TENANT_MISMATCH':         'Access denied for this company.',
      'TENANT_CLOSED':           'This location is not currently accepting registrations.',
      'PERMISSION_DENIED':       'You do not have permission for this action.',
      'TOKEN_EXPIRED':           'Session expired. Please log in again.',
      'REFRESH_TOKEN_INVALID':   'Session invalid. Please log in again.',
      'REFRESH_TOKEN_REUSED':    'Security alert. Please log in again.',
      'SSO_DOMAIN_MISMATCH':     'Your company email is not registered on Bhojan.',
      'SSO_PROVIDER_ERROR':      'Google sign-in failed. Please try again.',
      'DELEGATION_EXPIRED':      'Your temporary access has expired.',
      'INTERNAL_ERROR':          'Something went wrong. Please try again.',
      'UNAUTHORIZED':            'Please log in to continue.',
      'AUTH_LOGIN_FAILED':       'Incorrect password. Please try again.',
    }[code] ?? 'Something went wrong. Please try again.';
  }
}
```

### 3. `lib/features/auth/models/user_model.dart` — Add missing fields

```dart
class UserModel {
  final String id;
  final String phone;
  final String? email;
  final String fullName;
  final String role;
  final String? tenantId;      // null for GUEST
  final bool isEmployee;        // NEW — true only for USER role
  final String? employeeId;     // NEW — null for GUEST/VENDOR/ADMIN
  final bool isVerified;
  final String? lastLoginAt;
  // ... existing fields
}
```

### 4. `lib/core/api/interceptors/auth_interceptor.dart` — Confirm it handles all cases

```dart
// Must handle:
// 1. Attach Authorization: Bearer <token> to every request
// 2. On 401 TOKEN_EXPIRED → call EP-04 /auth/token/refresh → retry original request
// 3. On 401 REFRESH_TOKEN_INVALID → clear secure storage → redirect to login
// 4. On 403 ACCOUNT_SUSPENDED → clear storage → show suspension message
// 5. On 403 ACCOUNT_DELETED → clear storage → show deletion message
// 6. On 403 ACCOUNT_DEACTIVATED → clear storage → show deactivation message
```

---

## Build Order — P0 First

Build in this exact order. Complete P0 before starting P1.

---

## Sprint 1 — User App Registration & Login (P0)

These are the most critical screens. Build these first.

### Screen 1 — Tenant Selection (EP-35)

**File:** `lib/features/auth/screens/tenant_select_screen.dart` (NEW)

This is the very first screen for Employee registration. Employee users must pick their company before registering.

**Flow:** App opens → "Are you a Company Employee?" → Yes → show company list (EP-35) → user selects company → EP-37 validates it's accepting registrations → proceed to Employee Register screen

```
UI Elements:
- Search bar to filter companies
- List of company cards: logo + name + location
- Each card taps → validates via EP-37 → navigates to register

API calls:
- GET /tenants (EP-35) — load company list on screen open
- POST /tenants/validate (EP-37) — call when user taps a company
```

**Mock data (EP-35):**
```json
{ "tenants": [
  { "id": "uuid-1", "name": "Infosys", "city": "Bangalore", "location": "Electronic City", "logo_url": null, "has_active_cafeteria": true },
  { "id": "uuid-2", "name": "Capgemini", "city": "Bangalore", "location": "Manyata Tech Park", "logo_url": null, "has_active_cafeteria": true }
]}
```

---

### Screen 2 — Sign Up Type Selection

**File:** `lib/features/auth/screens/sign_up_type_screen.dart` (NEW)

Two large cards:
- "I'm a Company Employee" → navigates to Employee Register screen
- "I'm a Guest / Visitor" → navigates to Guest Register screen

No API call on this screen.

---

### Screen 3 — Guest Registration (EP-01, EP-02)

**File:** `lib/features/auth/screens/guest_register_screen.dart` (NEW)

**Fields:** Full Name · Phone (+91XXXXXXXXXX) · Password (min 8 chars, 1 uppercase, 1 number, 1 special) · Terms checkbox

**Flow:**
1. User fills form → tap Register
2. Call EP-01 with `user_type: "GUEST"` → receive `otp_reference`
3. Navigate to OTP screen
4. User enters OTP → EP-02 → receive `access_token` + `refresh_token` + user object
5. Save tokens to secure storage → navigate to Home

**Errors to handle:** `USER_ALREADY_EXISTS` (409), `OTP_RATE_LIMIT` (429), `VALIDATION_ERROR` (400)

---

### Screen 4 — Employee Registration (EP-01, EP-02)

**File:** `lib/features/auth/screens/employee_register_screen.dart` (NEW)

**Fields:** Full Name · Work Email · Phone · Employee ID · Password · Terms checkbox

**Important:** Employee must have selected a company on the Tenant Selection screen first. The selected `tenant_id` is stored in state — but you do NOT send it in the EP-01 request body. Backend reads `tenant_id` from the `employee_roster` using the `employee_id`. Never send `tenant_id` from client.

**Flow:** Same as Guest but with `user_type: "EMPLOYEE"`, additional fields, and extra error `EMPLOYEE_ID_NOT_FOUND`.

---

### Screen 5 — OTP Verification (EP-02) — UPDATE existing

**File:** `lib/features/auth/screens/otp_screen.dart` (UPDATE — already exists)

This screen is dual-purpose — used for both Registration OTP and Login OTP. The `context` (registration vs login) is passed as a parameter.

**UI:** 6-box OTP input with auto-read SMS · Resend OTP timer (60 seconds) · Resend button after timer

**Errors:** `OTP_INVALID`, `OTP_EXPIRED`, `OTP_MAX_ATTEMPTS`

---

### Screen 6 — Password Login (EP-03) — UPDATE existing

**File:** `lib/features/auth/screens/login_screen.dart` (UPDATE — already exists)

**Remove** any email field. Login is **phone only**.

**Fields:** Phone number · Password · "Forgot Password?" link · "Login with OTP" link

**Flow:** Call EP-03 → save tokens → navigate to Home

**On 3rd, 4th failed attempt:** Backend sends `message` like "2 attempts remaining". Show this in UI.  
**On 5th failed attempt:** `ACCOUNT_LOCKED` (429) — show "Account locked for 15 minutes".

---

## Sprint 2 — User App Profile (P1)

Build these after Sprint 1 screens are done.

### Screen 7 — View Profile (EP-06)

**File:** `lib/features/profile/screens/profile_screen.dart` (NEW)

**Data to display:**
- Avatar image (from `profile.avatar_url`)
- Full name, phone, email (if employee)
- Role badge (GUEST / Employee)
- Department, floor, building (if set)
- Food preferences (dietary type)

**For GUEST users:** Show a "Link Company Account" button → navigates to Upgrade to Employee screen

---

### Screen 8 — Edit Profile (EP-07, EP-08)

**File:** `lib/features/profile/screens/edit_profile_screen.dart` (NEW)

**Editable fields:** Full Name · Department · Floor · Building · Dietary preference · Notification preferences · Language

**Avatar upload:** Tap avatar → pick from gallery (JPEG/PNG, max 5MB) → call EP-08 multipart → update displayed avatar

**Important:** Phone and email changes go to a separate screen (Change Contact). Password changes go to Forgot Password screen.

---

### Screen 9 — Forgot Password (EP-09, EP-10)

**File:** `lib/features/profile/screens/forgot_password_screen.dart` (NEW)

**Step 1 — Enter phone:**
- Call EP-09 — always shows "OTP sent" message even if account doesn't exist (anti-enumeration)

**Step 2 — Enter OTP + New Password:**
- OTP box + new password field + confirm password field
- Call EP-10
- On success: all sessions revoked, navigate to Login with message "Password updated. Please log in again."

---

### Screen 10 — Change Contact (EP-11, EP-12)

**File:** `lib/features/profile/screens/change_contact_screen.dart` (NEW)

**Step 1 — Select type + enter new value:**
- Toggle: Phone / Email
- Input new phone/email
- Call EP-11 → receive `request_id`
- Show: "OTP sent to both your current and new contact"

**Step 2 — Enter both OTPs:**
- Two OTP boxes: "OTP sent to current [phone/email]" and "OTP sent to new [phone/email]"
- Call EP-12 with `request_id`, `otp_old`, `otp_new`
- On success: new tokens issued, save them, show "Contact updated"

---

### Screen 11 — Upgrade to Employee (EP-14)

**File:** `lib/features/profile/screens/upgrade_to_employee_screen.dart` (NEW)

Only shown for GUEST users (check `role == 'GUEST'` from JWT).

**Flow:**
1. Show Tenant Selection screen first (same as registration)
2. Fields: Employee ID + Work Email
3. OTP sent to phone for confirmation
4. Call EP-14
5. On success: new JWT issued with `role: USER`, `tenant_id` set — store new tokens, navigate to profile with "Benefits activated!" message

**Errors:** `ALREADY_EMPLOYEE`, `EMPLOYEE_ID_NOT_FOUND`, `VALIDATION_ERROR` (email mismatch)

---

### Screen 12 — Delete Account (EP-13) — P2

**File:** `lib/features/profile/screens/delete_account_screen.dart` (NEW)

**Flow:**
1. Show confirmation dialog with warning about what gets deleted
2. OTP sent to phone
3. User enters OTP + optional reason
4. Call EP-13 (DELETE /auth/account)
5. Clear all secure storage, navigate to Login with message

---

## Sprint 3 — Vendor App (P0)

### Screen 13 — Vendor Account Activation (EP-17)

**File:** `lib/features/vendor/auth/screens/vendor_activate_screen.dart` (NEW)

This screen is opened from an email link. The activation token comes from the URL query param.

**Fields:** Password · Confirm Password

**Flow:**
1. App opens with deep link: `/vendor/activate?token=xyz`
2. Extract token from URL
3. User sets password → call EP-17 with `activation_token` + `password`
4. On success: navigate to Vendor Login with "Account activated. Please log in."

**Error:** `UNAUTHORIZED` (token expired/already used — 24h TTL)

---

### Screen 14 — Vendor Login (EP-18)

**File:** `lib/features/vendor/auth/screens/vendor_login_screen.dart` (NEW)

**Fields:** Phone number · Password

**Important:** Login is phone, not email.

**Errors:** `EMAIL_NOT_VERIFIED` (vendor hasn't activated yet), `ACCOUNT_SUSPENDED`, `AUTH_LOGIN_FAILED`, `ACCOUNT_LOCKED`

---

### Screen 15 — Vendor Profile (EP-19) — P1

**File:** `lib/features/vendor/profile/screens/vendor_profile_screen.dart` (NEW)

**Editable fields:** Business name · Business address · City · Logo URL · FSSAI number

**Note:** Bank details (bank_name, account_number, IFSC) are restricted in Phase 1. Do not show edit fields for these — show them as read-only with "Contact admin to update" label.

---

## Sprint 4 — Admin App (P0)

### Screen 16 — Admin Login (EP-20)

**File:** `lib/features/admin/auth/screens/admin_login_screen.dart` (NEW)

**Important difference:** Admin uses **email** to log in (not phone). OTP is sent to email.

**Fields:** Work Email · OTP (6 digits)

**Flow:**
1. Admin enters email → tap "Send OTP"
2. OTP sent to email
3. Admin enters OTP → call EP-20
4. On success: store tokens, navigate to Admin Dashboard

---

### Screen 17 — Admin Dashboard (EP-21)

**File:** `lib/features/admin/auth/screens/admin_dashboard_screen.dart` (NEW)

Call EP-21 on load to get the RBAC permissions matrix. Show menu items based on what the role can access.

```
SUPER_ADMIN sees:    Audit Logs · Vendors · Employees · Sessions · Delegations
OPS_ADMIN sees:      Audit Logs · Vendors · Employees
TECH_ADMIN sees:     Audit Logs · Sessions
```

**Include delegation grants** — if OPS_ADMIN has a delegation for FINANCE, show that module too.

---

### Screen 18 — Audit Logs (EP-22) — P0

**File:** `lib/features/admin/audit/screens/audit_log_screen.dart` (NEW)

Paginated list (50 per page) with filter bar.

**Filters:** User ID · Action (dropdown from AuditAction enum) · Module · Date range (from/to)

**Each row shows:** Action · User · Module · IP address · Device · Timestamp

**Pagination:** Load more button or infinite scroll.

**Export button** → triggers EP-23 (async) → shows job ID + polling indicator → when done shows download link

---

### Screen 19 — Vendor Management (EP-27, EP-28, EP-29)

**File:** `lib/features/admin/vendor_mgmt/screens/vendor_list_screen.dart` (NEW)

List of vendors for the tenant. Each row: business name · phone · status badge (Active / Suspended).

**Actions per vendor:**
- Suspend button → confirmation dialog with reason field → EP-28
- Reactivate button (shown when suspended) → confirmation with reason → EP-29

**Create Vendor button** → navigates to Vendor Onboard Screen

---

### Screen 20 — Vendor Onboarding Form (EP-27)

**File:** `lib/features/admin/vendor_mgmt/screens/vendor_onboard_screen.dart` (NEW)

**Required fields:** Email · Phone · Full Name (contact person) · Business Name · Tenant (auto-set for OPS_ADMIN) · Business Address · City · State · Pincode  
**Optional fields:** GSTIN

On submit → EP-27 → on success show "Vendor created. Activation email sent."

---

### Screen 21 — Employee Management (EP-26)

**File:** `lib/features/admin/vendor_mgmt/screens/employee_management_screen.dart` (NEW)

List of employees for the tenant. Each row: name · employee ID · department · status.

**Offboard button** → confirmation dialog with reason field → EP-26 → employee deactivated immediately

---

### Screen 22 — Bulk Employee Upload (EP-24, EP-25)

**File:** `lib/features/admin/vendor_mgmt/screens/bulk_upload_screen.dart` (NEW)

**CSV format:**
```
employee_id,email,full_name,department
EMP001,john@infosys.com,John Doe,Engineering
```

**Flow:**
1. Download CSV template button
2. File picker — select CSV (max 10MB)
3. Call EP-24 → receive `upload_id` (202 Accepted)
4. Poll EP-25 every 3 seconds until `status != PROCESSING`
5. On complete: show success count + failed count + error rows table

---

### Screen 23 — Sessions (EP-33, EP-34) — P1

**File:** `lib/features/admin/vendor_mgmt/screens/sessions_screen.dart` (NEW)

List of active sessions. Each row: user email · device · IP · created date.

**Revoke button** per row → confirmation → EP-34 → session removed from list

---

### Screen 24 — Delegations (EP-30, EP-31, EP-32) — P1

**File:** `lib/features/admin/delegates/screens/delegation_screen.dart` (NEW)

Only visible to SUPER_ADMIN.

**Create delegation form:** Select Admin (delegatee) · Module (dropdown from AppModule enum) · Start date · End date (mandatory) · Reason

**List of active delegations** with Revoke button per row → EP-32

---

## Router — All Routes to Add

Update `lib/app/router.dart` with these new routes:

```dart
// User App routes
'/tenant-select'       → TenantSelectScreen
'/sign-up-type'        → SignUpTypeScreen
'/register/guest'      → GuestRegisterScreen
'/register/employee'   → EmployeeRegisterScreen
'/profile'             → ProfileScreen
'/profile/edit'        → EditProfileScreen
'/profile/avatar'      → (handled inside EditProfileScreen)
'/forgot-password'     → ForgotPasswordScreen
'/change-contact'      → ChangeContactScreen
'/upgrade-to-employee' → UpgradeToEmployeeScreen
'/delete-account'      → DeleteAccountScreen

// Vendor App routes
'/vendor/activate'     → VendorActivateScreen (deep link with ?token=)
'/vendor/login'        → VendorLoginScreen
'/vendor/profile'      → VendorProfileScreen

// Admin App routes
'/admin/login'         → AdminLoginScreen
'/admin/dashboard'     → AdminDashboardScreen
'/admin/audit-logs'    → AuditLogScreen
'/admin/vendors'       → VendorListScreen
'/admin/vendors/new'   → VendorOnboardScreen
'/admin/employees'     → EmployeeManagementScreen
'/admin/bulk-upload'   → BulkUploadScreen
'/admin/sessions'      → SessionsScreen
'/admin/delegations'   → DelegationScreen
```

---

## Models to Create

Create these model files matching the API contract response shapes exactly:

| File | Maps to |
|------|---------|
| `lib/features/profile/models/profile_model.dart` | EP-06 response `data.profile` |
| `lib/features/auth/models/tenant_model.dart` | EP-35 response `data.tenants[]` |
| `lib/features/auth/models/tenant_settings_model.dart` | EP-36 response `data` |
| `lib/features/vendor/models/vendor_profile_model.dart` | EP-19 response |
| `lib/features/admin/models/audit_log_model.dart` | EP-22 response `data.logs[]` |
| `lib/features/admin/models/delegation_model.dart` | EP-31 response `data.delegations[]` |
| `lib/features/admin/models/session_model.dart` | EP-33 response `data.sessions[]` (already exists — confirm fields) |
| `lib/features/admin/models/bulk_upload_model.dart` | EP-25 response `data` |

---

## Secure Storage — What to Store

All tokens go in `flutter_secure_storage`. **Never use SharedPreferences for tokens.**

```dart
// Keys to store
'access_token'      → JWT access token (15 min TTL)
'refresh_token'     → JWT refresh token (7 day TTL)
'user_role'         → 'USER' | 'GUEST' | 'VENDOR' | 'SUPER_ADMIN' | etc.
'tenant_id'         → UUID (null/empty string for GUEST)
'is_employee'       → 'true' | 'false'
'user_id'           → UUID
```

---

## Auth Interceptor — Full Behaviour

Confirm `lib/core/api/interceptors/auth_interceptor.dart` handles all of this:

```
Every request:
  → Add header: Authorization: Bearer {access_token from secure storage}

On response error:
  → 401 TOKEN_EXPIRED:
      1. Call POST /auth/token/refresh with { refresh_token }
      2. Save new access_token + refresh_token to secure storage
      3. Retry original request with new access_token

  → 401 REFRESH_TOKEN_INVALID or REFRESH_TOKEN_REUSED:
      1. Clear all secure storage (both tokens)
      2. Navigate to login screen
      3. Show message: "Session expired. Please log in again."

  → 403 ACCOUNT_SUSPENDED:
      1. Clear secure storage
      2. Navigate to login screen
      3. Show message from ErrorCodes.getMessage('ACCOUNT_SUSPENDED')

  → 403 ACCOUNT_DELETED:
      1. Clear secure storage
      2. Navigate to login screen
      3. Show message from ErrorCodes.getMessage('ACCOUNT_DELETED')

  → 403 ACCOUNT_DEACTIVATED:
      1. Clear secure storage
      2. Navigate to login screen
      3. Show message from ErrorCodes.getMessage('ACCOUNT_DEACTIVATED')
```

---

## Backend Handoff — When to Swap Mock to Real

Track this table as Shreyas deploys endpoints. When an endpoint is marked "Live on staging", flip the service to real.

| EP# | Endpoint | Priority | Backend Owner | Live on Staging? |
|-----|----------|----------|---------------|-----------------|
| EP-35 | GET /tenants | P0 | Shreyas | ☐ |
| EP-36 | GET /tenants/:id/settings | P0 | Shreyas | ☐ |
| EP-37 | POST /tenants/validate | P0 | Shreyas | ☐ |
| EP-01 | POST /auth/register | P0 | Shreyas | ☐ |
| EP-02 | POST /auth/otp/verify | P0 | Shreyas | ☐ |
| EP-03 | POST /auth/login/password | P0 | Shreyas | ☐ |
| EP-04 | POST /auth/token/refresh | P0 | Shreyas | ☐ |
| EP-05 | POST /auth/logout | P0 | Shreyas | ☐ |
| EP-06 | GET /auth/me | P0 | Shreyas | ☐ |
| EP-17 | POST /vendor/auth/activate | P0 | Nandan | ☐ |
| EP-18 | POST /vendor/auth/login | P0 | Nandan | ☐ |
| EP-20 | POST /admin/auth/login | P0 | Shreyas | ☐ |
| EP-21 | GET /admin/auth/permissions | P0 | Shreyas | ☐ |
| EP-22 | GET /admin/audit-logs | P0 | Shreyas | ☐ |
| EP-24 | POST /admin/employees/bulk-upload | P0 | Bhrigu | ☐ |
| EP-25 | GET /admin/employees/bulk-upload/:id | P0 | Bhrigu | ☐ |
| EP-26 | POST /admin/employees/:id/offboard | P0 | Shreyas | ☐ |
| EP-27 | POST /admin/vendors | P0 | Nandan | ☐ |
| EP-28 | POST /admin/vendors/:id/suspend | P0 | Bhrigu | ☐ |
| EP-29 | POST /admin/vendors/:id/reactivate | P0 | Bhrigu | ☐ |
| EP-07 | PUT /auth/profile | P1 | Shreyas | ☐ |
| EP-08 | POST /auth/profile/avatar | P1 | Shreyas | ☐ |
| EP-09 | POST /auth/password/reset-request | P1 | Shreyas | ☐ |
| EP-10 | POST /auth/password/reset-verify | P1 | Shreyas | ☐ |
| EP-11 | POST /auth/contact/change | P1 | Shreyas | ☐ |
| EP-12 | POST /auth/contact/verify | P1 | Shreyas | ☐ |
| EP-14 | POST /auth/upgrade-to-employee | P1 | Shreyas | ☐ |
| EP-19 | PUT /vendor/auth/profile | P1 | Nandan | ☐ |
| EP-23 | GET /admin/audit-logs/export | P1 | Bhrigu | ☐ |
| EP-30 | POST /admin/delegates | P1 | Bhrigu | ☐ |
| EP-31 | GET /admin/delegates | P1 | Bhrigu | ☐ |
| EP-32 | DELETE /admin/delegates/:id | P1 | Bhrigu | ☐ |
| EP-33 | GET /admin/sessions | P1 | Shreyas | ☐ |
| EP-34 | DELETE /admin/sessions/:id | P1 | Shreyas | ☐ |
| EP-15 | GET /auth/sso/google | P2 | Nandan | ☐ |
| EP-16 | GET /auth/sso/google/callback | P2 | Nandan | ☐ |
| EP-13 | DELETE /auth/account | P2 | Shreyas | ☐ |

---

## Phase 5 Exit Checklist

- [ ] All P0 screens implemented and connected to staging APIs
- [ ] OTP auto-read from SMS working on Android and iOS
- [ ] Token refresh interceptor working — no manual logout on token expiry
- [ ] All error codes displaying correct user-friendly messages
- [ ] Avatar upload working — image picked, uploaded, displayed
- [ ] Guest vs Employee registration flows both working end-to-end
- [ ] Guest → Employee upgrade flow working
- [ ] Admin RBAC working — OPS_ADMIN cannot see SUPER_ADMIN-only screens
- [ ] Tenant selection + validation working before registration
- [ ] Vendor activation deep link working
- [ ] Bulk upload + polling working with a real CSV
- [ ] APK and IPA distributed to team via Firebase App Distribution
- [ ] Sakshi QA sign-off on Admin App screens

---

*Plan owner: Rohit (frontend) · Sakshi (Admin App QA)*  
*API contracts source of truth: `BHOJAN_AUTH_API_CONTRACTS v 2.md`*  
*Last updated: April 2026 · Module 1 AUTH Phase 5 · Running in parallel with Phase 4 backend*
