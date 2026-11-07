import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../themes/app_colors.dart';
import '../../services/windows_auto_updater.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. On Windows desktop, check for updates first before navigating
    if (!kIsWeb && Platform.isWindows) {
      try {
        final updateInfo = await WindowsAutoUpdater.checkForUpdate();
        if (updateInfo != null && mounted) {
          // Show the update popup immediately on top of the splash screen
          await WindowsAutoUpdater.showUpdateDialog(context, updateInfo);
        }
      } catch (e) {
        debugPrint('[SplashScreen] Auto update check failed: $e');
      }
    }

    // 2. Minimum splash delay for smooth branding experience
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // 3. Navigate to Dashboard once up to date
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                isDarkMode ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
                height: 150,
                cacheHeight: 450, // Added to prevent excessive memory usage
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 60),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3.5,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
