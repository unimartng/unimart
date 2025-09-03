import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unimart/screens/home/category_screen.dart';

import 'package:unimart/services/auth_provider.dart';
import 'package:unimart/services/supabase_service.dart';
import 'package:unimart/widgets/loading_widget.dart';
import 'package:unimart/widgets/product_card.dart';
import 'package:unimart/widgets/search_bar.dart';
import '../../models/product_model.dart';
import '../../models/university_model.dart';
import '../../constants/app_colors.dart';
import '../../utils/error_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _showWelcomeBanner = false;
  String? _signedUrl;
  bool _showFeaturedOnly = true; // Add this to control featured vs all products

  // University filter
  List<University> _universities = [];
  University? _selectedUniversity;
  bool _universitiesLoading = true;

  // Animation Controllers
  late AnimationController _headerController;
  late AnimationController _bannerController;
  late AnimationController _categoryController;
  late AnimationController _productController;
  late AnimationController _avatarController;

  // Animations
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _bannerSlideAnimation;
  late Animation<double> _bannerScaleAnimation;
  late Animation<double> _categoryStaggerAnimation;
  late Animation<double> _productStaggerAnimation;
  late Animation<double> _avatarPulseAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.apps, 'color': Colors.blueGrey},
    {'name': 'Electronics', 'icon': Icons.devices, 'color': Colors.blue},
    {'name': 'Fashion', 'icon': Icons.checkroom, 'color': Colors.pink},
    {'name': 'Books', 'icon': Icons.menu_book, 'color': Colors.orange},
    {'name': 'Sports', 'icon': Icons.sports_soccer, 'color': Colors.green},
    {'name': 'Food', 'icon': Icons.fastfood, 'color': Colors.redAccent},
    {'name': 'Services', 'icon': Icons.handshake, 'color': Colors.teal},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkBanner();
    _loadProducts();
    _loadProfileImage();
    _loadUniversities();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Header animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerSlideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Banner animation
    _bannerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _bannerSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _bannerController, curve: Curves.easeOutBack),
    );

    _bannerScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bannerController, curve: Curves.elasticOut),
    );

    // Category animation
    _categoryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _categoryStaggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _categoryController, curve: Curves.easeOutCubic),
    );

    // Product animation
    _productController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _productStaggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _productController, curve: Curves.easeOutCubic),
    );

    // Avatar pulse animation
    _avatarController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _avatarPulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _headerController.forward();
        _avatarController.repeat(reverse: true);
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _categoryController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _bannerController.dispose();
    _categoryController.dispose();
    _productController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _loadProfileImage() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _signedUrl = user?.profilePhotoUrl;
  }

  Future<void> _checkBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldShow = !(prefs.getBool('hasSeenBanner') ?? false);
    setState(() {
      _showWelcomeBanner = shouldShow;
    });

    if (shouldShow && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _bannerController.forward();
      });
    }
  }

  void _dismissBanner() async {
    await _bannerController.reverse();
    if (mounted) {
      setState(() => _showWelcomeBanner = false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenBanner', true);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await SupabaseService.instance.getProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        campus: _selectedUniversity?.name,
        featuredOnly: _showFeaturedOnly,
      );

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
        _productController.reset();
        _productController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showError(
          context,
          e,
          title: 'Products Error',
          onRetry: _loadProducts,
        );
      }
    }
  }

  Future<void> _loadUniversities() async {
    setState(() => _universitiesLoading = true);
    try {
      final universities = await SupabaseService.instance.getUniversities();
      if (mounted) {
        setState(() {
          _universities = universities;
          _universitiesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _universitiesLoading = false);
        ErrorHandler.showError(context, e, title: 'Universities Error');
      }
    }
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    _loadProducts();
  }

  void _onUniversitySelected(University? university) {
    setState(() => _selectedUniversity = university);
    _loadProducts();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Animated Header
          AnimatedBuilder(
            animation: _headerController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _headerSlideAnimation.value),
                child: FadeTransition(
                  opacity: _headerFadeAnimation,
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 50, bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 15, right: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                      child: Text(
                                        'Hello, ${currentUser?.name ?? "Student"}👋',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Find great deals on campus',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white.withOpacity(0.95),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _avatarPulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _avatarPulseAnimation.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundImage:
                                            (_signedUrl != null &&
                                                _signedUrl!.isNotEmpty)
                                            ? NetworkImage(_signedUrl!)
                                            : null,
                                        child:
                                            (_signedUrl == null ||
                                                _signedUrl!.isEmpty)
                                            ? Text(
                                                currentUser?.name[0]
                                                        .toUpperCase() ??
                                                    '',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        // Search Bar and University Filter
                        Padding(
                          padding: const EdgeInsets.only(left: 15, right: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),

                                  child: CustomSearchBar(
                                    onChanged: _onSearchChanged,
                                    hintText: 'Search products, categories...',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width:
                                    100, // Increased width to accommodate content
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<University>(
                                    borderRadius: BorderRadius.circular(15),
                                    dropdownColor: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textLight,
                                      fontSize: 16,
                                    ),
                                    value: _selectedUniversity,
                                    hint: Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.school, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'University',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem<University>(
                                        value: null,
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 12),
                                          child: Text(
                                            'All Universities',
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                      ..._universities.map(
                                        (university) =>
                                            DropdownMenuItem<University>(
                                              value: university,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 12,
                                                ),
                                                child: Text(
                                                  university.name,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                      ),
                                    ],
                                    onChanged: _universitiesLoading
                                        ? null
                                        : _onUniversitySelected,
                                    icon: const Padding(
                                      padding: EdgeInsets.only(right: 12),
                                      child: Icon(Icons.arrow_drop_down),
                                    ),
                                    isExpanded: true,
                                    disabledHint: _universitiesLoading
                                        ? const Padding(
                                            padding: EdgeInsets.only(left: 12),
                                            child: Row(
                                              children: [
                                                Icon(Icons.school, size: 16),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Loading...',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _categoryStaggerAnimation,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _categoryStaggerAnimation,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  30 * (1 - _categoryStaggerAnimation.value),
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 15,
                                        right: 15,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Categories',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 20,
                                            ),
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
                                                      ) =>
                                                          const CategoryGridPage(),
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
                                              'See all',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Horizontal Category ListView
                                    Container(
                                      height: 40,
                                      margin: const EdgeInsets.only(left: 5),

                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _categories.length,
                                        itemBuilder: (context, index) {
                                          return AnimatedBuilder(
                                            animation:
                                                _categoryStaggerAnimation,
                                            builder: (context, child) {
                                              final staggerDelay = index * 0.1;
                                              final staggeredAnimation =
                                                  Tween<double>(
                                                    begin: 0.0,
                                                    end: 1.0,
                                                  ).animate(
                                                    CurvedAnimation(
                                                      parent:
                                                          _categoryController,
                                                      curve: Interval(
                                                        staggerDelay.clamp(
                                                          0.0,
                                                          0.8,
                                                        ),
                                                        (staggerDelay + 0.2)
                                                            .clamp(0.2, 1.0),
                                                        curve:
                                                            Curves.easeOutCubic,
                                                      ),
                                                    ),
                                                  );

                                              return FadeTransition(
                                                opacity: staggeredAnimation,
                                                child: Transform.translate(
                                                  offset: Offset(
                                                    30 *
                                                        (1 -
                                                            staggeredAnimation
                                                                .value),
                                                    0,
                                                  ),
                                                  child: Container(
                                                    margin: EdgeInsets.only(
                                                      right:
                                                          index ==
                                                              _categories
                                                                      .length -
                                                                  1
                                                          ? 20
                                                          : 8,
                                                    ),
                                                    child: _buildCategoryCard(
                                                      index,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Body with animations
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Animated Welcome Banner
                    if (_showWelcomeBanner)
                      AnimatedBuilder(
                        animation: _bannerController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _bannerSlideAnimation.value),
                            child: Transform.scale(
                              scale: _bannerScaleAnimation.value,
                              child: Container(
                                margin: const EdgeInsets.all(20),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: AppColors.orangeGradient,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryOrange
                                          .withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.campaign,
                                      color: Colors.white,
                                      size: 38,
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome to Unimart! 🎉',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'List your items or grab a deal from fellow students.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.white
                                                      .withOpacity(0.95),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      onPressed: _dismissBanner,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // Animated Categories Section

                    // Animated Products Section
                    AnimatedBuilder(
                      animation: _productStaggerAnimation,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _productStaggerAnimation,
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              50 * (1 - _productStaggerAnimation.value),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 20,
                                    left: 20,
                                    top: 20,
                                    bottom: 10,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _showFeaturedOnly
                                            ? 'Featured Products'
                                            : 'All Products',
                                        style: GoogleFonts.poppins(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 20,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          // Toggle button for featured/all products
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryBlue
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppColors.primaryBlue
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _showFeaturedOnly = true;
                                                    });
                                                    _loadProducts();
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _showFeaturedOnly
                                                          ? AppColors
                                                                .primaryBlue
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Featured',
                                                      style: GoogleFonts.poppins(
                                                        color: _showFeaturedOnly
                                                            ? Colors.white
                                                            : AppColors
                                                                  .primaryBlue,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _showFeaturedOnly = false;
                                                    });
                                                    _loadProducts();
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: !_showFeaturedOnly
                                                          ? AppColors
                                                                .primaryBlue
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'All',
                                                      style: GoogleFonts.poppins(
                                                        color:
                                                            !_showFeaturedOnly
                                                            ? Colors.white
                                                            : AppColors
                                                                  .primaryBlue,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                _isLoading
                                    ? const Center(
                                        child: LoadingIndicator(
                                          message: 'Loading...',
                                        ),
                                      )
                                    : _products.isEmpty
                                    ? _buildEmptyState()
                                    : _buildAnimatedProductGrid(currentUser),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(int index) {
    return GestureDetector(
      onTap: () => _onCategorySelected(_categories[index]['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _categories[index]['name'] == _selectedCategory
              ? _categories[index]['color'].withOpacity(0.1)
              : AppColors.primaryOrange.withAlpha(120),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _categories[index]['name'] == _selectedCategory
                ? _categories[index]['color']
                : Colors.grey[400]!,
            width: _categories[index]['name'] == _selectedCategory ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _categories[index]['name'] == _selectedCategory
                    ? _categories[index]['color']
                    : _categories[index]['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _categories[index]['icon'],
                color: _categories[index]['name'] == _selectedCategory
                    ? (index == 0 ? Colors.grey[100] : Colors.white)
                    : _categories[index]['color'],
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _categories[index]['name'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: _categories[index]['name'] == _selectedCategory
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: _categories[index]['name'] == _selectedCategory
                    ? _categories[index]['color']
                    : Colors.grey[200],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Image.asset('assets/images/empty.png', height: 120),
        const SizedBox(height: 16),
        Text(
          'No products found',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Try adjusting your search or filters',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildAnimatedProductGrid(currentUser) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.72,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return AnimatedBuilder(
          animation: _productStaggerAnimation,
          builder: (context, child) {
            final staggerDelay = index * 0.1;
            final staggeredAnimation = Tween<double>(begin: 0.0, end: 1.0)
                .animate(
                  CurvedAnimation(
                    parent: _productController,
                    curve: Interval(
                      staggerDelay.clamp(0.0, 0.8),
                      (staggerDelay + 0.2).clamp(0.2, 1.0),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                );

            return FadeTransition(
              opacity: staggeredAnimation,
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - staggeredAnimation.value)),
                child: Transform.scale(
                  scale: 0.8 + (0.2 * staggeredAnimation.value),
                  child: ProductCard(
                    product: product,
                    currentUserId: currentUser?.id ?? '',
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
