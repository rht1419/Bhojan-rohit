import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/onboarding_carousel_screen.dart';
import '../features/auth/screens/sign_up_type_screen.dart';
import '../features/auth/screens/guest_register_screen.dart';
import '../features/auth/screens/employee_register_screen.dart';
import '../features/auth/screens/tenant_selection_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/login_password_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/forgot_password_screen.dart';
import '../features/profile/screens/change_contact_screen.dart';
import '../features/profile/screens/upgrade_to_employee_screen.dart';
import '../features/profile/screens/delete_account_screen.dart';
import '../features/home/screens/home_screen.dart';

// ── Vendor App Imports ──────────────────────────────────────────────
import '../vendor_app/auth/screens/vendor_welcome_screen.dart';
import '../vendor_app/auth/screens/vendor_register_screen.dart';
import '../vendor_app/auth/screens/vendor_verify_phone_screen.dart';
import '../vendor_app/auth/screens/vendor_registration_status_screen.dart';
import '../vendor_app/auth/screens/vendor_activate_screen.dart';
import '../vendor_app/auth/screens/vendor_login_screen.dart';
import '../vendor_app/auth/screens/vendor_pending_screen.dart';
import '../vendor_app/auth/screens/vendor_loading_screen.dart';
import '../vendor_app/auth/screens/vendor_session_expired_screen.dart';
import '../vendor_app/profile/screens/vendor_profile_screen.dart';
import '../vendor_app/dashboard/screens/vendor_dashboard_screen.dart';
import '../vendor_app/dashboard/screens/vendor_access_denied_screen.dart';
import '../vendor_app/shared/widgets/vendor_shell_screen.dart';

// ── Admin App Imports ───────────────────────────────────────────────
import '../admin_app/auth/screens/admin_login_screen.dart';
import '../admin_app/auth/screens/admin_verify_otp_screen.dart';
import '../admin_app/auth/screens/admin_role_selection_screen.dart';
import '../admin_app/auth/screens/admin_sso_loading_screen.dart';
import '../admin_app/auth/screens/admin_sso_error_screen.dart';
import '../admin_app/dashboard/screens/admin_shell_screen.dart';
import '../admin_app/dashboard/screens/admin_dashboard_screen.dart';
import '../admin_app/tenants/screens/admin_tenant_switch_screen.dart';
import '../admin_app/tenants/screens/admin_analytics_screen.dart';
import '../admin_app/vendors/screens/admin_vendor_list_screen.dart';
import '../admin_app/employees/screens/admin_bulk_upload_screen.dart';
import '../admin_app/delegation/screens/admin_delegation_screen.dart';
import '../admin_app/audit/screens/admin_audit_logs_screen.dart';
import '../admin_app/sessions/screens/admin_active_sessions_screen.dart';
import '../admin_app/sessions/screens/admin_session_expired_screen.dart';
import '../admin_app/permissions/screens/admin_permission_matrix_screen.dart';
import '../admin_app/vendors/screens/admin_create_vendor_screen.dart';
import '../admin_app/vendors/screens/admin_vendor_detail_screen.dart';
import '../admin_app/employees/screens/admin_employee_offboard_screen.dart';
import '../admin_app/profile/screens/admin_profile_screen.dart';

/// Routes that unauthenticated users are allowed to visit.
const _publicPrefixes = [
  '/welcome', '/carousel', '/login', '/register', '/tenant-select',
  '/sign-up-type', '/verify-otp', '/forgot-password',
  // Vendor public routes
  '/vendor/welcome', '/vendor/register', '/vendor/verify-phone', 
  '/vendor/registration-status', '/vendor/activate', '/vendor/login', 
  '/vendor/pending', '/vendor/session-expired', '/vendor/access-denied',
  // Admin public routes
  '/admin/login', '/admin/verify-otp', '/admin/sso-loading', '/admin/sso-error', '/admin/session-expired',
];

bool _isPublicRoute(String location) {
  return _publicPrefixes.any((p) => location.startsWith(p));
}

// ── Router Provider ─────────────────────────────────────────────────

final _authListenableProvider = Provider<ValueNotifier<AuthState>>((ref) {
  final notifier = ValueNotifier<AuthState>(ref.read(authNotifierProvider));
  ref.listen<AuthState>(authNotifierProvider, (_, next) {
    notifier.value = next;
  });
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ref.watch(_authListenableProvider);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);

      // Don't redirect vendor/admin routes through user auth guard
      if (state.matchedLocation.startsWith('/vendor/')) return null;
      if (state.matchedLocation.startsWith('/admin/')) return null;

      // During startup token check, stay on current route (no flash to login)
      if (authState.status == AuthStatus.initial) return null;

      final isAuth = authState.status == AuthStatus.authenticated;
      final isPublic = _isPublicRoute(state.matchedLocation);

      if (isAuth && isPublic) return '/home';
      if (!isAuth && !isPublic) return '/welcome';
      return null;
    },
    routes: [
      // ── Onboarding ────────────────────────────────────────────
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/carousel', builder: (_, __) => const OnboardingCarouselScreen()),

      // ── Registration ──────────────────────────────────────────
      GoRoute(path: '/sign-up-type', builder: (_, __) => const SignUpTypeScreen()),
      GoRoute(path: '/tenant-select', builder: (_, __) => const TenantSelectionScreen()),
      GoRoute(path: '/register/guest', builder: (_, __) => const GuestRegisterScreen()),
      GoRoute(
        path: '/register/employee',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return EmployeeRegisterScreen(
            tenantId: extra['tenantId'] as String? ?? '',
            tenantName: extra['tenantName'] as String? ?? '',
          );
        },
      ),

      // ── OTP ───────────────────────────────────────────────────
      GoRoute(
        path: '/verify-otp',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return OtpScreen(
              phone: extra['phone'] as String? ?? '',
              otpReference: extra['otpReference'] as String?,
              otpContext: extra['context'] as String? ?? 'registration',
            );
          }
          // Fallback for legacy string-only extra
          return OtpScreen(phone: extra as String? ?? '');
        },
      ),

      // ── Login ─────────────────────────────────────────────────
      GoRoute(path: '/login-otp', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/login-password', builder: (_, __) => const LoginPasswordScreen()),

      // ── Password Reset ────────────────────────────────────────
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

      // ── Home (placeholder) ────────────────────────────────────
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),

      // ── Profile ───────────────────────────────────────────────
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/change-contact', builder: (_, __) => const ChangeContactScreen()),
      GoRoute(path: '/upgrade-to-employee', builder: (_, __) => const UpgradeToEmployeeScreen()),
      GoRoute(path: '/delete-account', builder: (_, __) => const DeleteAccountScreen()),

      // ── Vendor App Routes ──────────────────────────────────────
      GoRoute(path: '/vendor/welcome', builder: (_, __) => const VendorWelcomeScreen()),
      GoRoute(path: '/vendor/register', builder: (_, __) => const VendorRegisterScreen()),
      GoRoute(
        path: '/vendor/verify-phone',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return VendorVerifyPhoneScreen(
            phone: extra['phone'] as String? ?? '',
            nextRoute: extra['nextRoute'] as String? ?? '/vendor/dashboard',
          );
        },
      ),
      GoRoute(path: '/vendor/registration-status', builder: (_, __) => const VendorRegistrationStatusScreen()),
      GoRoute(
        path: '/vendor/activate',
        builder: (_, state) {
          final token = state.uri.queryParameters['token'] ??
              state.uri.queryParameters['activation_token'];
          return VendorActivateScreen(activationToken: token);
        },
      ),
      GoRoute(path: '/vendor/login', builder: (_, __) => const VendorLoginScreen()),
      GoRoute(
        path: '/vendor/pending',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VendorPendingScreen(
            reason: extra?['reason'] as String?,
            errorCode: extra?['errorCode'] as String?,
          );
        },
      ),
      GoRoute(path: '/vendor/loading', builder: (_, __) => const VendorLoadingScreen()),
      GoRoute(path: '/vendor/session-expired', builder: (_, __) => const VendorSessionExpiredScreen()),
      GoRoute(path: '/vendor/access-denied', builder: (_, __) => const VendorAccessDeniedScreen()),
      
      ShellRoute(
        builder: (context, state, child) => VendorShellScreen(child: child),
        routes: [
          GoRoute(path: '/vendor/dashboard', builder: (_, __) => const VendorDashboardScreen()),
          GoRoute(path: '/vendor/search', builder: (_, __) => const Scaffold(body: Center(child: Text('Search coming soon')))), // Placeholder
          GoRoute(path: '/vendor/profile', builder: (_, __) => const VendorProfileScreen()),
        ],
      ),
      // ── Admin App Routes ───────────────────────────────────────
      GoRoute(path: '/admin/login', builder: (_, __) => const AdminLoginScreen()),
      GoRoute(path: '/admin/verify-otp', builder: (_, __) => const AdminVerifyOtpScreen()),
      GoRoute(path: '/admin/select-role', builder: (_, __) => const AdminRoleSelectionScreen()),
      GoRoute(path: '/admin/sso-loading', builder: (_, __) => const AdminSsoLoadingScreen()),
      GoRoute(path: '/admin/sso-error', builder: (_, __) => const AdminSsoErrorScreen()),
      GoRoute(path: '/admin/session-expired', builder: (_, __) => const AdminSessionExpiredScreen()),
      
      ShellRoute(
        builder: (context, state, child) => AdminShellScreen(child: child),
        routes: [
          GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(path: '/admin/vendors', builder: (_, __) => const AdminVendorListScreen()),
          GoRoute(path: '/admin/logs', builder: (_, __) => const AdminAuditLogsScreen()),
          GoRoute(path: '/admin/profile', builder: (_, __) => const AdminProfileScreen()),
        ],
      ),
      
      // Admin inner routes (no bottom nav)
      GoRoute(path: '/admin/switch-tenant', builder: (_, __) => const AdminTenantSwitchScreen()),
      GoRoute(path: '/admin/analytics', builder: (_, __) => const AdminAnalyticsScreen()),
      GoRoute(path: '/admin/employees/upload', builder: (_, __) => const AdminBulkUploadScreen()),
      GoRoute(path: '/admin/employees/offboard', builder: (_, __) => const AdminEmployeeOffboardScreen()),
      GoRoute(path: '/admin/delegation', builder: (_, __) => const AdminDelegationScreen()),
      GoRoute(path: '/admin/sessions', builder: (_, __) => const AdminActiveSessionsScreen()),
      GoRoute(path: '/admin/permissions', builder: (_, __) => const AdminPermissionMatrixScreen()),
      GoRoute(path: '/admin/audit', builder: (_, __) => const AdminAuditLogsScreen()),
      GoRoute(path: '/admin/vendors/create', builder: (_, __) => const AdminCreateVendorScreen()),
      GoRoute(
        path: '/admin/vendors/detail',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AdminVendorDetailScreen(
            vendorId: extra['vendorId'] as String? ?? '',
            vendorName: extra['vendorName'] as String?,
          );
        },
      ),
    ],
  );
});
