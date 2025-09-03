// ignore_for_file: use_build_context_synchronously, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unimart/constants/app_colors.dart';
import 'package:unimart/screens/product/add_product_screen.dart';
import 'package:unimart/widgets/loading_widget.dart';
import '../../services/supabase_service.dart';
import '../../models/product_model.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../chat/chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unimart/models/review_model.dart';
import 'package:unimart/widgets/review_list_widget.dart';
import 'package:unimart/screens/product/review_screen.dart';
import 'package:unimart/screens/profile/user_profile_screen.dart';
import 'package:unimart/utils/error_handler.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  ProductModel? _product;
  bool _isLoading = true;
  List<ReviewModel> _reviews = [];
  bool _reviewsLoading = false;
  bool _isFavorited = false;
  bool _isFavoriteBusy = false;

  // Simplified animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Page controller for image carousel
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  // Scroll controller
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollListener();
    _loadProduct();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 100;
      if (scrolled != _isScrolled) {
        setState(() => _isScrolled = scrolled);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final product = await SupabaseService.instance.getProductById(
        widget.productId,
      );
      if (mounted) {
        if (product == null) {
          // Product not found, show error
          setState(() {
            _product = null;
            _isLoading = false;
          });
          ErrorHandler.showError(
            context,
            'Product not found',
            title: 'Product Error',
          );
          return;
        }
        setState(() {
          _product = product;
          _isLoading = false;
        });
        _loadReviews();
        _startAnimations();
        _loadFavoriteState();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _product = null;
          _isLoading = false;
        });
        ErrorHandler.showError(context, e, title: 'Product Error');
      }
    }
  }

  Future<void> _loadFavoriteState() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      if (currentUser == null || _product?.id == null) return;
      final isFav = await SupabaseService.instance.isFavorite(
        currentUser.id,
        _product!.id!,
      );
      if (mounted) {
        setState(() => _isFavorited = isFav);
      }
    } catch (_) {}
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  Future<void> _loadReviews() async {
    setState(() => _reviewsLoading = true);
    try {
      final reviews = await SupabaseService.instance.getProductReviews(
        widget.productId,
      );
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _reviewsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _reviewsLoading = false);
        ErrorHandler.showError(context, e, title: 'Reviews Error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _product == null
          ? _buildErrorState()
          : _buildMainContent(currentUser),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: _isScrolled ? AppColors.primaryBlue : Colors.transparent,
      elevation: _isScrolled ? 1 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isScrolled
              ? Colors.grey.shade100
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: _isScrolled ? Colors.black87 : Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isScrolled
                ? Colors.grey.shade100
                : Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _isFavorited
                    ? Colors.red
                    : (_isScrolled ? Colors.black87 : Colors.white),
                size: 20,
                key: ValueKey(_isFavorited),
              ),
            ),
            onPressed: _isFavoriteBusy ? null : _handleToggleFavorite,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: LoadingIndicator(message: 'Loading product...'));
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Product not found',
            style: GoogleFonts.inter(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(currentUser) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(),
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductInfo(),
                    if (_product!.seller != null)
                      _buildSellerSection(currentUser),
                    _buildProductDetails(),
                    _buildReviewsSection(),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _product!.imageUrls.isNotEmpty
                ? _product!.imageUrls.length
                : 1,
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              if (_product!.imageUrls.isEmpty) {
                return Container(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                );
              }
              return CachedNetworkImage(
                imageUrl: _product!.imageUrls[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.error, color: Colors.grey.shade400),
                ),
              );
            },
          ),
          if (_product!.imageUrls.length > 1) _buildImageIndicators(),
          if (_product!.isSold) _buildSoldBadge(),
        ],
      ),
    );
  }

  Widget _buildImageIndicators() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _product!.imageUrls.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: index == _currentImageIndex ? 24 : 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: index == _currentImageIndex
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoldBadge() {
    return Positioned(
      top: 12,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'SOLD',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price and title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _product!.title,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _product!.category,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue,
                      AppColors.primaryBlue.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₦${_product!.price.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          if (_product!.description.isNotEmpty) ...[
            Text(
              'Description',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _product!.description,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSellerSection(currentUser) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                child: const Icon(Icons.person, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(
                              userId: _product!.seller!.id,
                              userName: _product!.seller!.name,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        _product!.seller!.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _product!.seller!.email,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (currentUser != null && _product!.seller!.id == currentUser.id)
                ElevatedButton.icon(
                  onPressed: _handleEditProduct,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                )
              else if (currentUser != null &&
                  _product!.seller!.id != currentUser.id)
                ElevatedButton.icon(
                  onPressed: () => _handleChatWithSeller(currentUser),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
            ],
          ),
          if (currentUser != null &&
              _product!.seller!.id != currentUser.id) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleReviewSeller(currentUser),
                icon: const Icon(Icons.star_outline, size: 18),
                label: const Text('Write Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Details',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          _buildDetailItem('University', _product!.campus, Icons.school),
          _buildDetailItem('Category', _product!.category, Icons.category),
          _buildDetailItem(
            'Condition',
            _product!.isSold ? 'Sold' : 'Available',
            _product!.isSold ? Icons.block : Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Reviews',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_reviews.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ReviewListWidget(
            reviews: _reviews,
            productId: widget.productId,
            sellerId: _product!.seller?.id,
            sellerName: _product!.seller?.name,
            sellerEmail: _product!.seller?.email,
            sellerPhotoUrl: _product!.seller?.profilePhotoUrl,
            onReviewAdded: () => _loadReviews(),
          ),
        ],
      ),
    );
  }

  // Event handlers
  void _handleEditProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(editProduct: _product),
      ),
    ).then((value) {
      if (value == true) _loadProduct();
    });
  }

  void _handleChatWithSeller(currentUser) async {
    HapticFeedback.lightImpact();
    final chatId = await SupabaseService.instance.createOrGetChat(
      currentUser.id,
      _product!.seller!.id,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(chatId: chatId)),
    );
  }

  void _handleReviewSeller(currentUser) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to write a review'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();

    try {
      final hasReviewed = await SupabaseService.instance.hasUserReviewed(
        currentUser.id,
        _product!.seller!.id,
        widget.productId,
      );

      if (hasReviewed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('You have already reviewed this seller'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      // Show Instagram-style review bottom sheet
      ReviewBottomSheet.show(
        context: context,
        productId: widget.productId,
        seller: _product!.seller!,
        onReviewSubmitted: () {
          _loadReviews(); // Refresh reviews when submitted
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to check review status. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _handleToggleFavorite() async {
    HapticFeedback.lightImpact();
    if (_product?.id == null) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      ErrorHandler.showInfo(context, 'Please log in to favorite products');
      return;
    }

    setState(() => _isFavoriteBusy = true);
    final newValue = !_isFavorited;
    setState(() => _isFavorited = newValue);
    try {
      if (newValue) {
        await SupabaseService.instance.addFavorite(
          currentUser.id,
          _product!.id!,
        );
      } else {
        await SupabaseService.instance.removeFavorite(
          currentUser.id,
          _product!.id!,
        );
      }
    } catch (e) {
      // revert on failure
      if (mounted) setState(() => _isFavorited = !newValue);
      ErrorHandler.showError(context, e, title: 'Favorite Error');
    } finally {
      if (mounted) setState(() => _isFavoriteBusy = false);
    }
  }
}
