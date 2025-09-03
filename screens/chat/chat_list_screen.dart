import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unimart/constants/app_colors.dart';
import 'package:unimart/widgets/loading_widget.dart';
import '../../services/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  Stream<List<ChatModel>>? _chatsStream;
  String _currentUserId = '';
  final Map<String, UserModel> _userCache = {};

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final userId = user?.id ?? '';

    // Only recreate stream if user ID changed
    if (userId != _currentUserId) {
      _currentUserId = userId;
      _setupStreams();
    }
  }

  void _setupStreams() {
    if (_currentUserId.isNotEmpty) {
      _chatsStream = SupabaseService.instance.getUserChatsStream(
        _currentUserId,
      );
    } else {
      _chatsStream = Stream.value([]);
    }
  }

  Future<UserModel?> _getOtherUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }
    final user = await SupabaseService.instance.getUserProfile(userId);
    if (user != null) {
      _userCache[userId] = user;
    }
    return user;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) {
      return DateFormat.jm().format(time);
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.MMMd().format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: false,
      ),
      body: _chatsStream == null
          ? const Center(child: LoadingIndicator(message: 'Loading chats...'))
          : StreamBuilder<List<ChatModel>>(
              stream: _chatsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: LoadingIndicator(message: 'Loading chats...'),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() => _setupStreams()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final chats = snapshot.data!;
                chats.sort((a, b) {
                  final aTime = a.lastMessage?.createdAt ?? a.updatedAt;
                  final bTime = b.lastMessage?.createdAt ?? b.updatedAt;
                  return bTime.compareTo(aTime);
                });

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _setupStreams());
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: AppColors.primaryBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      return ChatListItem(
                        chat: chats[index],
                        currentUserId: _currentUserId,
                        getOtherUser: _getOtherUser,
                        formatTime: _formatTime,
                        onTap: () => _navigateToChat(chats[index]),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting with other students',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(ChatModel chat) {
    // Navigate to chat - the ChatScreen should handle marking messages as read
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(chatId: chat.chatId)),
    );
  }
}

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final Future<UserModel?> Function(String) getOtherUser;
  final String Function(DateTime) formatTime;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.getOtherUser,
    required this.formatTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUserId = chat.user1Id == currentUserId
        ? chat.user2Id
        : chat.user1Id;
    final lastMessage = chat.lastMessage;
    final unreadCount = chat.unreadCount;
    final hasUnread = unreadCount > 0;

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: hasUnread
            ? Theme.of(context).colorScheme.tertiary.withOpacity(0.7)
            : Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<UserModel?>(
              future: getOtherUser(otherUserId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return _buildLoadingItem();
                }

                final user = userSnapshot.data;
                return Row(
                  children: [
                    // Avatar with unread indicator
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryBlue.withOpacity(
                            0.1,
                          ),
                          backgroundImage: user?.profilePhotoUrl != null
                              ? NetworkImage(user!.profilePhotoUrl!)
                              : null,
                          child: user?.profilePhotoUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 28,
                                  color: AppColors.primaryBlue,
                                )
                              : null,
                        ),
                        if (hasUnread)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  user?.name ?? 'Unknown User',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (lastMessage != null)
                                Text(
                                  formatTime(lastMessage.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasUnread
                                        ? AppColors.primaryBlue
                                        : Colors.grey[500],
                                    fontWeight: hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lastMessage?.messageText ??
                                      'Start a conversation',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: hasUnread
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primary.withOpacity(0.8)
                                        : Colors.grey[500],
                                    fontWeight: hasUnread
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasUnread)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unreadCount > 99
                                        ? '99+'
                                        : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[300],
          child: Icon(Icons.person, color: Colors.grey[500]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 200,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
