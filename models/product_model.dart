import 'user_model.dart';

class ProductModel {
  final String? id;
  final String userId;
  final String title;
  final String description;
  final double price;
  final String category;
  final List<String> imageUrls;
  final String campus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSold;
  final UserModel? seller;

  ProductModel({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrls,
    required this.campus,
    required this.createdAt,
    required this.updatedAt,
    this.isSold = false,
    this.seller,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      campus: json['campus'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      isSold: json['is_sold'] ?? false,
      seller: json['seller'] != null
          ? UserModel.fromJson(json['seller'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'user_id': userId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'image_urls': imageUrls,
      'campus': campus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_sold': isSold,
    };
    if (id != null && id!.isNotEmpty) {
      map['id'] = id as String;
    }
    return map;
  }

  ProductModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? price,
    String? category,
    List<String>? imageUrls,
    String? campus,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSold,
    UserModel? seller,
  }) {
    return ProductModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      campus: campus ?? this.campus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSold: isSold ?? this.isSold,
      seller: seller ?? this.seller,
    );
  }
}
