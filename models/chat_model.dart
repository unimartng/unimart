import 'user_model.dart';
import 'message_model.dart';

class ChatModel {
  final String chatId;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MessageModel? lastMessage;
  final UserModel? otherUser;
  final int unreadCount;

  ChatModel({
    required this.chatId,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.otherUser,
    required this.unreadCount,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['chat_id'] ?? '',
      user1Id: json['user1_id'] ?? '',
      user2Id: json['user2_id'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'])
          : null,
      otherUser: json['other_user'] != null
          ? UserModel.fromJson(json['other_user'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message': lastMessage?.toJson(),
      'other_user': otherUser?.toJson(),
      'unread_count': unreadCount,
    };
  }

  ChatModel copyWith({
    String? chatId,
    String? user1Id,
    String? user2Id,
    DateTime? createdAt,
    DateTime? updatedAt,
    MessageModel? lastMessage,
    UserModel? otherUser,
    int? unreadCount,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      otherUser: otherUser ?? this.otherUser,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
