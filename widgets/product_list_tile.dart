// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unimart/widgets/loading_widget.dart';
import '../models/product_model.dart';
import '../constants/app_colors.dart';
import '../screens/product/product_detail_screen.dart';
import '../services/supabase_service.dart';
import '../screens/profile/user_profile_screen.dart';

class ProductListTile extends StatefulWidget {
  final ProductModel product;
  final String currentUserId;
  final VoidCallback? onTap;
  final void Function(bool isFavorite)? onFavoriteChanged;

  const ProductListTile({
    super.key,
    required this.product,
    required this.currentUserId,
    this.onTap,
    this.onFavoriteChanged,
  });

  @override
  State<ProductListTile> createState() => _ProductListTileState();
}

class _ProductListTileState extends State<ProductListTile> {
  bool _isFavorite = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  @override
  void dispose() {
    // Cancel any ongoing operations if needed
    super.dispose();
  }

  Future<void> _checkFavorite() async {
    if (widget.currentUserId.isEmpty) return;

    try {
      final isFav = await SupabaseService.instance.isFavorite(
        widget.currentUserId,
        widget.product.id ?? '',
      );

      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.currentUserId.isEmpty) return;

    // Check if widget is still mounted before starting operation
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      if (_isFavorite) {
        await SupabaseService.instance.removeFavorite(
          widget.currentUserId,
          widget.product.id ?? '',
        );
      } else {
        await SupabaseService.instance.addFavorite(
          widget.currentUserId,
          widget.product.id ?? '',
        );
      }

      final isFav = await SupabaseService.instance.isFavorite(
        widget.currentUserId,
        widget.product.id ?? '',
      );

      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _loading = false;
        });
        widget.onFavoriteChanged?.call(_isFavorite);
      }
    } catch (e) {
      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          widget.onTap ??
          () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ProductDetailScreen(productId: widget.product.id ?? ''),
                transitionsBuilder: (context, animation, _, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            );
          },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            height: 110, // Reduced slightly to ensure it fits
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    height: double.infinity,
                    color: AppColors.surface,
                    child:
                        widget.product.imageUrls.isNotEmpty &&
                            widget.product.imageUrls.first.startsWith('http')
                        ? Hero(
                            tag: 'product-image-${widget.product.id}',
                            child: CachedNetworkImage(
                              imageUrl: widget.product.imageUrls.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: LoadingIndicator(
                                  message: 'Loading...',
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          )
                        : const Icon(
                            Icons.image_not_supported,
                            color: AppColors.textLight,
                            size: 48,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.product.title,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontSize: 15,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '₦${widget.product.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryOrange,
                                    fontSize: 12,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (widget.product.seller != null)
                        Flexible(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundImage:
                                    widget.product.seller!.profilePhotoUrl !=
                                        null
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
                                          fontSize: 11,
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
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.product.category,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Favorite Button
          Positioned(
            top: 80,
            right: 10,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? AppColors.primaryOrange : Colors.grey,
                  size: 17,
                ),
                onPressed: _loading ? null : _toggleFavorite,
              ),
            ),
          ),
          if (widget.product.isFeatured &&
              widget.product.featuredUntil != null &&
              widget.product.featuredUntil!.isAfter(DateTime.now()))
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        ],
      ),
    );
  }
}
