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
    // Show splash animation for at least 1.5 seconds
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Check for updates automatically in the background ONLY on Windows desktop
    if (!kIsWeb && Platform.isWindows) {
      try {
        final updateInfo = await WindowsAutoUpdater.checkForUpdate();
        if (updateInfo != null && mounted) {
          // Show update dialog directly
          await WindowsAutoUpdater.showUpdateDialog(context, updateInfo);
        }
      } catch (e) {
        debugPrint('Update check during splash failed or skipped: $e');
      }
    }

    if (mounted) {
      context.go('/dashboard');
    }
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
