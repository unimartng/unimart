import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:unimart/screens/auth/forget_screen.dart';
import 'package:unimart/screens/auth/signup_screen.dart';

import '../../services/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Animation Controllers
  late AnimationController _logoController;
  late AnimationController _titleController;
  late AnimationController _formController;
  late AnimationController _buttonController;
  late AnimationController _socialController;
  late AnimationController _shakeController;

  // Animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _formStaggerAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _socialSlideAnimation;
  late Animation<double> _shakeAnimation;

  // Focus nodes for field animations
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // Field animation states
  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupFocusListeners();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Title animation
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _titleSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Form animation
    _formController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _formStaggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );

    // Button animation - Fixed version
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Social buttons animation
    _socialController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _socialSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _socialController, curve: Curves.easeOutBack),
    );

    // Shake animation for errors
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _setupFocusListeners() {
    _emailFocusNode.addListener(() {
      setState(() {
        _emailFocused = _emailFocusNode.hasFocus;
      });
    });

    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _logoController.forward();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _titleController.forward();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _formController.forward();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _socialController.forward();
    });
  }

  void _triggerShakeAnimation() {
    _shakeController.reset();
    _shakeController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    _socialController.dispose();
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      _buttonController.reset();
      await _buttonController.forward();
      await _buttonController.reverse();

      // ignore: use_build_context_synchronously
      final authProvider = context.read<AuthProvider>();
      await authProvider.signIn(
        email: _emailController.text.trim(),

        password: _passwordController.text,
        // ignore: use_build_context_synchronously
        context: context,
      );

      if (authProvider.error != null && mounted) {
        _triggerShakeAnimation();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      _triggerShakeAnimation();
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signInWithGoogle();

    if (authProvider.error != null && mounted) {
      _triggerShakeAnimation();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWideScreen = constraints.maxWidth > 600;

            return Center(
              child: Container(
                width: isWideScreen ? 500 : double.infinity,
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        final shakeValue = _shakeAnimation.value;
                        final shakeOffset =
                            10 *
                            (shakeValue < 0.5
                                ? 2 * shakeValue
                                : 2 * (1 - shakeValue)) *
                            (shakeValue < 0.25
                                ? 1
                                : shakeValue < 0.5
                                ? -1
                                : shakeValue < 0.75
                                ? 1
                                : -1);

                        return Transform.translate(
                          offset: Offset(shakeOffset, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 40),

                              // Animated Logo/Icon
                              Center(
                                child: AnimatedBuilder(
                                  animation: _logoController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _logoScaleAnimation.value,
                                      child: Transform.rotate(
                                        angle: _logoRotationAnimation.value,
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.primaryBlue,
                                                AppColors.primaryBlue
                                                    .withOpacity(0.7),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primaryBlue
                                                    .withOpacity(0.3),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.storefront,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 22),

                              // Animated Title
                              AnimatedBuilder(
                                animation: _titleController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      _titleSlideAnimation.value,
                                    ),
                                    child: FadeTransition(
                                      opacity: _titleFadeAnimation,
                                      child: Column(
                                        crossAxisAlignment: isWideScreen
                                            ? CrossAxisAlignment.start
                                            : CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Welcome Back👋',
                                            style: GoogleFonts.poppins(
                                              fontSize: 30,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: isWideScreen
                                                ? TextAlign.left
                                                : TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 30),

                              // Animated Form Fields
                              ..._buildAnimatedFormFields(),

                              const SizedBox(height: 5),

                              // Forgot Password
                              AnimatedBuilder(
                                animation: _formStaggerAnimation,
                                builder: (context, child) {
                                  final staggeredAnimation =
                                      Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _formController,
                                          curve: const Interval(
                                            0.6,
                                            1.0,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                      );

                                  return FadeTransition(
                                    opacity: staggeredAnimation,
                                    child: Transform.translate(
                                      offset: Offset(
                                        0,
                                        20 * (1 - staggeredAnimation.value),
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            // Handle forgot password
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ForgetScreen(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Forgot Password?',
                                            style: GoogleFonts.poppins(
                                              color: AppColors.primaryBlue,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 10),

                              // Fixed Animated Sign In Button
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  return AnimatedBuilder(
                                    animation: _formStaggerAnimation,
                                    builder: (context, child) {
                                      final staggeredAnimation =
                                          Tween<double>(
                                            begin: 0.0,
                                            end: 1.0,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: _formController,
                                              curve: const Interval(
                                                0.7,
                                                1.0,
                                                curve: Curves.easeOutCubic,
                                              ),
                                            ),
                                          );

                                      return FadeTransition(
                                        opacity: staggeredAnimation,
                                        child: Transform.translate(
                                          offset: Offset(
                                            0,
                                            20 * (1 - staggeredAnimation.value),
                                          ),
                                          child: AnimatedBuilder(
                                            animation: _buttonScaleAnimation,
                                            builder: (context, child) {
                                              return Transform.scale(
                                                scale:
                                                    _buttonScaleAnimation.value,
                                                child: CustomButton(
                                                  onPressed:
                                                      authProvider.isLoading
                                                      ? null
                                                      : _signIn,
                                                  height: 52,
                                                  width: double.infinity,
                                                  child: authProvider.isLoading
                                                      ? const SizedBox(
                                                          height: 20,
                                                          width: 20,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                  Color
                                                                >(Colors.white),
                                                          ),
                                                        )
                                                      : Text(
                                                          'Sign In',
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // Sign Up Link
                              AnimatedBuilder(
                                animation: _formStaggerAnimation,
                                builder: (context, child) {
                                  final staggeredAnimation =
                                      Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _formController,
                                          curve: const Interval(
                                            0.8,
                                            1.0,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                      );

                                  return FadeTransition(
                                    opacity: staggeredAnimation,
                                    child: Transform.translate(
                                      offset: Offset(
                                        0,
                                        20 * (1 - staggeredAnimation.value),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Don't have an account? ",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder:
                                                      (
                                                        context,
                                                        animation,
                                                        secondaryAnimation,
                                                      ) => const SignupScreen(),
                                                  transitionsBuilder:
                                                      (
                                                        context,
                                                        animation,
                                                        secondaryAnimation,
                                                        child,
                                                      ) {
                                                        return SlideTransition(
                                                          position:
                                                              Tween<Offset>(
                                                                begin:
                                                                    const Offset(
                                                                      1.0,
                                                                      0.0,
                                                                    ),
                                                                end:
                                                                    Offset.zero,
                                                              ).animate(
                                                                CurvedAnimation(
                                                                  parent:
                                                                      animation,
                                                                  curve: Curves
                                                                      .easeInOutCubic,
                                                                ),
                                                              ),
                                                          child: child,
                                                        );
                                                      },
                                                ),
                                              );
                                            },
                                            child: Text(
                                              'Sign Up',
                                              style: GoogleFonts.poppins(
                                                color: AppColors.primaryBlue,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Animated Social Buttons
                              AnimatedBuilder(
                                animation: _socialController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      _socialSlideAnimation.value,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Expanded(child: Divider()),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              child: Text(
                                                'OR',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color:
                                                          AppColors.textLight,
                                                    ),
                                              ),
                                            ),
                                            const Expanded(child: Divider()),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        _buildAnimatedSocialButton(
                                          onPressed: _signInWithGoogle,
                                          icon: Icons.g_mobiledata,
                                          label: 'Continue with Google',
                                          delay: 0.0,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildAnimatedSocialButton(
                                          onPressed: () => context.go('/'),
                                          icon: Icons.person_outline,
                                          label: 'Continue as Guest',
                                          delay: 0.1,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedFormFields() {
    return [
      // Email Field
      AnimatedBuilder(
        animation: _formStaggerAnimation,
        builder: (context, child) {
          final staggeredAnimation = Tween<double>(begin: 0.0, end: 1.0)
              .animate(
                CurvedAnimation(
                  parent: _formController,
                  curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
                ),
              );

          return FadeTransition(
            opacity: staggeredAnimation,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - staggeredAnimation.value)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.poppins(
                      color: _emailFocused
                          ? AppColors.primaryBlue
                          : AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: _emailFocused
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    child: const Text('Email'),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _emailFocused
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: CustomTextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      const SizedBox(height: 20),

      // Password Field
      AnimatedBuilder(
        animation: _formStaggerAnimation,
        builder: (context, child) {
          final staggeredAnimation = Tween<double>(begin: 0.0, end: 1.0)
              .animate(
                CurvedAnimation(
                  parent: _formController,
                  curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
                ),
              );

          return FadeTransition(
            opacity: staggeredAnimation,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - staggeredAnimation.value)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.poppins(
                      color: _passwordFocused
                          ? AppColors.primaryBlue
                          : AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: _passwordFocused
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    child: const Text('Password'),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _passwordFocused
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: CustomTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      hintText: 'Enter your password',
                      obscureText: _obscurePassword,
                      suffixIcon: AnimatedRotation(
                        turns: _obscurePassword ? 0.0 : 0.5,
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildAnimatedSocialButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _socialController,
      builder: (context, child) {
        final staggeredAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _socialController,
            curve: Interval(delay, delay + 0.4, curve: Curves.easeOutBack),
          ),
        );

        return FadeTransition(
          opacity: staggeredAnimation,
          child: Transform.scale(
            scale: 0.8 + (0.2 * staggeredAnimation.value),
            child: OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 24),
              label: Text(
                label,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
