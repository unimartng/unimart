// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:unimart/screens/auth/login_screen.dart';
import '../../services/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/university_model.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  List<University> _universities = [];
  University? _selectedUniversity;
  bool _universitiesLoading = true;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _formController;
  late AnimationController _buttonController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _formAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUniversities();
    _startAnimations();
  }

  void _setupAnimations() {
    // Main fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Slide animation for header
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    // Form fields staggered animation
    _formController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );

    // Button scale animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _formController.forward();
    });
  }

  Future<void> _loadUniversities() async {
    setState(() => _universitiesLoading = true);
    try {
      final universities = await SupabaseService.instance.getUniversities();
      setState(() {
        _universities = universities;
        _universitiesLoading = false;
      });
    } catch (e) {
      setState(() => _universitiesLoading = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      // Button press animation
      _buttonController.forward().then((_) {
        _buttonController.reverse();
      });

      final authProvider = context.read<AuthProvider>();
      await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        campus: _selectedUniversity?.name ?? '',
        context: context,
      );

      if (authProvider.error != null) {
        if (mounted) {
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
      } else if (authProvider.currentUser != null && mounted) {
        // Animate out before navigation
        await _fadeController.reverse();
        context.go('/');
      }
    } else {
      // Shake animation for validation errors
      _shakeForm();
    }
  }

  void _shakeForm() {
    final animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.elasticIn),
    );

    animationController.addListener(() {
      setState(() {});
    });

    animationController.forward().then((_) {
      animationController.dispose();
    });
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signInWithGoogle();

    if (authProvider.error != null && mounted) {
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

            return FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Container(
                  width: isWideScreen ? 500 : double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),

                          // Animated Header
                          SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sign Up',
                                  style: GoogleFonts.poppins(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: isWideScreen
                                      ? TextAlign.left
                                      : TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Create your account to continue',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                  textAlign: isWideScreen
                                      ? TextAlign.left
                                      : TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Animated Form Fields
                          ..._buildAnimatedFormFields(isWideScreen),

                          const SizedBox(height: 24),

                          // Animated Sign Up Button
                          _buildAnimatedSignUpButton(),

                          const SizedBox(height: 16),

                          // Animated Sign In Link
                          _buildAnimatedFormField(
                            delay: 6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                TextButton(
                                  onPressed: () {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder:
                                                  (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                  ) => const LoginScreen(),
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
                                                            begin: const Offset(
                                                              1.0,
                                                              0.0,
                                                            ),
                                                            end: Offset.zero,
                                                          ).animate(
                                                            CurvedAnimation(
                                                              parent: animation,
                                                              curve: Curves
                                                                  .easeInOut,
                                                            ),
                                                          ),
                                                      child: child,
                                                    );
                                                  },
                                              transitionDuration:
                                                  const Duration(
                                                    milliseconds: 300,
                                                  ),
                                            ),
                                          );
                                        });
                                  },
                                  child: const Text('Sign In'),
                                ),
                              ],
                            ),
                          ),

                          // Animated Divider
                          _buildAnimatedFormField(
                            delay: 7,
                            child: Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'OR',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.textLight),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Animated Google Sign Up Button
                          _buildAnimatedFormField(
                            delay: 8,
                            child: _AnimatedButton(
                              onPressed: _signInWithGoogle,
                              child: OutlinedButton.icon(
                                onPressed: _signInWithGoogle,
                                icon: const Icon(Icons.g_mobiledata, size: 24),
                                label: const Text('Continue with Google'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Animated Continue as Guest Button
                          _buildAnimatedFormField(
                            delay: 9,
                            child: _AnimatedButton(
                              onPressed: () => context.go('/'),
                              child: OutlinedButton(
                                onPressed: () => context.go('/'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                child: const Text('Continue as Guest'),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  List<Widget> _buildAnimatedFormFields(bool isWideScreen) {
    return [
      // Name Field
      _buildAnimatedFormField(
        delay: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Name'),
            _AnimatedTextField(
              controller: _nameController,
              hintText: 'Enter your full name',
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),

      const SizedBox(height: 10),

      // Email Field
      _buildAnimatedFormField(
        delay: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Email'),
            _AnimatedTextField(
              controller: _emailController,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
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
          ],
        ),
      ),

      const SizedBox(height: 10),

      // University Field
      _buildAnimatedFormField(
        delay: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('University'),
            _AnimatedDropdown(
              value: _selectedUniversity,
              items: _universities,
              onChanged: _universitiesLoading
                  ? null
                  : (University? value) {
                      setState(() {
                        _selectedUniversity = value;
                      });
                    },
              universitiesLoading: _universitiesLoading,
            ),
          ],
        ),
      ),

      const SizedBox(height: 10),

      // Password Field
      _buildAnimatedFormField(
        delay: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Password'),
            _AnimatedTextField(
              controller: _passwordController,
              hintText: 'Enter your password',
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
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
          ],
        ),
      ),

      const SizedBox(height: 10),

      // Confirm Password Field
      _buildAnimatedFormField(
        delay: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Confirm Password'),
            _AnimatedTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirm your password',
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildAnimatedFormField({required int delay, required Widget child}) {
    return AnimatedBuilder(
      animation: _formAnimation,
      builder: (context, _) {
        final progress = (_formAnimation.value * 10 - delay).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 20 * (1 - progress)),
          child: Opacity(opacity: progress, child: child),
        );
      },
    );
  }

  Widget _buildAnimatedSignUpButton() {
    return _buildAnimatedFormField(
      delay: 5,
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ScaleTransition(
            scale: _buttonScaleAnimation,
            child: CustomButton(
              height: 50,
              width: double.infinity,
              onPressed: authProvider.isLoading ? null : _signUp,
              child: authProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Create Account'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
    );
  }
}

// Custom animated text field widget
class _AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AnimatedTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<_AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<_AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _focusAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _focusController.forward();
      } else {
        _focusController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _focusAnimation,
      child: CustomTextField(
        controller: widget.controller,
        hintText: widget.hintText,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        suffixIcon: widget.suffixIcon,
        validator: widget.validator,
        focusNode: _focusNode,
      ),
    );
  }
}

// Custom animated dropdown widget
class _AnimatedDropdown extends StatefulWidget {
  final University? value;
  final List<University> items;
  final ValueChanged<University?>? onChanged;
  final bool universitiesLoading;

  const _AnimatedDropdown({
    this.value,
    required this.items,
    this.onChanged,
    required this.universitiesLoading,
  });

  @override
  State<_AnimatedDropdown> createState() => _AnimatedDropdownState();
}

class _AnimatedDropdownState extends State<_AnimatedDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          height: 48,
          child: DropdownButtonFormField<University>(
            borderRadius: BorderRadius.circular(12),
            dropdownColor: Theme.of(context).colorScheme.tertiary,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            value: widget.value,
            items: widget.items
                .map(
                  (university) => DropdownMenuItem(
                    value: university,
                    child: Text(university.name),
                  ),
                )
                .toList(),
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              fillColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null) {
                return 'Please select your university';
              }
              return null;
            },
            disabledHint: widget.universitiesLoading
                ? const Text('Loading universities...')
                : null,
          ),
        ),
      ),
    );
  }
}

// Custom animated button widget
class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _AnimatedButton({this.onPressed, required this.child});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
