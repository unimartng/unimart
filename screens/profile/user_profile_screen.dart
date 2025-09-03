// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:unimart/constants/app_colors.dart';
import 'package:unimart/models/user_model.dart';
import 'package:unimart/models/product_model.dart';
import 'package:unimart/models/review_model.dart';
import 'package:unimart/services/auth_provider.dart';
import 'package:unimart/services/supabase_service.dart';
import 'package:unimart/widgets/product_card.dart';
import 'package:unimart/widgets/review_list_widget.dart';
import 'package:unimart/screens/chat/chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? userName;

  const UserProfileScreen({super.key, required this.userId, this.userName});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  UserModel? _user;
  List<ProductModel> _products = [];
  List<ReviewModel> _reviews = [];
  double _averageRating = 0.0;
  bool _isLoading = true;
  bool _productsLoading = false;
  bool _reviewsLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Load user profile
      final user = await SupabaseService.instance.getUserProfile(widget.userId);

      // Load user's average rating
      final rating = await SupabaseService.instance.getUserAverageRating(
        widget.userId,
      );

      setState(() {
        _user = user;
        _averageRating = rating;
        _isLoading = false;
      });

      // Load products and reviews in parallel
      await Future.wait([_loadProducts(), _loadReviews()]);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _productsLoading = true);
    try {
      final products = await SupabaseService.instance.getUserProducts(
        widget.userId,
      );
      setState(() {
        _products = products;
        _productsLoading = false;
      });
    } catch (e) {
      setState(() => _productsLoading = false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _reviewsLoading = true);
    try {
      final reviews = await SupabaseService.instance.getUserReviews(
        widget.userId,
      );
      setState(() {
        _reviews = reviews;
        _reviewsLoading = false;
      });
    } catch (e) {
      setState(() => _reviewsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? const Center(child: Text('User not found'))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.primaryBlue,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.primaryBlue.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Profile Picture
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage:
                                      _user!.profilePhotoUrl != null
                                      ? CachedNetworkImageProvider(
                                          _user!.profilePhotoUrl!,
                                        )
                                      : null,
                                  child: _user!.profilePhotoUrl == null
                                      ? Text(
                                          _user!.name.isNotEmpty
                                              ? _user!.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                // User Name
                                Text(
                                  _user!.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // University
                                Text(
                                  _user!.campus,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ];
              },
              body: Column(
                children: [
                  // User Stats Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Products Count
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${_products.length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                              Text(
                                'Products',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Rating
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _averageRating.toStringAsFixed(1),
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber[700],
                                    size: 20,
                                  ),
                                ],
                              ),
                              Text(
                                '${_reviews.length} reviews',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action Buttons
                        if (currentUser != null &&
                            currentUser.id != widget.userId)
                          Expanded(
                            child: Column(
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.chat, size: 16),
                                  label: const Text('Chat'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _startChat(context, currentUser),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(color: AppColors.primaryBlue),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Products'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Products Tab
                        _buildProductsTab(),
                        // Reviews Tab
                        _buildReviewsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProductsTab() {
    if (_productsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No products yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This user hasn\'t listed any products',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive grid parameters
        final screenWidth = constraints.maxWidth;
        int crossAxisCount;
        if (screenWidth < 400) {
          crossAxisCount = 2; // Single column for small screens
        } else if (screenWidth < 600) {
          crossAxisCount = 2; // Two columns for medium screens
        } else {
          crossAxisCount = 3; // Three columns for large screens
        }

        return Column(
          children: [
            // Products Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products (${_products.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_products.length} items',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Products Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75, // Good aspect ratio for product cards
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return ProductCard(
                    product: product,
                    currentUserId:
                        Provider.of<AuthProvider>(context).currentUser?.id ??
                        '',
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    if (_reviewsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ReviewListWidget(
        reviews: _reviews,
        productId: '', // Not needed for user reviews
        sellerId: widget.userId,
        sellerName: _user?.name ?? '',
        sellerEmail: _user?.email ?? '',
        sellerPhotoUrl: _user?.profilePhotoUrl,
        onReviewAdded: () {
          _loadReviews();
          _loadUserData(); // Refresh average rating
        },
      ),
    );
  }

  Future<void> _startChat(BuildContext context, UserModel currentUser) async {
    try {
      final chatId = await SupabaseService.instance.createOrGetChat(
        currentUser.id,
        widget.userId,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(chatId: chatId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
