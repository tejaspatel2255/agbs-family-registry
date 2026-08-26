import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import '../../features/auth/screens/admin_login_screen.dart';
import '../../features/auth/screens/member_login_screen.dart';
import '../../features/auth/screens/member_signup_screen.dart';
import '../../features/dashboard/admin_dashboard_screen.dart';
import '../../features/dashboard/member_dashboard_screen.dart';
import '../../features/family/screens/family_form_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/admin-login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/member-login',
      builder: (context, state) => const MemberLoginScreen(),
    ),
    GoRoute(
      path: '/member-signup',
      builder: (context, state) => const MemberSignUpScreen(),
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/member-dashboard',
      builder: (context, state) => const MemberDashboardScreen(),
    ),
    GoRoute(
      path: '/register-family',
      builder: (context, state) => const MemberDashboardScreen(),
    ),
    GoRoute(
      path: '/family-form',
      builder: (context, state) {
        final id = state.uri.queryParameters['id'];
        return FamilyFormScreen(familyId: id);
      },
    ),
  ],
);
