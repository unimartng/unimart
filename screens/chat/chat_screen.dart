// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:unimart/constants/app_colors.dart';
import 'package:unimart/widgets/loading_widget.dart';
import 'package:flutter/services.dart';

import '../../services/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../profile/user_profile_screen.dart';

class ChatBubble extends StatefulWidget {
  final String text;
  final bool isMe;
  final DateTime time;
  final int index;
  final MessageModel? repliedMessage;
  final VoidCallback? onReply;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
    required this.index,
    this.repliedMessage,
    this.onReply,
    this.onLongPress,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: widget.isMe ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Start animation with a slight delay based on index
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Align(
          alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: widget.onLongPress,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 200),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: widget.isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: widget.isMe
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primaryBlue,
                                      AppColors.primaryBlue.withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: widget.isMe
                                ? null
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: widget.isMe
                                  ? const Radius.circular(20)
                                  : const Radius.circular(6),
                              bottomRight: widget.isMe
                                  ? const Radius.circular(6)
                                  : const Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: widget.isMe
                                ? null
                                : Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1,
                                  ),
                          ),
                          child: Column(
                            crossAxisAlignment: widget.isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              // Reply section
                              if (widget.repliedMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: widget.isMe
                                        ? Colors.white.withOpacity(0.2)
                                        : AppColors.primaryBlue.withOpacity(
                                            0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(
                                      left: BorderSide(
                                        color: widget.isMe
                                            ? Colors.white
                                            : AppColors.primaryBlue,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.repliedMessage!.senderId ==
                                                widget.isMe.toString()
                                            ? 'You'
                                            : 'Other User',
                                        style: TextStyle(
                                          color: widget.isMe
                                              ? Colors.white
                                              : AppColors.primaryBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          widget.repliedMessage!.messageText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Main message
                              Text(
                                widget.text,
                                style: GoogleFonts.inter(
                                  color: widget.isMe
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${widget.time.hour.toString().padLeft(2, '0')}:${widget.time.minute.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.inter(
                                      color: widget.isMe
                                          ? Colors.white70
                                          : Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  if (widget.isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.done_all,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  final String userName;

  const TypingIndicator({super.key, required this.userName});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: 0.7 + (_animation.value * 0.3),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, size: 16, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.userName} is typing',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        height: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(3, (index) {
                            return AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                final delay = index * 0.2;
                                final animValue =
                                    (_animationController.value - delay).clamp(
                                      0.0,
                                      1.0,
                                    );
                                return Transform.translate(
                                  offset: Offset(
                                    0,
                                    -4 * sin(animValue * 3.14159),
                                  ),
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ReplyPreview extends StatelessWidget {
  final MessageModel repliedMessage;
  final VoidCallback onCancel;

  const ReplyPreview({
    super.key,
    required this.repliedMessage,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(
          color: AppColors.primaryBlue, // Use a single color for all sides
          width: 3,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to:',
                  style: GoogleFonts.inter(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  repliedMessage.messageText,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onCancel,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late String _currentUserId;
  UserModel? _otherUser;
  final bool _otherUserTyping = false;
  MessageModel? _replyingTo;
  late AnimationController _fadeController;
  late AnimationController _sendButtonController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sendButtonAnimation;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _currentUserId = user?.id ?? '';

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _sendButtonAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.elasticOut),
    );

    _fetchOtherUser();
    _markMessagesAsRead();

    // Start fade in animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sendButtonController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    await SupabaseService.instance.markMessagesAsRead(
      widget.chatId,
      _currentUserId,
    );
  }

  Future<void> _fetchOtherUser() async {
    final chatParts = widget.chatId.split('_');
    String otherUserId = chatParts[0] == _currentUserId
        ? chatParts[1]
        : chatParts[0];
    final user = await SupabaseService.instance.getUserProfile(otherUserId);
    setState(() {
      _otherUser = user;
    });
  }

  void _showMessageOptions(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.reply, color: AppColors.primaryBlue),
              title: Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyingTo = message;
                });
                _focusNode.requestFocus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.messageText));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    margin: const EdgeInsets.all(12),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    content: Text(
                      'Message copied!',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
            if (message.senderId == _currentUserId)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement delete functionality
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _sendButtonController.forward().then((_) {
      _sendButtonController.reverse();
    });

    final supabaseUid = SupabaseService.instance.currentUser?.id;
    if (supabaseUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must be logged in to send messages.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final message = MessageModel(
      id: '',
      chatId: widget.chatId,
      senderId: _currentUserId,
      receiverId: _otherUser?.id ?? '',
      messageText: text,
      createdAt: DateTime.now(),
      isRead: false,
      replyToMessageId: _replyingTo?.id, // <-- Pass reply reference here
    );

    await SupabaseService.instance.sendMessage(message);
    _controller.clear();
    setState(() {
      _replyingTo = null;
    });
  }

  Future<bool> _onWillPop() async {
    await _markMessagesAsRead();
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          toolbarHeight: 65,
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 22,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_otherUser != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfileScreen(
                                    userId: _otherUser!.id,
                                    userName: _otherUser!.name,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              Hero(
                                tag: 'avatar_${widget.chatId}',
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundImage:
                                        _otherUser?.profilePhotoUrl != null
                                        ? NetworkImage(
                                            _otherUser!.profilePhotoUrl!,
                                          )
                                        : null,
                                    child: _otherUser?.profilePhotoUrl == null
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.white70,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _otherUser?.name ?? 'User',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Online',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.call, color: Colors.white),
              onPressed: () {
                // Implement call functionality
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                if (value == 'clear_chat') {
                  await SupabaseService.instance.clearChat(widget.chatId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      margin: EdgeInsets.all(12),
                      behavior: SnackBarBehavior.floating,
                      // ignore: use_build_context_synchronously
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      content: Text(
                        'Chat cleared!',
                        style: GoogleFonts.poppins(
                          // ignore: use_build_context_synchronously
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                  setState(() {}); // Refresh the UI
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'clear_chat',
                  child: Text('Clear chat'),
                ),
              ],
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWideScreen = constraints.maxWidth > 700;
              return Center(
                child: SizedBox(
                  width: isWideScreen ? 600 : double.infinity,
                  child: Column(
                    children: [
                      Expanded(
                        child: StreamBuilder<List<MessageModel>>(
                          stream: SupabaseService.instance.subscribeToMessages(
                            widget.chatId,
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: LoadingIndicator(message: 'Loading...'),
                              );
                            }
                            final messages = snapshot.data!;
                            if (messages.isEmpty) {
                              return Center(
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 1000),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_outline,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Start a conversation',
                                              style: GoogleFonts.inter(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'Send a message to get started',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                            return ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message =
                                    messages[messages.length - 1 - index];
                                final isMe = message.senderId == _currentUserId;

                                // Find the replied message if any
                                MessageModel? repliedMessage;
                                if (message.replyToMessageId != null) {
                                  repliedMessage = messages.firstWhere(
                                    (m) => m.id == message.replyToMessageId,
                                    orElse: () => MessageModel(
                                      id: '',
                                      chatId: '',
                                      senderId: '',
                                      receiverId: '',
                                      messageText: '',
                                      createdAt: DateTime.now(),
                                      isRead: false,
                                    ),
                                  );
                                  if (repliedMessage.id == '') {
                                    repliedMessage = null;
                                  }
                                }

                                return ChatBubble(
                                  text: message.messageText,
                                  isMe: isMe,
                                  time: message.createdAt,
                                  index: index < 5 ? index : 0,
                                  repliedMessage: repliedMessage,
                                  onLongPress: () =>
                                      _showMessageOptions(message),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      SafeArea(
                        child: Column(
                          children: [
                            if (_otherUserTyping)
                              SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(-1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _fadeController,
                                        curve: Curves.easeOutBack,
                                      ),
                                    ),
                                child: TypingIndicator(
                                  userName: _otherUser?.name ?? "User",
                                ),
                              ),
                            if (_replyingTo != null)
                              ReplyPreview(
                                repliedMessage: _replyingTo!,
                                onCancel: () {
                                  setState(() {
                                    _replyingTo = null;
                                  });
                                },
                              ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              color: Theme.of(context).colorScheme.surface,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.tertiary,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: _controller,
                                        focusNode: _focusNode,
                                        decoration: InputDecoration(
                                          hintText: 'Type a message...',
                                          hintStyle: GoogleFonts.inter(
                                            color: Colors.grey[500],
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 12,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          fillColor: Theme.of(
                                            context,
                                          ).colorScheme.tertiary,
                                          suffixIcon: IconButton(
                                            icon: const Icon(
                                              Icons.emoji_emotions_outlined,
                                            ),
                                            color: Colors.grey[500],
                                            onPressed: () {
                                              // Implement emoji picker
                                            },
                                          ),
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                        maxLines: null,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ScaleTransition(
                                    scale: _sendButtonAnimation,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primaryBlue,
                                            AppColors.primaryBlue.withOpacity(
                                              0.8,
                                            ),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryBlue
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                        ),
                                        onPressed: _sendMessage,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
