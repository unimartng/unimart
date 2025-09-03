import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unimart/widgets/loading_widget.dart';
import '../models/product_model.dart';
import '../constants/app_colors.dart';
import '../screens/product/product_detail_screen.dart';
import '../services/supabase_service.dart';
import '../screens/profile/user_profile_screen.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final String currentUserId;
  final VoidCallback? onTap;
  final void Function(bool isFavorite)? onFavoriteChanged;

  const ProductCard({
    super.key,
    required this.product,
    required this.currentUserId,
    this.onTap,
    this.onFavoriteChanged,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isFavorite = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    if (widget.currentUserId.isEmpty) return;
    final isFav = await SupabaseService.instance.isFavorite(
      widget.currentUserId,
      widget.product.id ?? '',
    );
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    if (widget.currentUserId.isEmpty) return;
    setState(() => _loading = true);
    try {
      if (_isFavorite) {
        await SupabaseService.instance.removeFavorite(
          widget.currentUserId,
          widget.product.id ?? '',
        );
      } else {
        // Only add if not already a favorite
        if (!await SupabaseService.instance.isFavorite(
          widget.currentUserId,
          widget.product.id ?? '',
        )) {
          await SupabaseService.instance.addFavorite(
            widget.currentUserId,
            widget.product.id ?? '',
          );
        }
      }
      // Always check the latest favorite status from the DB
      final isFav = await SupabaseService.instance.isFavorite(
        widget.currentUserId,
        widget.product.id ?? '',
      );
      setState(() {
        _isFavorite = isFav;
        _loading = false;
      });
      if (widget.onFavoriteChanged != null) {
        widget.onFavoriteChanged!(_isFavorite);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ProductDetailScreen(productId: widget.product.id ?? ''),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          );
        }
      },
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      color: AppColors.surface,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child:
                          widget.product.imageUrls.isNotEmpty &&
                              widget.product.imageUrls.first.startsWith('http')
                          ? Hero(
                              tag: 'product-image-${widget.product.id}',
                              child: CachedNetworkImage(
                                imageUrl: widget.product.imageUrls.first,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  child: Center(
                                    child: LoadingIndicator(
                                      message: 'Loading...',
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.surface,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.surface,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: AppColors.textLight,
                                size: 48,
                              ),
                            ),
                    ),
                  ),
                ),

                // Product Info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 4,
                      right: 12,
                      left: 12,
                      bottom: 5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title
                        Text(
                          widget.product.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 15,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Price
                        Text(
                          '₦${widget.product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryOrange,
                                fontSize: 14,
                              ),
                        ),

                        // Seller Info
                        if (widget.product.seller != null)
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundImage:
                                    (widget.product.seller!.profilePhotoUrl !=
                                            null &&
                                        widget
                                            .product
                                            .seller!
                                            .profilePhotoUrl!
                                            .isNotEmpty)
                                    ? NetworkImage(
                                        widget.product.seller!.profilePhotoUrl!,
                                      )
                                    : null,
                                child:
                                    (widget.product.seller!.profilePhotoUrl ==
                                            null ||
                                        widget
                                            .product
                                            .seller!
                                            .profilePhotoUrl!
                                            .isEmpty)
                                    ? Text(
                                        widget.product.seller!.name.isNotEmpty
                                            ? widget.product.seller!.name[0]
                                                  .toUpperCase()
                                            : '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserProfileScreen(
                                          userId: widget.product.seller!.id,
                                          userName: widget.product.seller!.name,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    widget.product.seller!.name,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.product.category,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.primaryOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Featured Badge
            if (widget.product.isFeatured &&
                widget.product.featuredUntil != null &&
                widget.product.featuredUntil!.isAfter(DateTime.now()))
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryOrange,
                        AppColors.primaryOrange.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Featured',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Favorite Button
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: _toggleFavorite,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite
                              ? AppColors.primaryOrange
                              : Colors.grey[600],
                          size: 16,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
