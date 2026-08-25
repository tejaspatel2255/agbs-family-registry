import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/welcome/welcome_screen.dart';

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
      path: '/login',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Login Screen (Phase 3)')),
      ),
    ),
    GoRoute(
      path: '/register-family',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Family Registration Screen (Phase 4)')),
      ),
    ),
  ],
);
