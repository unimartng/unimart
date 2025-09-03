import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unimart/constants/app_colors.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Start animation
    _controller.forward();

    // Navigate after delay
    _navigationTimer = Timer(const Duration(milliseconds: 2000), () {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    try {
      context.go('/');
    } catch (e) {
      try {
        Navigator.of(context).pushReplacementNamed('/');
      } catch (e2) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                const Scaffold(body: Center(child: Text('Home Screen'))),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo container with theme-aware colors
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : AppColors.primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.white : AppColors.primaryBlue).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.shopping_bag_outlined,
                      size: 40,
                      color: isDark ? AppColors.primaryBlue : Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App name with theme-aware color
              Text(
                'Unimart',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline with theme-aware color
              Text(
                'Your Campus Marketplace',
                style: TextStyle(
                  color: theme.colorScheme.primary.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
