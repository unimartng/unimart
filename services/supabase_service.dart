// ignore_for_file: unnecessary_null_comparison

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
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

  // Product Methods
  Future<List<ProductModel>> getProducts({
    String? campus,
    String? category,
    String? searchQuery,
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

      // Apply filters in memory
      products = products.where((p) => p.isSold == false).toList();

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

      // Sort by created_at descending
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return products;
    } catch (e) {
      return [];
    }
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
      return null;
    }
  }

  Future<void> createProduct(ProductModel product) async {
    await client.from('products').insert(product.toJson());
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
    try {
      final response = await client.storage
          .from('images')
          .uploadBinary(path, bytes);
      return client.storage.from('images').getPublicUrl(response);
    } catch (e) {
      return '';
    }
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
}
