import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unimart/constants/app_colors.dart';
import 'package:unimart/models/review_model.dart';

import 'package:unimart/models/user_model.dart';
import 'package:unimart/screens/product/review_screen.dart';

class ReviewListWidget extends StatelessWidget {
  final List<ReviewModel> reviews;
  final String productId;
  final String? sellerId;
  final String? sellerName;
  final String? sellerEmail;
  final String? sellerPhotoUrl;
  final VoidCallback? onReviewAdded;

  const ReviewListWidget({
    super.key,
    required this.reviews,
    required this.productId,
    this.sellerId,
    this.sellerName,
    this.sellerEmail,
    this.sellerPhotoUrl,
    this.onReviewAdded,
  });

  // Public method to navigate to review screen
  void navigateToReviewScreen(BuildContext context) {
    _navigateToReviewScreen(context);
  }

  bool get _canWriteReview =>
      sellerId != null && sellerName != null && sellerEmail != null;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.rate_review, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No reviews yet',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to review this seller',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            if (_canWriteReview)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _navigateToReviewScreen(context),
                  child: Text(
                    'Write Review',
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Reviews (${reviews.length})',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: const Divider(height: 1, color: Colors.grey),
            ),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _buildReviewItem(context, review);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, ReviewModel review) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: review.reviewer?.profilePhotoUrl != null
                    ? NetworkImage(review.reviewer!.profilePhotoUrl!)
                    : null,
                child: review.reviewer?.profilePhotoUrl == null
                    ? Text(
                        review.reviewer?.name.isNotEmpty == true
                            ? review.reviewer!.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewer?.name ?? 'Anonymous',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: index < review.rating
                        ? Colors.amber
                        : Colors.grey[300],
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToReviewScreen(BuildContext context) {
    if (!_canWriteReview) return;

    // Create a seller object for the review screen
    final String id = sellerId!;
    final String name = sellerName!;
    final String email = sellerEmail!;

    final seller = UserModel(
      id: id,
      name: name,
      email: email,
      campus: '',
      profilePhotoUrl: sellerPhotoUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ReviewBottomSheet.show(
      context: context,
      productId: productId,
      seller: seller,
      onReviewSubmitted: onReviewAdded,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
