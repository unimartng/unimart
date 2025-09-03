// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unimart/constants/app_colors.dart';

import 'package:unimart/screens/home/home_screen.dart';
import 'package:unimart/widgets/loading_widget.dart';
import 'package:unimart/widgets/product_list_tile.dart';
import '../../services/supabase_service.dart';
import '../../models/product_model.dart';

import '../../services/auth_provider.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen>
    with TickerProviderStateMixin {
  List<ProductModel> _favoriteProducts = [];
  bool _isLoading = true;

  late AnimationController _fadeController;
  late AnimationController _listController;
  late AnimationController _refreshController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadFavorites();
  }

  void _setupAnimations() {
    // Main fade controller for screen transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // List animation controller for staggered entrance
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Refresh animation controller
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
        );

    // Start entrance animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _listController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
      });
    } else {
      // Animate refresh indicator
      _refreshController.forward().then((_) {
        _refreshController.reverse();
      });
    }

    final currentUser = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser;

    if (currentUser == null) {
      setState(() {
        _favoriteProducts = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final favoriteIds = await SupabaseService.instance.getFavoritesForUser(
        currentUser.id,
      );

      List<ProductModel> products = [];
      for (final productId in favoriteIds) {
        final product = await SupabaseService.instance.getProductById(
          productId,
        );
        if (product != null) {
          products.add(product);
        }
      }

      setState(() {
        _favoriteProducts = products;
        _isLoading = false;
      });

      // Trigger list animation after data loads
      if (!isRefresh && products.isNotEmpty) {
        _listController.reset();
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _listController.forward();
        }
      }
    } catch (e) {
      setState(() {
        _favoriteProducts = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _animatedRemoveItem(int index) async {
    // Create a temporary controller for the remove animation
    final removeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final slideOutAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0)).animate(
          CurvedAnimation(parent: removeController, curve: Curves.easeInBack),
        );

    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: removeController, curve: Curves.easeIn));

    // Start the animation
    await removeController.forward();

    // Remove the item after animation
    if (mounted) {
      setState(() {
        _favoriteProducts.removeAt(index);
      });
    }

    removeController.dispose();
  }

  Widget _buildEmptyState() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated heart icon
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 2000),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeInOut,
                builder: (context, heartValue, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * heartValue),
                    child: Icon(
                      Icons.favorite_outline,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Animated text
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _fadeController,
                        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                      ),
                    ),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _fadeController,
                      curve: const Interval(0.5, 1.0),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'No favorites yet',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start adding products to your favorites!',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Animated CTA button
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.bounceOut,
                        builder: (context, btnValue, child) {
                          return Transform.scale(
                            scale: btnValue,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.explore),
                              label: const Text('Explore Products'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedListItem(ProductModel product, int index) {
    // Staggered animation delay
    final delay = index * 0.1;

    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        // Item entrance animation
        final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _listController,
            curve: Interval(
              delay.clamp(0.0, 0.8),
              (delay + 0.4).clamp(0.2, 1.0),
              curve: Curves.easeOutBack,
            ),
          ),
        );

        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0.5, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _listController,
                curve: Interval(
                  delay.clamp(0.0, 0.8),
                  (delay + 0.4).clamp(0.2, 1.0),
                  curve: Curves.easeOut,
                ),
              ),
            );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: itemAnimation,
            child: Transform.scale(
              scale: itemAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 8),
                child: ProductListTile(
                  product: product,
                  currentUserId:
                      Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).currentUser?.id ??
                      '',
                  onFavoriteChanged: (isFavorite) async {
                    if (!isFavorite) {
                      // 1. Remove from backend
                      final currentUserId = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).currentUser?.id;
                      if (currentUserId != null) {
                        await SupabaseService.instance.removeFavoriteForUser(
                          currentUserId,
                          product.id ?? '',
                        );
                      }
                      // 2. Remove from UI with animation
                      await _animatedRemoveItem(index);
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(-0.5, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _fadeController,
                  curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
                ),
              ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _fadeController,
                curve: const Interval(0.2, 0.6),
              ),
            ),
            child: Text(
              'Favorites',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        centerTitle: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isLoading
              ? const Center(child: LoadingIndicator(message: 'Loading...'))
              : _favoriteProducts.isEmpty
              ? Center(child: _buildEmptyState())
              : AnimatedBuilder(
                  animation: _refreshController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 - (_refreshController.value * 0.02),
                      child: RefreshIndicator(
                        onRefresh: () => _loadFavorites(isRefresh: true),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return ListView.builder(
                              padding: const EdgeInsets.all(10),
                              itemCount: _favoriteProducts.length,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final product = _favoriteProducts[index];
                                return _buildAnimatedListItem(product, index);
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      // Animated floating counter badge
      floatingActionButton: _favoriteProducts.isNotEmpty
          ? AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _fadeController,
                      curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          '${_favoriteProducts.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
