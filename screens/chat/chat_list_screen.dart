import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unimart/constants/app_colors.dart';
import '../../services/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart'; // Added import for UserModel
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<ChatModel>> _chatsFuture;
  late String _currentUserId;
  final Map<String, UserModel> _userCache = {};

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _currentUserId = user?.id ?? '';
    _chatsFuture = SupabaseService.instance.getUserChats(_currentUserId);
  }

  Future<UserModel?> _getOtherUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }
    final user = await SupabaseService.instance.getUserProfile(userId);
    if (user != null) _userCache[userId] = user;
    return user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontSize: 28, color: Colors.white),
        ),
        centerTitle: false,
        backgroundColor: AppColors.primaryBlue,
      ),
      body: FutureBuilder<List<ChatModel>>(
        future: _chatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No chats yet.'));
          }
          final chats = snapshot.data!;
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.user1Id == _currentUserId
                  ? chat.user2Id
                  : chat.user1Id;
              final lastMessage = chat.lastMessage;
              return FutureBuilder<UserModel?>(
                future: _getOtherUser(otherUserId),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user?.profilePhotoUrl != null
                          ? NetworkImage(user!.profilePhotoUrl!)
                          : null,
                      child: user?.profilePhotoUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(user?.name ?? 'User'),
                    subtitle: Text(
                      lastMessage?.messageText ?? 'No messages yet',
                    ),
                    trailing: lastMessage != null
                        ? Text(
                            _formatTime(lastMessage.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(chatId: chat.chatId),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.month}/${time.day}/${time.year}';
    }
  }
}
