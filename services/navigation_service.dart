// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unimart/constants/app_colors.dart';
import 'package:unimart/screens/auth/onborading_screen.dart';
import 'package:unimart/screens/auth/forget_screen.dart';
import 'package:unimart/screens/favorite/favorite_screen.dart';
import 'package:unimart/screens/product/add_product_screen.dart';
import 'package:unimart/screens/product/manage_product_screen.dart';
import 'package:unimart/screens/settings/settings_screen.dart';
import 'package:unimart/screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/product/product_detail_screen.dart';

import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../services/auth_provider.dart';
import '../services/supabase_service.dart';

class NavigationService {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final currentLocation = state.matchedLocation;
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoading = authProvider.loading;

      print(
        '🔀 Router redirect: location=$currentLocation, isAuth=$isAuthenticated, isLoading=$isLoading',
      );

      // 1. Handle onboarding first (highest priority)
      if (!seenOnboarding && currentLocation != '/onboarding') {
        print('🎯 Redirecting to onboarding');
        return '/onboarding';
      }

      // 2. If we've seen onboarding, handle loading state
      if (seenOnboarding && isLoading && currentLocation != '/splash') {
        print('🔄 Redirecting to splash');
        return '/splash';
      }

      // 3. Once loading is complete, handle authentication
      if (!isLoading) {
        final protectedRoutes = [
          '/profile',
          '/add-product',
          '/chats',
          '/favorites',
        ];
        final authRoutes = ['/login', '/signup'];

        // Redirect unauthenticated users from protected routes
        if (!isAuthenticated && protectedRoutes.contains(currentLocation)) {
          print('🔒 Redirecting to login for protected route');
          return '/login';
        }

        // Redirect authenticated users away from auth pages
        if (isAuthenticated &&
            (authRoutes.contains(currentLocation) ||
                currentLocation == '/splash')) {
          print('✅ User authenticated, redirecting to home');
          return '/';
        }
      }

      print('✅ No redirect needed');
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgetScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main App Routes with Page Transitions
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const HomeScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/product/:id',
            pageBuilder: (context, state) {
              final productId = state.pathParameters['id']!;
              return _buildPageWithTransition(
                child: ProductDetailScreen(productId: productId),
                state: state,
              );
            },
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const SettingsScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/add-product',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: AddProductScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/manage-products',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const ManageProductsScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/chats',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const ChatListScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const FavoriteScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: '/chat/:chatId',
            pageBuilder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              return _buildPageWithTransition(
                child: ChatScreen(chatId: chatId),
                state: state,
              );
            },
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const ProfileScreen(),
              state: state,
            ),
          ),
        ],
      ),
    ],
  );

  // Custom page transition builder
  static Page<void> _buildPageWithTransition({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Smooth fade and slide animation
        const begin = Offset(0.1, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var fadeAnimation = Tween(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _unreadMessages = 0;
  late AnimationController _animationController;
  late AnimationController _badgeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _badgeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();

    // Initialize animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _badgeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.bounceOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  void _fetchUnreadCount() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      final count = await SupabaseService.instance.getUnreadMessageCount(
        user.id,
        '',
        chatId: '',
      );
      if (mounted) {
        setState(() {
          _unreadMessages = count;
        });
        if (count > 0) {
          _badgeController.forward();
        }
      }
    }
  }

  void showGuestPrompt(BuildContext context) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sign Up Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'You need to sign up or log in to access this feature.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    if (mounted) {
                      context.go('/signup');
                    }
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(int index) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    // Check for protected pages
    if (user == null && [1, 2, 3, 4].contains(index)) {
      showGuestPrompt(context);
      return;
    }

    // Animate the tap
    _animationController.forward().then((_) {
      if (mounted) {
        _animationController.reverse();
      }
    });

    // Reset unread messages when navigating to chats
    if (index == 3) {
      setState(() {
        _unreadMessages = 0;
      });
      _badgeController.reverse();
    }

    setState(() {
      _currentIndex = index;
    });

    // Navigate with a slight delay for smooth animation feel
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/favorites');
          break;
        case 2:
          context.go('/add-product');
          break;
        case 3:
          context.go('/chats');
          break;
        case 4:
          context.go('/profile');
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.1, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
      bottomNavigationBar: AnimatedContainer(
        height: 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.only(top: 2, right: 10, left: 10, bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            final isActive = _currentIndex == index;
            return _buildNavItem(index, isActive);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isActive) {
    IconData iconData;
    String label;

    switch (index) {
      case 0:
        iconData = LucideIcons.home;
        label = 'Home';
        break;
      case 1:
        iconData = LucideIcons.heart;
        label = 'Favorites';
        break;
      case 2:
        iconData = LucideIcons.plusCircle;
        label = 'Sell';
        break;
      case 3:
        iconData = LucideIcons.messageCircle;
        label = 'Chats';
        break;
      case 4:
        iconData = LucideIcons.user;
        label = 'Profile';
        break;
      default:
        iconData = Icons.circle;
        label = '';
    }

    return GestureDetector(
      onTap: () => _onTap(index),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: isActive && _animationController.isAnimating
                ? _scaleAnimation.value
                : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 16 : 12,
                vertical: 10,
              ),
              decoration: isActive
                  ? BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    )
                  : BoxDecoration(borderRadius: BorderRadius.circular(24)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index == 3)
                    AnimatedBuilder(
                      animation: _badgeAnimation,
                      builder: (context, child) {
                        return Badge(
                          label: Text('$_unreadMessages'),
                          isLabelVisible: _unreadMessages > 0,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              iconData,
                              key: ValueKey('$index-$isActive'),
                              color: isActive
                                  ? AppColors.primaryOrange
                                  : Colors.grey[600],
                              size: isActive ? 22 : 20,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        iconData,
                        key: ValueKey('$index-$isActive'),
                        color: isActive
                            ? AppColors.primaryOrange
                            : Colors.grey[600],
                        size: isActive ? 22 : 20,
                      ),
                    ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    child: isActive
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isActive ? 1.0 : 0.0,
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: AppColors.primaryOrange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
