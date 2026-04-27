# Bhojan — Frontend UI Specification
## Module 1: Authentication & User Management
### Three Apps: User App · Vendor App · Admin App

> **Purpose:** This document tells the frontend team exactly what each screen must contain,
> which API it calls, what validations to apply, and how to navigate between screens.
> Cross-check every screen against this spec before marking it complete.

---

## Screen Count Summary

| App        | Screens | Priority Screens (P0) |
|------------|---------|----------------------|
| User App   | 17      | 10                   |
| Vendor App | 5       | 3                    |
| Admin App  | 12      | 8                    |
| **Total**  | **34**  | **21**               |

---

## Global Rules (Apply to ALL Three Apps)

### API Response Format
Every API response follows this envelope:
```json
// Success
{ "success": true, "data": { ... }, "message": "..." }

// Error
{ "success": false, "error": { "code": "ERROR_CODE", "message": "Human readable" } }
```
Always check `response.success` first. Show `error.message` on failure.

### Auth Header
All protected screens must send: `Authorization: Bearer <access_token>`

### Token Storage
- Store `access_token` (15 min TTL) and `refresh_token` (7 day TTL) in secure storage
- On any `401 TOKEN_EXPIRED` error → call EP-04 silently to refresh → retry original request
- On `401 REFRESH_TOKEN_INVALID` → clear storage → redirect to Login screen

### Loading States
Every button that triggers an API call must:
1. Show a loading spinner / disable the button while waiting
2. Re-enable on success or error response

### OTP Input
- 6 individual character boxes (not a single text field)
- Auto-advance focus to next box on each digit entry
- Auto-submit when 6th digit is entered
- Keyboard type: numeric

### Phone Number Format
- All phone fields: `+91XXXXXXXXXX` (Indian mobile, 10 digits after +91)
- Show "+91" as a fixed prefix in the input field
- User types only the 10-digit number
- Validate: starts with 6, 7, 8, or 9 after +91

### Password Rules
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 number
- At least 1 special character
- Show/hide password toggle (eye icon)
- Show a strength indicator while typing

### Error Code → User Message Mapping
| Error Code             | Message to Show User                                      |
|------------------------|-----------------------------------------------------------|
| `VALIDATION_ERROR`     | Show field-level error next to the relevant input         |
| `USER_ALREADY_EXISTS`  | "This phone/email is already registered."                 |
| `USER_NOT_FOUND`       | "No account found with this number."                      |
| `OTP_INVALID`          | "Incorrect OTP. Please try again."                        |
| `OTP_EXPIRED`          | "OTP has expired. Request a new one."                     |
| `OTP_MAX_ATTEMPTS`     | "Too many wrong attempts. Try again in 15 minutes."       |
| `OTP_RATE_LIMIT`       | "Too many OTP requests. Wait 15 minutes."                 |
| `ACCOUNT_LOCKED`       | "Account locked. Too many wrong passwords. Try in 15 min."|
| `ACCOUNT_SUSPENDED`    | "Your account has been suspended. Contact support."       |
| `ACCOUNT_DEACTIVATED`  | "Your account is deactivated. Contact your HR."           |
| `ACCOUNT_DELETED`      | "This account no longer exists."                          |
| `AUTH_LOGIN_FAILED`    | "Incorrect password. X attempts remaining."               |
| `EMPLOYEE_ID_NOT_FOUND`| "Employee ID not found. Check with your HR team."         |
| `ALREADY_EMPLOYEE`     | "Your account is already linked to a company."            |
| `INTERNAL_ERROR`       | "Something went wrong. Please try again."                 |

---

# ═══════════════════════════════════════
# PART 1 — USER APP (17 Screens)
# ═══════════════════════════════════════

The User App is for company employees and guests ordering food.
Roles: `GUEST` (no company linkage) and `USER` (company employee).

---

## U-01 · Splash Screen
**Priority:** P0 | **Auth Required:** No

### Purpose
App launch screen. Checks if user is already logged in.

### UI Elements
- Bhojan logo (centered)
- App tagline (optional)
- Full-screen background color / gradient

### Logic on Mount
1. Check secure storage for `access_token` and `refresh_token`
2. If tokens exist → call `GET /auth/me` silently
   - Success → navigate to **U-11 Home/Dashboard**
   - `401` → try EP-04 refresh → if refresh succeeds, go to Home → if fails, clear tokens → go to **U-02**
3. If no tokens → navigate to **U-02 Tenant Selection** after 2 seconds

### Navigation
- Auto → **U-02** (first launch) or **U-11** (returning user)

---

## U-02 · Tenant Selection Screen
**Priority:** P0 | **Auth Required:** No | **API:** EP-35, EP-36, EP-37

### Purpose
User selects their company/cafeteria before registering or logging in.
Employees select their company tenant. Guests can also select to browse menu.

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Select Your Company" |
| Search bar | "Search company name..." |
| Tenant list | Scrollable list of cards |
| **Each tenant card** | Company logo (circular, 48×48), company name, `has_active_cafeteria` badge ("Open" / "Closed") |
| Loading skeleton | Show while EP-35 is loading |
| Empty state | "No companies found" if search yields nothing |

### API Calls
- **On screen load:** `GET /tenants` (EP-35) — populate the list
- **On tenant tap:** `POST /tenants/validate` (EP-37) with `{ tenant_id }`
  - If `is_open: true` → also call `GET /tenants/:id/settings` (EP-36) → store tenant settings in app state → navigate to **U-03**
  - If `is_open: false` or `TENANT_CLOSED` error → show inline error on that card: "This company is not accepting registrations right now."

### Data to Store in App State After Selection
- `tenant_id`
- `tenant_name`
- `subsidy_per_meal`
- `meal_window_start` / `meal_window_end`
- `wallet_enabled`
- `max_wallet_balance`

### Navigation
- Tap tenant card (open) → **U-03 Welcome / Auth Choice**

---

## U-03 · Welcome / Auth Choice Screen
**Priority:** P0 | **Auth Required:** No

### Purpose
After tenant is selected, user chooses how to proceed.

### UI Elements
| Element | Detail |
|---------|--------|
| Selected tenant display | Small logo + name at top ("Logging in for: Capgemini") |
| "Create Account" button | Primary CTA → leads to registration type choice |
| "Login with Password" button | Secondary → **U-08 Password Login** |
| "Login with OTP" button | Secondary → shows phone input → sends OTP → **U-07 OTP Verify** |
| "Continue with Google" button | Google logo + text → opens browser for OAuth (EP-15) |
| "Change Company" link | Back to **U-02** |

### OTP Login Flow (from this screen)
1. Show a bottom sheet / modal with phone input
2. Call `POST /auth/password/reset-request` — No, actually for OTP login call `POST /auth/register` is wrong. The OTP login is: user requests an OTP to be sent to their phone, then verifies via EP-02 (OTP Login path)
   - Actually there's no separate "send OTP for login" endpoint. The flow is:
   - User enters phone → app calls the OTP send (which is part of the register flow if user exists, EP-02 handles login path automatically when `reg_pending:{phone}` does not exist)
   - For pure OTP login: show phone input → call `POST /auth/password/reset-request` to trigger OTP? No.
   - **Correct flow:** There's no dedicated "OTP login" endpoint. The OTP login path in EP-02 works when `reg_pending:{phone}` is NOT in Redis. So to trigger OTP login: the backend needs to have an OTP stored for that phone. The app must first call some endpoint to send the OTP.
   - Looking at the codebase, there's no `/auth/otp/send` endpoint. OTP login works after registration sends an OTP. For a returning user OTP login, the frontend would need a separate "send OTP" flow.
   - **For now:** only show "Login with Password" and "Register" for OTP. The OTP option in the auth choice can be shown but note that OTP login for returning users is not a separate EP — EP-02 handles it when `reg_pending` doesn't exist. The frontend would need to have a way to trigger an OTP send for existing users, which may be implemented via a `/auth/otp/send` endpoint in a future sprint, or by using the password reset OTP flow.
   - **Simplest approach:** Show OTP Login button but it just sends to the password reset OTP flow (EP-09 triggers OTP, EP-02 verifies but for login — or simply treat the reset OTP as login OTP). Actually this is a product decision.
   - For the spec: mark "Login with OTP" as P2, note it requires a `/auth/otp/send` endpoint to be added.

### Navigation
- "Create Account" → show bottom sheet to choose GUEST or EMPLOYEE → **U-04** or **U-05**
- "Login with Password" → **U-08**
- "Continue with Google" → browser WebView/in-app browser → EP-15/16

---

## U-04 · GUEST Registration Screen
**Priority:** P0 | **Auth Required:** No | **API:** EP-01

### Purpose
New user without a company employee ID registers as a Guest.
Can order food but without company subsidy.

### UI Elements
| Field | Type | Validation | Placeholder |
|-------|------|------------|-------------|
| Full Name | Text input | Required, 1–100 chars | "Your full name" |
| Phone Number | Phone input | Required, `+91[6-9]XXXXXXXXX` | "+91 XXXXX XXXXX" |
| Password | Password input (hidden) | Min 8 chars, 1 upper, 1 number, 1 special | "Create a password" |
| Confirm Password | Password input (hidden) | Must match Password | "Confirm password" |

| Element | Detail |
|---------|--------|
| Screen title | "Create Guest Account" |
| Tenant badge | Shows selected tenant at top |
| Password strength bar | Weak / Medium / Strong color indicator |
| "Register" button | Primary, disabled until all fields valid |
| "Already have an account? Login" | Link → **U-08** |
| Terms & Privacy checkbox | Required to enable Register button |

### API Call — On "Register" tap
`POST /auth/register` with:
```json
{
  "user_type": "GUEST",
  "full_name": "<value>",
  "phone": "<+91XXXXXXXXXX>",
  "password": "<value>"
}
```

### Success Response
`{ "success": true, "data": { "otp_reference": "...", "expires_in": 300 } }`
→ Navigate to **U-07 OTP Verification** (pass phone number)

### Error Handling
| Error Code | Action |
|------------|--------|
| `USER_ALREADY_EXISTS` | Show below phone field: "This number is already registered. Login instead?" with link |
| `OTP_RATE_LIMIT` | Show toast: "Too many OTP requests. Wait 15 minutes." |
| `VALIDATION_ERROR` | Show field-level errors |

---

## U-05 · Employee Registration Screen
**Priority:** P0 | **Auth Required:** No | **API:** EP-01

### Purpose
User with a company employee ID registers as an Employee.
Gets company subsidy on meals.

### UI Elements
| Field | Type | Validation | Placeholder |
|-------|------|------------|-------------|
| Full Name | Text input | Required, 1–100 chars | "Your full name" |
| Phone Number | Phone input | Required, `+91[6-9]XXXXXXXXX` | "+91 XXXXX XXXXX" |
| Work Email | Email input | Required, valid email format | "your@company.com" |
| Employee ID | Text input | Required | "e.g. EMP001" |
| Password | Password input | Min 8 chars, 1 upper, 1 number, 1 special | "Create a password" |
| Confirm Password | Password input | Must match | "Confirm password" |

| Element | Detail |
|---------|--------|
| Screen title | "Create Employee Account" |
| Tenant badge | Shows selected tenant at top ("Registering for: Capgemini") |
| Info note | "Your Employee ID and work email must match your company's records." |
| Password strength bar | Weak / Medium / Strong |
| "Register" button | Primary, disabled until all valid |
| Terms & Privacy checkbox | Required |
| "Already have an account? Login" | → **U-08** |

### API Call — On "Register" tap
`POST /auth/register` with:
```json
{
  "user_type": "EMPLOYEE",
  "full_name": "<value>",
  "phone": "<+91XXXXXXXXXX>",
  "email": "<work@company.com>",
  "employee_id": "<EMP001>",
  "password": "<value>"
}
```
> `tenant_id` is NOT sent — backend reads it from the employee roster.

### Success → Navigate to **U-07 OTP Verification**

### Error Handling
| Error Code | Field to highlight | Message |
|------------|--------------------|---------|
| `USER_ALREADY_EXISTS` | Phone or Email | "This phone/email is already registered." |
| `EMPLOYEE_ID_NOT_FOUND` | Employee ID | "Employee ID not found. Check with your HR team." |
| `VALIDATION_ERROR` | Relevant field | Show per-field message |

---

## U-06 · Registration Type Choice (Bottom Sheet)
**Priority:** P0 | **Auth Required:** No

### Purpose
Appears as a modal/bottom sheet when user taps "Create Account" on U-03.

### UI Elements
| Element | Detail |
|---------|--------|
| Sheet title | "How would you like to register?" |
| Option 1 | Icon + "Guest" + subtitle "Order food without company linkage" → **U-04** |
| Option 2 | Icon + "Employee" + subtitle "Use your company employee ID for subsidies" → **U-05** |
| Cancel | Dismiss sheet |

---

## U-07 · OTP Verification Screen
**Priority:** P0 | **Auth Required:** No | **API:** EP-02

### Purpose
Shared screen used for:
1. Post-registration OTP verify (creates account)
2. OTP-based login (for returning users)

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Verify Your Phone" |
| Subtitle | "Enter the 6-digit OTP sent to +91XXXXXXXXXX" (show masked number) |
| OTP Input | 6 individual digit boxes, numeric keyboard, auto-advance |
| Countdown timer | "OTP expires in 4:32" — counts down from 5:00 |
| "Resend OTP" button | Greyed out during countdown, enabled after timer hits 0:00 |
| "Change Number" link | Goes back to previous screen |

### API Call — On OTP entry (auto-submits on 6th digit)
`POST /auth/otp/verify` with:
```json
{ "phone": "+91XXXXXXXXXX", "otp": "123456" }
```

### Success Response
```json
{
  "success": true,
  "data": {
    "access_token": "...",
    "refresh_token": "...",
    "user": { "id": "...", "role": "GUEST|USER", "tenant_id": "...", ... }
  }
}
```
→ Store both tokens securely → Navigate to **U-11 Home/Dashboard**

### Error Handling
| Error Code | Action |
|------------|--------|
| `OTP_INVALID` | Shake animation on boxes, clear input, show "Incorrect OTP. X attempts remaining." |
| `OTP_EXPIRED` | Show "OTP has expired." Enable Resend button immediately |
| `OTP_MAX_ATTEMPTS` | Disable input + Resend, show "Too many wrong attempts. Try again in 15 minutes." |

### Resend OTP
- Tap "Resend OTP" → call `POST /auth/register` again (same body as before) for registration path
- Reset countdown to 5:00

---

## U-08 · Password Login Screen
**Priority:** P0 | **Auth Required:** No | **API:** EP-03

### Purpose
Login using phone number and password.

### UI Elements
| Field | Type | Validation | Placeholder |
|-------|------|------------|-------------|
| Phone Number | Phone input | Required, `+91[6-9]XXXXXXXXX` | "+91 XXXXX XXXXX" |
| Password | Password input | Required | "Enter your password" |

| Element | Detail |
|---------|--------|
| Screen title | "Welcome Back" |
| Tenant badge | Small logo + name at top |
| Show/hide password icon | Eye icon on password field |
| "Forgot Password?" | Link → **U-09** |
| "Login" button | Primary, disabled until both fields filled |
| "Don't have an account? Register" | → **U-06 Registration Type Choice** |
| "Continue with Google" | → Google OAuth (EP-15) |

### API Call
`POST /auth/login/password` with:
```json
{ "phone": "+91XXXXXXXXXX", "password": "..." }
```

### Success → Store tokens → Navigate to **U-11 Home/Dashboard**

### Error Handling
| Error Code | Action |
|------------|--------|
| `USER_NOT_FOUND` | Below phone: "No account found with this number." |
| `AUTH_LOGIN_FAILED` | Below password: "Incorrect password." + if `message` contains "attempts remaining" show it |
| `ACCOUNT_LOCKED` | Full-screen / modal: "Too many wrong attempts. Try again after 15 minutes." with a countdown |
| `ACCOUNT_SUSPENDED` | Modal: "Your account has been suspended. Contact support." |
| `ACCOUNT_DEACTIVATED` | Modal: "Your account has been deactivated. Contact your HR." |

---

## U-09 · Forgot Password — Phone Screen
**Priority:** P1 | **Auth Required:** No | **API:** EP-09

### Purpose
User enters their registered phone number to receive a password reset OTP.

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Reset Password" |
| Subtitle | "Enter your registered phone number and we'll send you an OTP." |
| Phone input | `+91XXXXXXXXXX` format |
| "Send OTP" button | Primary |
| "Back to Login" link | → **U-08** |

### API Call
`POST /auth/password/reset-request` with `{ "phone": "+91XXXXXXXXXX" }`

### Important
- This endpoint **always returns 200** regardless of whether the phone is registered.
  Do NOT show "phone not found" — this is by design (prevents account enumeration).
- On success (any 200): show message "If an account exists with this number, an OTP has been sent."
- Navigate to **U-10 Forgot Password — Reset Screen**

---

## U-10 · Forgot Password — Reset Screen
**Priority:** P1 | **Auth Required:** No | **API:** EP-10

### Purpose
User enters the OTP they received and sets a new password.

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Set New Password" |
| Subtitle | "Enter the OTP sent to +91XXXXXXXXXX" |
| OTP Input | 6 digit boxes (same as U-07) |
| Countdown timer | 5 minutes |
| "Resend OTP" | Greyed during countdown |
| New Password | Password input, strength bar |
| Confirm New Password | Must match |
| "Reset Password" button | Disabled until OTP filled + passwords match |

### API Call
`POST /auth/password/reset-verify` with:
```json
{
  "phone": "+91XXXXXXXXXX",
  "otp": "123456",
  "new_password": "NewPass@123"
}
```

### Success
- Show toast: "Password reset successfully. Please log in."
- All previous sessions revoked on backend
- Navigate to **U-08 Password Login**

### Error Handling
| Error Code | Action |
|------------|--------|
| `OTP_INVALID` | Clear OTP boxes, "Incorrect OTP." |
| `OTP_EXPIRED` | "OTP expired. Request a new one." Enable resend. |
| `VALIDATION_ERROR` | Show password strength error |

---

## U-11 · Home / Dashboard Screen
**Priority:** P0 | **Auth Required:** Yes (Bearer)

### Purpose
Landing screen after successful login. Shows user info and quick actions.
(This is the post-auth shell — actual food ordering is Phase 2+)

### UI Elements
| Element | Detail |
|---------|--------|
| Top bar | Avatar thumbnail + "Hi, [First Name]" + notification bell icon |
| Role badge | "Guest" or "Employee" pill |
| Tenant name | "Capgemini Cafeteria" |
| Subsidy card | Shows subsidy_per_meal from tenant settings (only for USER role) |
| Meal window | "Available: 07:00 – 22:00" |
| Quick links | Profile, Settings |
| Upgrade banner | Shown only for GUEST role: "Unlock subsidies — link your employee account" → **U-17** |
| Bottom nav bar | Home · Orders · Wallet · Profile |

### Navigation
- Profile tab → **U-12 Profile View**

---

## U-12 · Profile View Screen
**Priority:** P0 | **Auth Required:** Yes | **API:** EP-06

### Purpose
Shows the full profile of the logged-in user.

### API Call on Load
`GET /auth/me` → populate all fields

### UI Elements
| Element | Detail |
|---------|--------|
| Avatar | Circular, 80×80, tap to upload (→ EP-08) |
| Full Name | Large text, edit icon |
| Role badge | "Guest" or "Employee" |
| Phone | With a phone icon |
| Email | With email icon (hidden if null) |
| Employee ID | Only shown if `is_employee = true` |
| Tenant | Company name |
| Department | Only shown if set |
| Floor | Only shown if set |
| Building | Only shown if set |
| Last Login | "Last login: 2 hours ago" (relative time) |
| "Edit Profile" button | → **U-13** |
| "Change Contact" button | → **U-14** |
| "Upgrade to Employee" button | Only shown if `role === 'GUEST'` → **U-17** |
| "Delete Account" button | Red text, at bottom → **U-16** |
| Logout button | With confirm dialog |

### Logout Flow
- Tap Logout → confirm dialog "Are you sure you want to log out?"
- Confirm → `POST /auth/logout` (EP-05) with `{ refresh_token }` using current access token
- Clear all stored tokens → Navigate to **U-02 Tenant Selection**

---

## U-13 · Edit Profile Screen
**Priority:** P1 | **Auth Required:** Yes | **API:** EP-07, EP-08

### Purpose
User can update their display name, work details, and avatar.

### UI Elements
| Field | Type | Max Length | Notes |
|-------|------|------------|-------|
| Avatar | Image picker | — | Tap → pick from gallery/camera → auto-upload via EP-08 |
| Full Name | Text input | 100 chars | Syncs to `users.full_name` + `user_profiles.full_name` |
| Department | Text input | 100 chars | — |
| Floor | Text input | 20 chars | e.g. "3rd Floor" |
| Building | Text input | 100 chars | e.g. "Block A" |
| Dietary Preference | Dropdown / radio | — | Values: VEG · NON_VEG · VEGAN · JAIN (from `preferences.dietary`) |
| Order Notifications | Toggle | — | `preferences.notifications.order` |
| Promo Notifications | Toggle | — | `preferences.notifications.promo` |
| Language | Dropdown | — | `preferences.language` (e.g. "en", "kn", "hi") |
| "Save Changes" button | Primary | — | Disabled until any change is made |

### Avatar Upload (EP-08)
- Tap avatar → open image picker (gallery / camera)
- Compress image to max 5 MB before upload
- Show upload progress indicator on avatar
- `POST /auth/profile/avatar` with `multipart/form-data`, field name `avatar`, JPEG or PNG only
- On success: update avatar_url in local state

### Profile Update (EP-07)
- On "Save Changes" → `PUT /auth/profile` with only the changed fields
- Show success toast: "Profile updated"

---

## U-14 · Contact Change — Init Screen
**Priority:** P1 | **Auth Required:** Yes | **API:** EP-11

### Purpose
User initiates a phone or email change. OTPs will be sent to both old and new contacts for security.

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Change Contact" |
| Segment selector | "Phone" / "Email" tabs |
| Current value | Read-only field showing current phone or email: "Current: +91 98765 43210" |
| New value input | Phone or email field depending on selection |
| Info note | "We'll send an OTP to both your current and new contact to verify this change." |
| "Send OTP" button | Primary |

### API Call
`POST /auth/contact/change` with:
```json
{ "type": "EMAIL", "new_value": "new@company.com" }
// or
{ "type": "PHONE", "new_value": "+91XXXXXXXXXX" }
```

### Success → Navigate to **U-15 Contact Change Verify** (pass `request_id`)

### Error Handling
| Error Code | Action |
|------------|--------|
| `USER_ALREADY_EXISTS` | "This contact is already registered to another account." |
| `VALIDATION_ERROR` | Show format error below input |

---

## U-15 · Contact Change — Verify Screen
**Priority:** P1 | **Auth Required:** Yes | **API:** EP-12

### Purpose
User enters both OTPs (one from old contact, one from new contact) to confirm the change.

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Verify Change" |
| Old contact section | Label: "OTP sent to your current [phone/email]: +91XXXXXX" — 6 digit OTP input |
| New contact section | Label: "OTP sent to your new [phone/email]" — 6 digit OTP input |
| Countdown timer | 5 minutes (same timer for both) |
| "Resend OTPs" | Re-calls EP-11 with same data, resets timer |
| "Verify & Update" button | Enabled only when both OTP fields have 6 digits |
| Important note | "All your active sessions will be logged out after this change." |

### API Call
`POST /auth/contact/verify` with:
```json
{
  "request_id": "...",
  "otp_old": "123456",
  "otp_new": "654321"
}
```

### Success
- Returns new `access_token` and `refresh_token`
- Update stored tokens
- Show toast: "Contact updated. Other sessions have been logged out."
- Navigate to **U-12 Profile View**

### Error Handling
| Error Code | Action |
|------------|--------|
| `OTP_INVALID` | "One or both OTPs are incorrect." Clear both fields. |
| `OTP_EXPIRED` | "OTPs expired. Resend to start again." |

---

## U-16 · Delete Account Screen
**Priority:** P2 | **Auth Required:** Yes | **API:** EP-13

### Purpose
User permanently deletes their account (DPDP compliance).
Account is soft-deleted and PII is anonymised.

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Delete Account" |
| Warning banner | Red banner: "This action cannot be undone." |
| What happens section | Bullet list: "• Your name and contact info will be anonymised" · "• Your order history is retained for tax compliance" · "• You will be logged out of all devices" |
| OTP section | "Confirm your identity" — "Send OTP to +91XXXXXXXXXX" button |
| OTP Input | 6 digit boxes (visible after OTP is sent) |
| Reason field | Optional multiline text: "Why are you leaving? (optional)" |
| "Permanently Delete My Account" | Destructive red button, requires OTP to be filled |
| Cancel link | → back to Profile |

### Flow
1. User taps "Send OTP" → backend sends OTP to their phone (use EP-09 logic or a dedicated send)
2. User enters OTP
3. `DELETE /auth/account` with `{ "otp": "123456", "reason": "..." }`
4. On success → clear all tokens → show farewell screen → Navigate to **U-02**

### Confirmation Dialog
Before final API call: "Are you absolutely sure? Type DELETE to confirm." (text confirmation input)

---

## U-17 · Upgrade to Employee Screen
**Priority:** P1 | **Auth Required:** Yes (GUEST role only) | **API:** EP-14

### Purpose
A guest user who now has a company employee ID can link their account to their company
to unlock subsidies and meal benefits — without losing order history.

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Upgrade to Employee Account" |
| Current status | "You are currently a Guest" pill |
| Benefits section | Card showing: "✓ Company meal subsidy" · "✓ Wallet top-ups from HR" · "✓ Priority support" |
| Employee ID field | Text input, required |
| Work Email field | Email input — "Must match your HR records" |
| OTP section | "Confirm your phone" — "Send OTP" button + 6-digit input |
| "Upgrade My Account" button | Primary, disabled until all fields + OTP filled |
| Info note | "All active sessions will be logged out after upgrade." |

### API Call
`POST /auth/upgrade-to-employee` with:
```json
{
  "employee_id": "EMP001",
  "work_email": "john@company.com",
  "otp": "123456"
}
```

### Success
- Returns new `access_token`, `refresh_token`, user now has `role: "USER"`, `tenant_id`, `is_employee: true`
- Update stored tokens
- Show celebration screen: "Welcome to [Company]! Your subsidies are now active."
- Navigate to **U-11 Home/Dashboard**

### Error Handling
| Error Code | Action |
|------------|--------|
| `EMPLOYEE_ID_NOT_FOUND` | Below Employee ID: "Employee ID not found in your company records." |
| `ALREADY_EMPLOYEE` | Show: "Your account is already linked to a company." |
| `VALIDATION_ERROR` | "Work email does not match the email on file for this Employee ID." |
| `OTP_INVALID` | "Incorrect OTP." |

---

# ═══════════════════════════════════════
# PART 2 — VENDOR APP (5 Screens)
# ═══════════════════════════════════════

The Vendor App is for food vendors/kitchen operators.
Vendors are created by Admin (never self-register).
Role: `VENDOR`

---

## V-01 · Splash Screen
**Priority:** P0 | **Auth Required:** No

### UI Elements
- Bhojan Vendor logo
- "Vendor Portal" subtitle
- Full screen background

### Logic on Mount
1. Check secure storage for vendor `access_token`
2. If valid → `GET /auth/me` (reuse same endpoint)
   - Success → **V-04 Vendor Dashboard**
   - 401 → try refresh → if fails → **V-02 Vendor Login**
3. If no token → **V-02 Vendor Login**

---

## V-02 · Vendor Account Activation Screen
**Priority:** P0 | **Auth Required:** No | **API:** EP-17

### Purpose
First-time screen for a vendor who received the activation email.
They open the link from email: `http://localhost:3000/vendor/auth/activate?activation_token=<uuid>`
The app intercepts this deep link and shows this screen.

### Deep Link Handling
- URL scheme: `bhojan-vendor://activate?activation_token=<uuid>`
- OR the app opens the web URL and handles the `activation_token` param from the URL

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Activate Your Vendor Account" |
| Welcome message | "Welcome! Set a password to activate your Bhojan Vendor account." |
| Activation token display | Hidden (used in API call, not shown to user) |
| Password field | Min 8 chars, 1 upper, 1 number, 1 special |
| Confirm Password field | Must match |
| Password strength bar | Weak / Medium / Strong |
| "Activate Account" button | Primary, disabled until passwords match |
| Note | "This activation link is valid for 24 hours." |

### API Call
`POST /vendor/auth/activate` with:
```json
{
  "activation_token": "<uuid from URL>",
  "password": "Vendor@Pass1"
}
```

### Success
- Show toast: "Account activated! Please log in."
- Navigate to **V-03 Vendor Login**

### Error Handling
| Error Code | Action |
|------------|--------|
| `UNAUTHORIZED` | Full screen error: "This activation link is invalid or has expired. Please contact your administrator." |
| `VALIDATION_ERROR` | Show password strength error below field |

---

## V-03 · Vendor Login Screen
**Priority:** P0 | **Auth Required:** No | **API:** EP-18

### Purpose
Vendor logs in with their registered phone number and password.

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Vendor Login" |
| Logo | Bhojan Vendor logo |
| Phone Number field | `+91XXXXXXXXXX` format |
| Password field | With show/hide toggle |
| "Login" button | Primary |
| "Activate Account" link | → **V-02** (for vendors who haven't activated yet) |

### API Call
`POST /vendor/auth/login` with:
```json
{ "phone": "+91XXXXXXXXXX", "password": "..." }
```

### Success → Store tokens → Navigate to **V-04 Vendor Dashboard**

### Error Handling
| Error Code | Action |
|------------|--------|
| `USER_NOT_FOUND` | "No vendor account found with this phone number." |
| `EMAIL_NOT_VERIFIED` | "Your account has not been activated yet. Check your email for the activation link." |
| `ACCOUNT_SUSPENDED` | Modal: "Your account has been suspended. Contact your Bhojan administrator." |
| `AUTH_LOGIN_FAILED` | "Incorrect password." |
| `ACCOUNT_LOCKED` | "Too many attempts. Try again in 15 minutes." |

---

## V-04 · Vendor Dashboard
**Priority:** P0 | **Auth Required:** Yes (VENDOR Bearer)

### Purpose
Main landing screen after vendor login.
Shows today's orders, kitchen status, quick actions.
(Order management is Phase 2+ — show a placeholder for now)

### UI Elements
| Element | Detail |
|---------|--------|
| Header | "Good morning, [Business Name]" + avatar |
| Status indicator | Kitchen "Open" / "Closed" toggle (Phase 2) |
| Today's orders count | Placeholder "0 orders today" |
| Quick actions | View Profile, Update Menu (Phase 2+) |
| Bottom nav | Dashboard · Orders · Menu · Profile |

### Navigation
- Profile tab → **V-05 Vendor Profile**

---

## V-05 · Vendor Profile Screen
**Priority:** P1 | **Auth Required:** Yes (VENDOR Bearer) | **API:** EP-19

### Purpose
Vendor views and edits their business profile.

### API Call on Load
`GET /auth/me` → get basic user info + `GET /vendor/auth/profile` if such endpoint exists
(For now use the data stored after login)

### UI Elements — View Mode
| Element | Detail |
|---------|--------|
| Business logo | Circular 80×80, tap to edit |
| Business Name | Large text |
| Business Address | With map pin icon |
| City | — |
| FSSAI Number | With a label "FSSAI License:" |
| Phone | — |
| "Edit Profile" button | → switches to Edit Mode |
| Logout button | With confirm dialog |

### UI Elements — Edit Mode (PUT /vendor/auth/profile)
| Field | Type | Max Length | Validation |
|-------|------|------------|------------|
| Business Name | Text input | 120 chars | Optional |
| Business Address | Text input | 250 chars | Optional |
| City | Text input | 100 chars | Optional |
| Logo URL | URL input | — | Must be valid URL |
| FSSAI Number | Text input | 40 chars | Optional |

> Note: `state` and `pincode` are NOT editable via the vendor app (not in the update DTO).
> Bank account details require admin approval (Phase 2).

### API Call on Save
`PUT /vendor/auth/profile` with only changed fields

### Success → Show toast "Profile updated" → Switch back to View Mode

---

# ═══════════════════════════════════════
# PART 3 — ADMIN APP (12 Screens)
# ═══════════════════════════════════════

The Admin App is for internal Bhojan operations team.
Roles: `SUPER_ADMIN` · `OPS_ADMIN` · `TECH_ADMIN`
Login is always email + OTP (never password).

---

## A-01 · Admin Login — Email Screen
**Priority:** P0 | **Auth Required:** No | **API:** EP-20 (Step 1)

### Purpose
Admin enters their registered email to receive a one-time login OTP.

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Admin Portal" |
| Bhojan admin logo | — |
| Email input | Standard email keyboard, e.g. "admin@bhojan.com" |
| "Send OTP" button | Primary |
| Security note | "Admin accounts use OTP-only login for security." |

### API Call
`POST /admin/auth/login` with `{ "email": "admin@bhojan.com" }`

### Success Response
`{ "success": true }` — OTP sent to email
→ Navigate to **A-02 Admin Login OTP Screen**

### Error Handling
| Error Code | Action |
|------------|--------|
| `USER_NOT_FOUND` | "No admin account found with this email." |
| `ACCOUNT_DEACTIVATED` | "This admin account is deactivated." |

---

## A-02 · Admin Login — OTP Screen
**Priority:** P0 | **Auth Required:** No | **API:** EP-20 (Step 2)

### Purpose
Admin enters the OTP they received in their email inbox.

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Enter OTP" |
| Subtitle | "We sent a 6-digit OTP to [admin@email.com]" (show masked email) |
| OTP Input | 6 digit boxes |
| Countdown timer | 5 minutes |
| "Resend OTP" | Re-calls EP-20 step 1 |
| "Change Email" link | Back to **A-01** |

### API Call
`POST /admin/auth/login` with:
```json
{ "email": "admin@bhojan.com", "otp": "123456" }
```

### Success
- Store `access_token`, `refresh_token`, `role`, `user.id`
- After login fetch permissions → `GET /admin/auth/permissions` (EP-21)
- Store permissions in app state (used to show/hide menu items)
- Navigate to **A-03 Admin Dashboard**

### Error Handling
| Error Code | Action |
|------------|--------|
| `OTP_INVALID` | "Incorrect OTP." Clear input. |
| `OTP_EXPIRED` | "OTP expired. Click Resend." Enable resend button. |

---

## A-03 · Admin Dashboard
**Priority:** P0 | **Auth Required:** Yes (Admin Bearer)

### Purpose
Central hub after admin login. Shows stats and navigation to all modules.

### UI Elements
| Element | Detail |
|---------|--------|
| Header | "Welcome, [Admin Name]" + role badge (SUPER_ADMIN / OPS_ADMIN / TECH_ADMIN) |
| Stats cards (placeholder) | Total vendors · Active sessions · Audit events today |
| Module tiles / navigation | Audit Logs · Vendor Management · Employee Management · Delegations · Sessions |
| Side drawer / bottom nav | Navigation to all admin screens |
| Logout button | In header/drawer |

### Permissions-based visibility
After loading permissions from EP-21, show/hide tiles based on `can_read` for each module:
- `module: "VENDOR"` `can_read: true` → show Vendor Management tile
- `module: "SESSION"` `can_read: true` → show Sessions tile
- etc.

---

## A-04 · My Permissions Screen
**Priority:** P0 | **Auth Required:** Yes | **API:** EP-21

### Purpose
Admin views their own RBAC permissions and any active delegations.
Useful to understand what they can and cannot do.

### API Call on Load
`GET /admin/auth/permissions`

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "My Permissions" |
| Role banner | "Your role: OPS_ADMIN" |
| Permissions table | Module · Can Create · Can Read · Can Update · Can Delete (✓ / ✗ icons) |
| Active Delegations section | Shows delegations granted to this admin: Module · Expires At |
| Empty state for delegations | "No active delegations" |

### Permissions Table Rows
One row per module returned. Modules: AUTH · VENDOR · ORDER · MENU · REPORT · SETTINGS · EMPLOYEE · DELEGATION · TENANT · SESSION · FINANCE

---

## A-05 · Audit Logs Screen
**Priority:** P0 | **Auth Required:** Yes | **API:** EP-22, EP-23

### Purpose
Browse, filter, and export the system audit log. SUPER_ADMIN and TECH_ADMIN see all tenants.
OPS_ADMIN sees their own tenant only.

### UI Elements — Filter Bar
| Filter | Input Type | Values |
|--------|-----------|--------|
| Date range | Date picker (from/to) | ISO8601 |
| Action | Dropdown | USER_LOGIN, VENDOR_SUSPENDED, BULK_EMPLOYEE_UPLOAD, etc. |
| Module | Dropdown | AUTH, VENDOR, EMPLOYEE, etc. |
| User ID | Text input | UUID of the actor |
| Tenant | Dropdown | Only for SUPER_ADMIN / TECH_ADMIN |

### UI Elements — Log List
| Element | Detail |
|---------|--------|
| Each log row | Timestamp · Action badge (color coded) · Module · Actor name/id · Target ID (if any) |
| Tap to expand row | Shows full metadata JSON |
| Pagination | "Page X of Y" with prev/next |
| "Export CSV" button | Triggers async export flow (see below) |

### API Call on Load / Filter Change
`GET /admin/audit-logs?page=1&limit=50&action=...&from_date=...`

### Export CSV Flow (EP-23)
1. Tap "Export CSV"
2. Call `GET /admin/audit-logs/export` → receive `job_id`
3. Show progress modal: "Generating export... This may take a moment."
4. Poll `GET /admin/audit-logs/export?job_id=<id>` every 2 seconds
5. On `status: "COMPLETED"` → show "Download Ready" button with `download_url`
6. Tap download → open URL in browser / trigger download
7. On `status: "FAILED"` → show error toast

---

## A-06 · Employee Management Screen
**Priority:** P0 | **Auth Required:** Yes (OPS_ADMIN or SUPER_ADMIN) | **API:** EP-24, EP-25, EP-26

### Purpose
Upload employees in bulk via CSV and offboard individual employees.

### Sub-screens / Tabs

#### Tab 1: Bulk Upload (EP-24, EP-25)
| Element | Detail |
|---------|--------|
| Screen title | "Bulk Employee Upload" |
| Info note | "Upload a CSV file with columns: employee_id, email, full_name, department" |
| CSV template download | "Download Template" button |
| SUPER_ADMIN only | Tenant selector dropdown (OPS_ADMIN uses own tenant automatically) |
| File picker button | "Choose CSV File" — accepts `.csv` only, max 10 MB |
| Selected file display | Shows filename and size after selection |
| "Upload" button | Disabled until file selected |
| Upload status | Inline progress bar after upload |

**CSV Column Format:**
```
employee_id,email,full_name,department
EMP001,john@infosys.com,John Doe,Engineering
EMP002,jane@infosys.com,Jane Smith,Finance
```

**Upload API Call:** `POST /admin/employees/bulk-upload` as `multipart/form-data`
- Field: `file` (CSV file)
- Field: `tenant_id` (SUPER_ADMIN only)

**Poll Status (EP-25):** After upload accepted (202) → poll `GET /admin/employees/bulk-upload/:upload_id` every 2 seconds

**Status Display Card:**
| Field | Display |
|-------|---------|
| status | PENDING / PROCESSING / COMPLETED / FAILED (with color) |
| total_records | Total rows in CSV |
| success_count | Green: "X added/updated" |
| failed_count | Red: "X failed" |
| error_details | Expandable list: row number + reason |

#### Tab 2: Offboard Employee (EP-26)
| Element | Detail |
|---------|--------|
| Search field | "Search by name, Employee ID, or email" |
| Employee list | Name · Employee ID · Department · Tenant |
| Tap employee | Opens offboard confirmation bottom sheet |
| Offboard sheet | Employee name · Reason input (required) · "Confirm Offboard" red button |

**API Call:** `POST /admin/employees/:id/offboard` with `{ "reason": "..." }`

**Success:** Toast "Employee offboarded. All sessions revoked." Refresh list.

**Error Handling:**
| Error Code | Action |
|------------|--------|
| `TENANT_MISMATCH` | "You can only offboard employees in your own tenant." |
| `USER_NOT_FOUND` | "Employee not found." |

---

## A-07 · Vendor Management — List Screen
**Priority:** P0 | **Auth Required:** Yes | **API:** EP-27, EP-28, EP-29

### Purpose
Browse all vendors, create new vendors, and manage suspension.

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Vendor Management" |
| Search bar | Search by business name, phone, email |
| Filter tabs | All · Active · Suspended |
| "Add Vendor" button | Top right → **A-08 Create Vendor** |
| Vendor card | Business name · City · Status badge (Active/Suspended) · Phone |
| Tap vendor card | → **A-09 Vendor Detail Screen** |

---

## A-08 · Create Vendor Screen
**Priority:** P0 | **Auth Required:** Yes (OPS_ADMIN or SUPER_ADMIN) | **API:** EP-27

### Purpose
Admin creates a new vendor account. Activation email is sent automatically.

### UI Elements
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| Contact Person Name | Text | Yes | Full name |
| Phone Number | Phone | Yes | `+91XXXXXXXXXX` |
| Business Email | Email | Yes | Used for activation email |
| Business Name | Text | Yes | Outlet / kitchen name |
| Business Address | Text | Yes | Full address |
| City | Text | Yes | — |
| State | Text | Yes | e.g. "Karnataka" |
| Pincode | Text | Yes | 6 digits |
| GSTIN | Text | No | GST number |
| Tenant | Dropdown | Yes | Select from active tenants (SUPER_ADMIN) or pre-filled (OPS_ADMIN) |

| Element | Detail |
|---------|--------|
| Screen title | "Add New Vendor" |
| Info note | "An activation email will be sent to the vendor's email address." |
| "Create Vendor" button | Primary |

### API Call
`POST /admin/vendors` with all fields

### Success
Show: "Vendor account created. Activation email sent to [email]."
Navigate back to **A-07 Vendor List**

### Error Handling
| Error Code | Action |
|------------|--------|
| `USER_ALREADY_EXISTS` | "This phone or email is already registered." |

---

## A-09 · Vendor Detail Screen
**Priority:** P0 | **Auth Required:** Yes | **API:** EP-28, EP-29

### Purpose
View vendor details and manage their suspension status.

### UI Elements — View Mode
| Element | Detail |
|---------|--------|
| Business Name | Large heading |
| Status badge | "Active" (green) or "Suspended" (red) |
| Phone | — |
| Email | — |
| City, State | — |
| GSTIN | — |
| Tenant | — |
| Suspension history | List of past suspensions with reason + date + actioned by (Phase 2) |

### Action Buttons (conditional)
| Condition | Button Shown |
|-----------|-------------|
| Vendor is Active | "Suspend Vendor" (red outline button) |
| Vendor is Suspended | "Reactivate Vendor" (green outline button) |

### Suspend Vendor Flow (EP-28)
1. Tap "Suspend Vendor"
2. Bottom sheet appears: "Suspend [Business Name]?"
3. Reason input (required): "Enter reason for suspension"
4. "Confirm Suspend" red button
5. Call `POST /admin/vendors/:id/suspend` with `{ "reason": "..." }`
6. Success → badge updates to "Suspended" · Toast: "Vendor suspended."

### Reactivate Vendor Flow (EP-29)
1. Tap "Reactivate Vendor"
2. Bottom sheet: "Reactivate [Business Name]?"
3. Reason input (required)
4. "Confirm Reactivate" green button
5. Call `POST /admin/vendors/:id/reactivate` with `{ "reason": "..." }`
6. Success → badge updates to "Active" · Toast: "Vendor reactivated."

---

## A-10 · Delegation Management Screen
**Priority:** P1 | **Auth Required:** Yes (SUPER_ADMIN only) | **API:** EP-30, EP-31, EP-32

### Purpose
SUPER_ADMIN grants other admins temporary access to specific modules.

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Delegations" |
| Filter tabs | Active · All |
| "Create Delegation" button | FAB or top right → create form |
| Delegation card | Delegatee name · Module · Expires at · Status badge (Active/Expired) |
| Tap card | Show Revoke option if active |

### Create Delegation Form
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Delegatee | Admin search / dropdown | Yes | Searches active admins |
| Module | Dropdown | Yes | AUTH · VENDOR · ORDER · MENU · REPORT · SETTINGS · EMPLOYEE · DELEGATION · TENANT · SESSION · FINANCE |
| Expires At | Date-time picker | Yes | Must be in the future |
| Starts At | Date-time picker | No | Defaults to now |
| Reason | Text area | No | Why delegating |

### API Call — Create
`POST /admin/delegations` with:
```json
{
  "delegatee_id": "uuid",
  "module": "VENDOR",
  "expires_at": "2026-06-30T00:00:00.000Z",
  "reason": "Out of office coverage"
}
```

### API Call — List
`GET /admin/delegations` (optionally filter by `?is_active=true`)

### Revoke Delegation
- Tap active delegation → confirm dialog "Revoke this delegation?"
- `DELETE /admin/delegations/:id`
- Toast: "Delegation revoked."

### Error Handling
| Error Code | Action |
|------------|--------|
| `USER_NOT_FOUND` | "Delegatee admin not found." |
| `VALIDATION_ERROR` | "Expiry date must be in the future." |

---

## A-11 · Session Management Screen
**Priority:** P1 | **Auth Required:** Yes (SUPER_ADMIN or TECH_ADMIN) | **API:** EP-33, EP-34

### Purpose
Monitor active user sessions across the platform. Force-revoke suspicious sessions.

### UI Elements
| Element | Detail |
|---------|--------|
| Screen title | "Active Sessions" |
| Filter: User ID | Optional UUID input to filter by specific user |
| Filter: is_active toggle | Show active / all |
| Session card | User email (or ID) · Device · IP address · Created at · Expires at · Status (Active/Revoked) |
| "Revoke" button | On each active session card |

### API Call on Load
`GET /admin/sessions` (optionally with `?user_id=&is_active=true`)

### Revoke Session
- Tap "Revoke" on a session
- Confirm dialog: "Force logout this session?"
- `DELETE /admin/sessions/:id`
- Session card updates to show "Revoked"
- Toast: "Session revoked. User will be logged out on their device."

---

## A-12 · Admin Profile / Settings Screen
**Priority:** P1 | **Auth Required:** Yes

### Purpose
Admin views their own profile and can log out.

### UI Elements
| Element | Detail |
|---------|--------|
| Name | — |
| Email | — |
| Role badge | SUPER_ADMIN / OPS_ADMIN / TECH_ADMIN |
| Tenant | (if applicable) |
| "My Permissions" link | → **A-04** |
| Logout button | `POST /auth/logout` (EP-05) with Bearer token |

---

# ═══════════════════════════════════════
# APPENDIX A — Navigation Map
# ═══════════════════════════════════════

## User App Navigation Flow
```
Splash (U-01)
  └─ First launch → Tenant Selection (U-02)
       └─ Tap tenant → Welcome/Auth Choice (U-03)
            ├─ Register → Type Choice (U-06)
            │    ├─ Guest → GUEST Registration (U-04) → OTP Verify (U-07) → Home (U-11)
            │    └─ Employee → EMPLOYEE Registration (U-05) → OTP Verify (U-07) → Home (U-11)
            ├─ Login with Password → Password Login (U-08) → Home (U-11)
            └─ Forgot Password → Phone Screen (U-09) → Reset Screen (U-10) → Login (U-08)

Home (U-11)
  └─ Profile tab → Profile View (U-12)
       ├─ Edit → Edit Profile (U-13)
       ├─ Change Contact → Contact Init (U-14) → Contact Verify (U-15)
       ├─ Delete Account → Delete Screen (U-16)
       └─ Upgrade (GUEST only) → Upgrade Screen (U-17) → Home (U-11) [now USER]
```

## Vendor App Navigation Flow
```
Splash (V-01)
  ├─ Returning vendor → Dashboard (V-04)
  └─ New/logged out → Login (V-03)
       └─ First time → Activation (V-02) → Login (V-03) → Dashboard (V-04)

Dashboard (V-04)
  └─ Profile → Vendor Profile (V-05)
```

## Admin App Navigation Flow
```
Login Email (A-01) → Login OTP (A-02) → Dashboard (A-03)
  ├─ Audit Logs (A-05)
  ├─ Employee Management (A-06)
  ├─ Vendor List (A-07) → Create Vendor (A-08) / Vendor Detail (A-09)
  ├─ Delegations (A-10)     [SUPER_ADMIN only]
  ├─ Sessions (A-11)        [SUPER_ADMIN, TECH_ADMIN only]
  ├─ My Permissions (A-04)
  └─ Profile/Settings (A-12)
```

---

# ═══════════════════════════════════════
# APPENDIX B — API to Screen Mapping
# ═══════════════════════════════════════

| EP# | Endpoint | Screen(s) |
|-----|----------|-----------|
| EP-01 | POST /auth/register | U-04, U-05 |
| EP-02 | POST /auth/otp/verify | U-07 |
| EP-03 | POST /auth/login/password | U-08 |
| EP-04 | POST /auth/token/refresh | All protected screens (silent) |
| EP-05 | POST /auth/logout | U-12, A-12, V-05 |
| EP-06 | GET /auth/me | U-12, U-01 (splash check) |
| EP-07 | PUT /auth/profile | U-13 |
| EP-08 | POST /auth/profile/avatar | U-13 (avatar section) |
| EP-09 | POST /auth/password/reset-request | U-09 |
| EP-10 | POST /auth/password/reset-verify | U-10 |
| EP-11 | POST /auth/contact/change | U-14 |
| EP-12 | POST /auth/contact/verify | U-15 |
| EP-13 | DELETE /auth/account | U-16 |
| EP-14 | POST /auth/upgrade-to-employee | U-17 |
| EP-15 | GET /auth/sso/google | U-03, U-08 (Google button) |
| EP-16 | GET /auth/sso/google/callback | Browser/WebView callback |
| EP-17 | POST /vendor/auth/activate | V-02 |
| EP-18 | POST /vendor/auth/login | V-03 |
| EP-19 | PUT /vendor/auth/profile | V-05 |
| EP-20 | POST /admin/auth/login | A-01, A-02 |
| EP-21 | GET /admin/auth/permissions | A-04, A-03 (on login) |
| EP-22 | GET /admin/audit-logs | A-05 |
| EP-23 | GET /admin/audit-logs/export | A-05 (export button) |
| EP-24 | POST /admin/employees/bulk-upload | A-06 (Tab 1) |
| EP-25 | GET /admin/employees/bulk-upload/:id | A-06 (Tab 1, poll) |
| EP-26 | POST /admin/employees/:id/offboard | A-06 (Tab 2) |
| EP-27 | POST /admin/vendors | A-08 |
| EP-28 | POST /admin/vendors/:id/suspend | A-09 |
| EP-29 | POST /admin/vendors/:id/reactivate | A-09 |
| EP-30 | POST /admin/delegations | A-10 |
| EP-31 | GET /admin/delegations | A-10 |
| EP-32 | DELETE /admin/delegations/:id | A-10 |
| EP-33 | GET /admin/sessions | A-11 |
| EP-34 | DELETE /admin/sessions/:id | A-11 |
| EP-35 | GET /tenants | U-02 |
| EP-36 | GET /tenants/:id/settings | U-02 (on tenant tap) |
| EP-37 | POST /tenants/validate | U-02 (on tenant tap) |

---

# ═══════════════════════════════════════
# APPENDIX C — Screen Checklist
# ═══════════════════════════════════════

Use this to track frontend build progress.

## User App
- [ ] U-01 Splash Screen
- [ ] U-02 Tenant Selection
- [ ] U-03 Welcome / Auth Choice
- [ ] U-04 GUEST Registration
- [ ] U-05 EMPLOYEE Registration
- [ ] U-06 Registration Type Choice (bottom sheet)
- [ ] U-07 OTP Verification
- [ ] U-08 Password Login
- [ ] U-09 Forgot Password — Phone
- [ ] U-10 Forgot Password — Reset
- [ ] U-11 Home / Dashboard
- [ ] U-12 Profile View
- [ ] U-13 Edit Profile
- [ ] U-14 Contact Change Init
- [ ] U-15 Contact Change Verify
- [ ] U-16 Delete Account
- [ ] U-17 Upgrade to Employee

## Vendor App
- [ ] V-01 Splash Screen
- [ ] V-02 Vendor Account Activation
- [ ] V-03 Vendor Login
- [ ] V-04 Vendor Dashboard
- [ ] V-05 Vendor Profile

## Admin App
- [ ] A-01 Admin Login — Email
- [ ] A-02 Admin Login — OTP
- [ ] A-03 Admin Dashboard
- [ ] A-04 My Permissions
- [ ] A-05 Audit Logs (+ Export)
- [ ] A-06 Employee Management (Bulk Upload + Offboard)
- [ ] A-07 Vendor List
- [ ] A-08 Create Vendor
- [ ] A-09 Vendor Detail (Suspend / Reactivate)
- [ ] A-10 Delegation Management
- [ ] A-11 Session Management
- [ ] A-12 Admin Profile / Settings
