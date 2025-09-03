// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:unimart/constants/app_colors.dart';
import 'package:unimart/models/review_model.dart';
import 'package:unimart/models/user_model.dart';
import 'package:unimart/services/auth_provider.dart';
import 'package:unimart/services/supabase_service.dart';

class ReviewBottomSheet extends StatefulWidget {
  final String productId;
  final UserModel seller;
  final String? existingReviewId;
  final ReviewModel? existingReview;
  final VoidCallback? onReviewSubmitted;

  const ReviewBottomSheet({
    super.key,
    required this.productId,
    required this.seller,
    this.existingReviewId,
    this.existingReview,
    this.onReviewSubmitted,
  });

  static void show({
    required BuildContext context,
    required String productId,
    required UserModel seller,
    String? existingReviewId,
    ReviewModel? existingReview,
    VoidCallback? onReviewSubmitted,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => ReviewBottomSheet(
        productId: productId,
        seller: seller,
        existingReviewId: existingReviewId,
        existingReview: existingReview,
        onReviewSubmitted: onReviewSubmitted,
      ),
    );
  }

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet>
    with TickerProviderStateMixin {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  int _rating = 0;
  bool _isLoading = false;

  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;

  // Animations
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment ?? '';
    }

    // Auto-focus and animate in
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      HapticFeedback.mediumImpact();
      _showError('Please select a rating');
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      HapticFeedback.mediumImpact();
      _showError('Please write a review');
      return;
    }

    if (_commentController.text.trim().length < 3) {
      HapticFeedback.mediumImpact();
      _showError('Review is too short');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser;
      if (currentUser == null) throw Exception('User not found');

      final review = ReviewModel(
        reviewerId: currentUser.id,
        reviewedUserId: widget.seller.id,
        productId: widget.productId,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      if (widget.existingReviewId != null) {
        await SupabaseService.instance.updateReview(widget.existingReviewId!, {
          'rating': _rating,
          'comment': _commentController.text.trim(),
        });
      } else {
        await SupabaseService.instance.createReview(review);
      }

      if (mounted) {
        HapticFeedback.lightImpact();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.existingReview != null
                      ? 'Review updated!'
                      : 'Review posted!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        // Call callback if provided
        widget.onReviewSubmitted?.call();

        // Close modal
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to submit review. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: GoogleFonts.inter())),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          minHeight: 400,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSellerInfo(),
                    const SizedBox(height: 24),
                    _buildRatingSection(),
                    const SizedBox(height: 24),
                    _buildCommentSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(),
      child: Row(
        children: [
          Text(
            widget.existingReview != null ? 'Edit Review' : 'Write Review',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),
          if (_isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Profile picture with Instagram-style gradient border
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF833AB4),
                  Color(0xFFE1306C),
                  Color(0xFFFCAF45),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  color: Colors.grey.shade200,
                ),
                child: widget.seller.profilePhotoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: Image.network(
                          widget.seller.profilePhotoUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.seller.name.isNotEmpty
                              ? widget.seller.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.seller.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How was your experience with this seller?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),

        // Stars with Instagram-style animation
        Row(
          children: List.generate(5, (index) {
            final isSelected = index < _rating;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _rating = index + 1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(right: 4),
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isSelected
                      ? const Color(0xFFFCAF45)
                      : Colors.grey.shade400,
                  size: 36,
                ),
              ),
            );
          }),
        ),

        // Rating feedback text
        if (_rating > 0) ...[
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: _rating > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRatingColor(_rating).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getRatingColor(_rating).withOpacity(0.3),
                ),
              ),
              child: Text(
                _getRatingText(_rating),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _getRatingColor(_rating),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),

        // Instagram-style comment input
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? AppColors.primaryBlue
                  : Colors.grey.shade200,
              width: _focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _commentController,
            focusNode: _focusNode,
            maxLines: null,
            minLines: 3,
            maxLength: 50,

            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.4,
              color: Colors.grey.shade500,
            ),

            decoration: InputDecoration(
              hintText: 'Tell others about your experience...',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 15,
              ),

              fillColor: Theme.of(context).colorScheme.tertiary,
              border: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
              counterStyle: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
            onChanged: (value) {
              setState(() {}); // Rebuild to update submit button state
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final canSubmit =
        _rating > 0 &&
        _commentController.text.trim().length >= 3 &&
        !_isLoading;

    return Container(
      padding: EdgeInsets.only(top: 10, right: 10, left: 10, bottom: 10),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Row(
        children: [
          // Cancel button
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),

          const Spacer(),

          // Submit button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: canSubmit ? _submitReview : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit
                    ? AppColors.primaryBlue
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: canSubmit ? 2 : 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.existingReview != null ? 'Update' : 'Post Review',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.primaryOrange,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor experience';
      case 2:
        return 'Could be better';
      case 3:
        return 'Good experience';
      case 4:
        return 'Great experience';
      case 5:
        return 'Amazing experience!';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red.shade500;
      case 2:
        return Colors.orange.shade500;
      case 3:
        return Colors.amber.shade600;
      case 4:
        return Colors.lightGreen.shade600;
      case 5:
        return Colors.green.shade600;
      default:
        return Colors.grey.shade500;
    }
  }
}
