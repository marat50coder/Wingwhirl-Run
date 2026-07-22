import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class WingwhirlApp extends StatelessWidget {
  const WingwhirlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wingwhirl Run',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashScreen(),
    );
  }
}

/// Fade + slide page transition (300-500ms, easeInOut) used across the app.
Route<T> fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Shared full-screen sky gradient background used behind menus.
class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key, required this.child, this.bgAsset});
  final Widget child;
  final String? bgAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.skyGradient),
      child: bgAsset == null
          ? child
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(bgAsset!, fit: BoxFit.cover),
                Container(color: Colors.black.withValues(alpha: 0.12)),
                child,
              ],
            ),
    );
  }
}
