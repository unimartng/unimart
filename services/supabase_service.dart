// ignore_for_file: unnecessary_null_comparison

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/university_model.dart';
import '../models/review_model.dart';
import 'dart:typed_data';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  // Authentication Methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String campus,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'campus': campus},
    );

    if (response.user != null) {
      await _createUserProfile(response.user!.id, name, campus, email);
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'https://ubwqruzgcgqfzgcpzaqd.supabase.co/auth/v1/callback',
    );
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'https://ubwqruzgcgqfzgcpzaqd.supabase.co/auth/v1/callback',
    );
  }

  /// Change user password (requires current password)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // First, re-authenticate with current password
    await client.auth.signInWithPassword(
      email: user.email!,
      password: currentPassword,
    );

    // Then update the password
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Delete user account and all associated data
  Future<void> deleteUserAccount({required String password}) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // First, re-authenticate with current password
    await client.auth.signInWithPassword(
      email: user.email!,
      password: password,
    );

    // Delete user data from all tables
    await _deleteUserData(user.id);

    // Sign out the user (this effectively deactivates the account)
    // Note: Complete account deletion requires backend/admin intervention
    await client.auth.signOut();
  }

  /// Delete all user data from database tables
  Future<void> _deleteUserData(String userId) async {
    // Delete user's products
    await client.from('products').delete().eq('user_id', userId);

    // Delete user's reviews (both as reviewer and reviewed)
    await client.from('reviews').delete().eq('reviewer_id', userId);
    await client.from('reviews').delete().eq('reviewed_user_id', userId);

    // Delete user's favorites
    await client.from('favorites').delete().eq('user_id', userId);

    // Delete user's chat messages (both sent and received)
    await client.from('messages').delete().eq('sender_id', userId);
    await client.from('messages').delete().eq('receiver_id', userId);

    // Delete user's chats
    await client
        .from('chats')
        .delete()
        .or('user1_id.eq.$userId,user2_id.eq.$userId');

    // Delete user profile
    await client.from('users').delete().eq('id', userId);
  }

  User? get currentUser => client.auth.currentUser;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // User Profile Methods
  Future<void> _createUserProfile(
    String userId,
    String name,
    String campus,
    String email,
  ) async {
    await client.from('users').insert({
      'id': userId,
      'name': name,
      'campus': campus,
      'email': email,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final response = await client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return response != null ? UserModel.fromJson(response) : null;
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await client
        .from('users')
        .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }

  Future<ProductModel?> getProductById(String productId) async {
    try {
      final response = await client
          .from('products')
          .select('*, users(*)')
          .eq('id', productId)
          .single();

      final product = ProductModel.fromJson(response);
      final seller = response['users'] != null
          ? UserModel.fromJson(response['users'])
          : null;
      return product.copyWith(seller: seller);
    } catch (e) {
      print('Error getting product by ID: $e');
      if (e.toString().contains('No rows found')) {
        throw Exception('Product not found');
      }
      throw Exception('Failed to load product: ${e.toString()}');
    }
  }

  // Product Methods
  Future<List<ProductModel>> getProducts({
    String? campus,
    String? category,
    String? searchQuery,
    bool featuredOnly = false,
  }) async {
    try {
      final response = await client.from('products').select('*, users(*)');

      List<ProductModel> products = response.map((json) {
        final product = ProductModel.fromJson(json);
        final seller = json['users'] != null
            ? UserModel.fromJson(json['users'])
            : null;
        return product.copyWith(seller: seller);
      }).toList();

      // Filter only unsold
      products = products.where((p) => p.isSold == false).toList();

      if (featuredOnly) {
        final now = DateTime.now();
        products = products
            .where(
              (p) =>
                  p.isFeatured == true &&
                  p.featuredUntil != null &&
                  p.featuredUntil!.isAfter(now),
            )
            .toList();
      }

      if (campus != null && campus.isNotEmpty) {
        products = products.where((p) => p.campus == campus).toList();
      }

      if (category != null && category.isNotEmpty) {
        products = products.where((p) => p.category == category).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        products = products
            .where(
              (p) =>
                  p.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  p.description.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
            )
            .toList();
      }

      // Sort products: featured first, then by creation date
      products.sort((a, b) {
        final now = DateTime.now();
        final aIsFeatured =
            a.isFeatured &&
            a.featuredUntil != null &&
            a.featuredUntil!.isAfter(now);
        final bIsFeatured =
            b.isFeatured &&
            b.featuredUntil != null &&
            b.featuredUntil!.isAfter(now);

        // If one is featured and the other isn't, featured comes first
        if (aIsFeatured && !bIsFeatured) return -1;
        if (!aIsFeatured && bIsFeatured) return 1;

        // If both are featured or both are not featured, sort by creation date
        return b.createdAt.compareTo(a.createdAt);
      });

      return products;
    } catch (e) {
      print('Error getting products: $e');
      throw Exception('Failed to load products: ${e.toString()}');
    }
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final response = await client
          .from('products')
          .insert(product.toJson())
          .select()
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      rethrow; // Let caller handle this if needed
    }
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    await client
        .from('products')
        .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', productId);
  }

  Future<void> deleteProduct(String productId) async {
    await client.from('products').delete().eq('id', productId);
  }

  Future<List<ProductModel>> getUserProducts(String userId) async {
    try {
      final response = await client
          .from('products')
          .select('*, users(*)')
          .eq('user_id', userId);

      final products = response.map((json) {
        final product = ProductModel.fromJson(json);
        final seller = json['users'] != null
            ? UserModel.fromJson(json['users'])
            : null;
        return product.copyWith(seller: seller);
      }).toList();

      // Sort by created_at descending
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return products;
    } catch (e) {
      return [];
    }
  }

  // Chat Methods
  Future<String> createOrGetChat(String user1Id, String user2Id) async {
    try {
      // Check if chat already exists
      final existingChat = await client
          .from('chats')
          .select()
          .or('user1_id.eq.$user1Id,user2_id.eq.$user1Id')
          .or('user1_id.eq.$user2Id,user2_id.eq.$user2Id')
          .maybeSingle();

      if (existingChat != null) {
        return existingChat['chat_id'];
      }

      // Create new chat
      final chatId =
          '${user1Id}_${user2Id}_${DateTime.now().millisecondsSinceEpoch}';
      await client.from('chats').insert({
        'chat_id': chatId,
        'user1_id': user1Id,
        'user2_id': user2Id,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return chatId;
    } catch (e) {
      // Fallback: create a simple chat ID
      return '${user1Id}_${user2Id}_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<List<ChatModel>> getUserChats(String userId) async {
    try {
      final response = await client
          .from('chats')
          .select('*, messages(*)')
          .or('user1_id.eq.$userId,user2_id.eq.$userId');

      final chats = response.map((json) {
        final chat = ChatModel.fromJson(json);
        final lastMessage =
            json['messages'] != null && json['messages'].isNotEmpty
            ? MessageModel.fromJson(json['messages'].last)
            : null;
        return chat.copyWith(lastMessage: lastMessage);
      }).toList();

      // Sort by updated_at descending
      chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return chats;
    } catch (e) {
      return [];
    }
  }

  Future<List<MessageModel>> getChatMessages(String chatId) async {
    try {
      final response = await client
          .from('messages')
          .select()
          .eq('chat_id', chatId);

      final messages = response
          .map((json) => MessageModel.fromJson(json))
          .toList();

      // Sort by created_at ascending
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return messages;
    } catch (e) {
      return [];
    }
  }

  Future<void> sendMessage(MessageModel message) async {
    try {
      // 1. Insert the message into the "messages" table
      final response = await client.from('messages').insert({
        'chat_id': message.chatId,
        'sender_id': message.senderId,
        'receiver_id': message.receiverId,
        'message_text': message.messageText,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (response == null) {
        return;
      }

      // 2. Update the chat's updated_at timestamp
      await client
          .from('chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('chat_id', message.chatId);
      // ignore: empty_catches
    } catch (e) {
      // Handle error silently
    }
  }

  Stream<List<MessageModel>> subscribeToMessages(String chatId) {
    try {
      return client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('chat_id', chatId)
          .map(
            (response) =>
                response.map((json) => MessageModel.fromJson(json)).toList(),
          );
    } catch (e) {
      return Stream.value([]);
    }
  }

  // --- Typing Status Methods ---
  Future<void> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    await client.from('typing_status').upsert({
      'chat_id': chatId,
      'user_id': userId,
      'is_typing': isTyping,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<bool> subscribeToTypingStatus(String chatId, String otherUserId) {
    return client
        .from('typing_status')
        .stream(primaryKey: ['chat_id', 'user_id'])
        .order('updated_at')
        .map((rows) {
          final filtered = rows
              .where(
                (row) =>
                    row['chat_id'] == chatId && row['user_id'] == otherUserId,
              )
              .toList();
          return filtered.isNotEmpty && filtered.first['is_typing'] == true;
        });
  }

  // Storage Methods
  Future<String> uploadImage(String path, Uint8List bytes) async {
    // ignore: unused_local_variable
    final response = await client.storage
        .from('images')
        .uploadBinary(path, bytes);
    // Use 'path' instead of 'response' for getPublicUrl
    return client.storage.from('images').getPublicUrl(path);
  }

  Future<void> deleteImage(String path) async {
    try {
      await client.storage.from('images').remove([path]);
    } catch (e) {
      // Handle error silently
    }
  }

  // --- Favorite Methods ---
  Future<void> addFavorite(String userId, String productId) async {
    await client.from('favorites').insert({
      'user_id': userId,
      'product_id': productId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFavorite(String userId, String productId) async {
    await client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  Future<void> removeFavoriteForUser(String userId, String productId) async {
    await client.from('favorites').delete().match({
      'user_id': userId,
      'product_id': productId,
    });
  }

  Future<bool> isFavorite(String userId, String productId) async {
    final response = await client
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
    return response != null;
  }

  Future<List<String>> getFavoritesForUser(String userId) async {
    final response = await client
        .from('favorites')
        .select('product_id')
        .eq('user_id', userId);
    return List<String>.from(response.map((item) => item['product_id']));
  }

  Future<int> getUnreadMessageCount(
    String userId,
    String currentUserId, {
    required String chatId,
  }) async {
    try {
      final response = await client
          .from('messages')
          .select('id')
          .eq('receiver_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching unread message count: $e');
      return 0;
    }
  }

  Stream<List<ChatModel>> getUserChatsStream(String userId) async* {
    while (true) {
      final data = await client
          .rpc('get_user_chats_with_details', params: {'p_user_id': userId})
          .select();
      yield data.map<ChatModel>((chat) => ChatModel.fromJson(chat)).toList();
      await Future.delayed(const Duration(seconds: 3)); // Poll every 3 seconds
    }
  }

  Stream<int> getUnreadMessageCountStream(String userId) {
    return client.from('messages').stream(primaryKey: ['id']).map((listOfMaps) {
      final unreadMessages = listOfMaps.where((message) {
        return message['receiver_id'] == userId && message['is_read'] == false;
      });
      return unreadMessages.length;
    });
  }

  Future<void> markMessagesAsRead(String chatId, String receiverId) async {
    try {
      await client
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .eq('receiver_id', receiverId);
    } catch (e) {
      // ignore: avoid_print
      print('Error marking messages as read: $e');
    }
  }

  Future<void> markChatAsRead(String chatId, String userId) async {
    await client.from('messages').update({'is_read': true}).match({
      'chat_id': chatId,
      'recipient_id': userId,
      'is_read': false,
    });
  }

  Future<List<ProductModel>> getProductsByUser(String userId) async {
    final response = await client
        .from('products')
        .select()
        .eq('user_id', userId);
    return (response as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<String?> uploadProfilePhoto(String userId, File imageFile) async {
    // Get file extension
    final fileExt = p.extension(imageFile.path).replaceFirst('.', '');

    // Ensure the userId is safe for use in a path
    final safeUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    // Create timestamped file name
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final filePath = 'profile_photos/$safeUserId.$timestamp.$fileExt';

    try {
      if (!await imageFile.exists()) {
        return null;
      }

      final bytes = await imageFile.readAsBytes();

      final response = await client.storage
          .from('profile-photos')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      if (response == null || response.isEmpty) {
        return null;
      }

      final urlResponse = client.storage
          .from('profile-photos')
          .getPublicUrl(filePath);
      return urlResponse;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getSignedProfileImageUrl(String filePath) async {
    final response = await client.storage
        .from('profile-photos')
        .createSignedUrl(filePath, 60 * 60); // 1 hour validity
    return response;
  }

  // Example: Remove image from product and storage
  Future<void> removeProductImage(String imageUrl, String productId) async {
    // Extract the path from the public URL
    final uri = Uri.parse(imageUrl);
    final segments = uri.pathSegments;
    // Assuming your public URL is like https://your-project.supabase.co/storage/v1/object/public/images/filename.jpg
    // The path for deletion is everything after 'images/'
    final imagePathIndex = segments.indexOf('images');
    if (imagePathIndex != -1 && imagePathIndex + 1 < segments.length) {
      final imagePath = segments.sublist(imagePathIndex + 1).join('/');
      await SupabaseService.instance.deleteImage(imagePath);
    }

    // Remove the image URL from the product's imageUrls list and update the product
    final product = await SupabaseService.instance.getProductById(productId);
    if (product != null) {
      final updatedImageUrls = List<String>.from(product.imageUrls)
        ..remove(imageUrl);
      await SupabaseService.instance.updateProduct(productId, {
        'image_urls': updatedImageUrls,
      });
    }
  }

  //category

  // Future<List<Map<String, dynamic>>> fetchCampuses() async {
  //   final response = await Supabase.instance.client.from('campuses').select();

  //   if (response.isEmpty) {
  //     print('No campuses found');
  //     return [];
  //   }

  //   return response;
  // }

  // University Methods
  Future<List<University>> getUniversities() async {
    try {
      final response = await client
          .from('universities')
          .select('*')
          .order('name');

      return response.map((json) => University.fromMap(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Review Methods
  Future<List<ReviewModel>> getProductReviews(String productId) async {
    try {
      final response = await client
          .from('reviews')
          .select('*, users!reviews_reviewer_id_fkey(*)')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      final reviews = (response as List)
          .map((json) => ReviewModel.fromJson(json))
          .toList();
      return reviews;
    } catch (e) {
      throw Exception('Failed to load reviews: ${e.toString()}');
    }
  }

  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final response = await client
          .from('reviews')
          .select('*, reviewer:users(*)')
          .eq('reviewed_user_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => ReviewModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createReview(ReviewModel review) async {
    await client.from('reviews').insert(review.toJson());
  }

  Future<void> updateReview(
    String reviewId,
    Map<String, dynamic> updates,
  ) async {
    await client.from('reviews').update(updates).eq('id', reviewId);
  }

  Future<void> deleteReview(String reviewId) async {
    await client.from('reviews').delete().eq('id', reviewId);
  }

  Future<bool> hasUserReviewed(
    String reviewerId,
    String reviewedUserId,
    String? productId,
  ) async {
    try {
      var query = client
          .from('reviews')
          .select('id')
          .eq('reviewer_id', reviewerId)
          .eq('reviewed_user_id', reviewedUserId);

      if (productId != null) {
        query = query.eq('product_id', productId);
      }

      final result = await query.maybeSingle();
      return result != null;
    } catch (e) {
      return false;
    }
  }

  Future<double> getUserAverageRating(String userId) async {
    try {
      final response = await client
          .from('reviews')
          .select('rating')
          .eq('reviewed_user_id', userId);

      if (response.isEmpty) return 0.0;

      final ratings = response.map((r) => r['rating'] as int).toList();
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      return average.toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  Future<double?> getFeaturedPlanPrice(int days) async {
    final response = await client
        .from('featured_plans')
        .select('price')
        .eq('days', days)
        .single();

    if (response != null && response['price'] != null) {
      return double.tryParse(response['price'].toString());
    }
    return null;
  }

  Future<void> clearChat(String chatId) async {
    await client.from('messages').delete().match({'chat_id': chatId});
  }
}
