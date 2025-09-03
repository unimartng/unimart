// ignore_for_file: unused_field, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:unimart/constants/app_colors.dart';
import 'package:unimart/screens/profile/edit_profile_screen.dart';
import 'package:unimart/screens/settings/dark_mode_page.dart';
import 'package:unimart/screens/settings/change_password_screen.dart';
import 'package:unimart/screens/settings/delete_account_screen.dart';
import 'package:unimart/services/location_service.dart';
import 'package:unimart/widgets/location_toggle.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  bool _locationEnabled = false;

  late Animation<double> _fadeAnimation;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _toggleLocation(bool value) async {
    if (value) {
      // User wants to enable location
      final position = await LocationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _locationEnabled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Location enabled: ${position.latitude}, ${position.longitude}",
            ),
          ),
        );
      } else {
        // Permission denied
        setState(() {
          _locationEnabled = false;
        });

        // Check if it's permanently denied
        if (await Permission.location.isPermanentlyDenied) {
          _showSettingsDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Location permission denied."),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      // User turned OFF
      setState(() {
        _locationEnabled = false;
      });
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "Location permission is permanently denied. "
          "Please enable it from app settings to use this feature.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              openAppSettings(); // opens system app settings
              Navigator.pop(context);
            },
            child: const Text("Go to Settings"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: AppColors.primaryBlue,
        elevation: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20),
              child: Text(
                'Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(top: 10, left: 15, right: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildAnimatedTile(
                    icon: Icons.notifications,
                    title: 'Push notification',
                    onTap: () {
                      // Handle push notification settings
                    },
                    index: 0,
                  ),
                  _buildAnimatedTile(
                    icon: Icons.settings_display,
                    title: 'Display',
                    onTap: () {
                      // Handle push notification settings
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DarkModePage(),
                        ),
                      );
                    },
                    index: 0,
                  ),

                  // Add the Switch as a separate widget below the tile if needed
                  LocationToggleWidget(
                    isLocationEnabled: _locationEnabled,
                    onToggle: (value) {
                      if (value != null) {
                        _toggleLocation(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20),
              child: Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(top: 10, left: 15, right: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildAnimatedTile(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    onTap: () {
                      _showPrivacyDialog();
                    },
                    index: 0,
                  ),
                  _buildAnimatedTile(
                    icon: Icons.document_scanner,
                    title: 'Terms of Service',
                    onTap: () {
                      _showTermsDialog();
                    },
                    index: 0,
                  ),
                  _buildAnimatedTile(
                    icon: Icons.info,
                    title: 'About UniMart',
                    onTap: () {
                      _showAboutDialog();
                    },
                    index: 0,
                  ),
                  _buildAnimatedTile(
                    icon: Icons.rate_review_rounded,
                    title: 'Rate Us',
                    onTap: () {
                      // Handle push notification settings
                    },
                    index: 0,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20),
              child: Text(
                'Support',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(top: 10, left: 15, right: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildAnimatedTile(
                    icon: Icons.help_center,
                    title: 'Help center / FAQs',
                    onTap: () {
                      _showFaqsDialog();
                    },
                    index: 0,
                  ),
                  _buildAnimatedTile(
                    icon: Icons.support_agent,
                    title: 'Conact support',
                    onTap: () {
                      // Handle push notification settings
                    },
                    index: 0,
                  ),
                  _buildAnimatedTile(
                    icon: Icons.bug_report,
                    title: 'report a bug',
                    onTap: () {
                      // Handle push notification settings
                    },
                    index: 0,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20),
              child: Text(
                'Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(top: 10, left: 15, right: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildAnimatedTile(
                    icon: Icons.person,
                    title: 'Personal info',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    index: 0,
                  ),
                  _buildAnimatedTile(
                    icon: Icons.delete_forever,
                    iconColor: Colors.red,
                    title: 'Delete Account',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DeleteAccountScreen(),
                        ),
                      );
                    },
                    index: 0,
                  ),
                  _buildAnimatedTile(
                    icon: Icons.lock,
                    title: 'Change Password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                    index: 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Move this function inside the _SettingsScreenState class
  Widget _buildAnimatedTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required int index,
    Color? iconColor,
  }) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: Offset(0, 0.1 * (index + 1)),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _slideController,
                    curve: Interval(
                      0.1 * index,
                      1.0,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                iconColor?.withOpacity(0.1) ??
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color:
                                iconColor ??
                                Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.school, color: AppColors.primaryBlue, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'About UniMart',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unimart is a student-focused marketplace that connects buyers and sellers within university communities.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Buy and sell products/services\n• Chat directly for transactions\n• Discover student businesses',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.description,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Terms & Conditions',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'By using Unimart, you agree to:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Unimart is for students 16+\n'
                '2. You are responsible for your listings\n'
                '3. Transactions are done via chat only\n'
                '4. No illegal or harmful items allowed\n'
                '5. Meet in safe places, Unimart is not liable\n'
                '6. Keep your account safe\n'
                '7. Terms may be updated anytime',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'App Version 1.0.0',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.privacy_tip_rounded,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Privacy Policy',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your privacy matters to us.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. We collect basic details (name, email, listings, messages).\n'
                '2. We use this to connect students and improve the app.\n'
                '3. We don\'t sell your data. Info is only shared for transactions or legal reasons.\n'
                '4. We secure your data but advise caution when sharing personal info.\n'
                '5. You can delete your account or listings anytime.\n'
                '6. Policy may be updated, and we\'ll notify you of major changes.',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'App Version 1.0.0',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showFaqsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.help_center,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'FAQs / Help Center',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFaqItem(
                'What is Unimart?',
                'A student marketplace for buying, selling, and promoting services.',
              ),
              const SizedBox(height: 16),
              _buildFaqItem(
                'How do I list an item?',
                'Go to Add Product, upload, set price, and post.',
              ),
              const SizedBox(height: 16),
              _buildFaqItem(
                'How do transactions work?',
                'Through chat only. Payments/delivery are handled between students.',
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Still need help? Contact Support at support@unimart.ng ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Q: $question',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text('A: $answer', style: const TextStyle(fontSize: 14, height: 1.4)),
      ],
    );
  }
}
