class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String messageText;
  final DateTime createdAt;
  final bool isRead;
  final String? replyToMessageId;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.messageText,
    required this.createdAt,
    this.isRead = false,
    this.replyToMessageId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      chatId: json['chat_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      messageText: json['message_text'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: json['is_read'] ?? false,
      replyToMessageId: json['reply_to_message_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': '',
      'chat_id': chatId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message_text': messageText,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'reply_to_message_id': replyToMessageId,
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? messageText,
    DateTime? createdAt,
    bool? isRead,
    String? replyToMessageId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      messageText: messageText ?? this.messageText,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    );
  }
}
