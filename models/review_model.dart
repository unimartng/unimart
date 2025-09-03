import 'user_model.dart';

class ReviewModel {
  final String? id;
  final String reviewerId;
  final String reviewedUserId;
  final String? productId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final UserModel? reviewer;

  ReviewModel({
    this.id,
    required this.reviewerId,
    required this.reviewedUserId,
    this.productId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewer,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      reviewerId: json['reviewer_id'] ?? '',
      reviewedUserId: json['reviewed_user_id'] ?? '',
      productId: json['product_id'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      reviewer: UserModel.fromJson(json['users'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'reviewer_id': reviewerId,
      'reviewed_user_id': reviewedUserId,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
    };

    if (productId != null) {
      map['product_id'] = productId;
    }

    if (comment != null) {
      map['comment'] = comment;
    }

    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  ReviewModel copyWith({
    String? id,
    String? reviewerId,
    String? reviewedUserId,
    String? productId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    UserModel? reviewer,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewedUserId: reviewedUserId ?? this.reviewedUserId,
      productId: productId ?? this.productId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      reviewer: reviewer ?? this.reviewer,
    );
  }
}
