import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/utils.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/price_offer_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String taskTitle;
  final String otherUserName;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.taskTitle,
    required this.otherUserName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showOfferField = false;
  final _offerPriceController = TextEditingController();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    final chatProvider = context.read<ChatProvider>();
    chatProvider.joinRoom(widget.roomId);
    chatProvider.loadMessages(widget.roomId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _offerPriceController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    context.read<ChatProvider>().leaveRoom(widget.roomId);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    context.read<ChatProvider>().sendMessage(widget.roomId, content);
    _messageController.clear();
    _scrollToBottom();
  }

  void _sendOffer() {
    final priceText = _offerPriceController.text.trim();
    if (priceText.isEmpty) return;

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan harga yang valid')),
      );
      return;
    }

    final content = 'Tawaran: ${formatRupiah(price)}';
    context.read<ChatProvider>().sendMessage(
          widget.roomId,
          content,
          offerPrice: price,
        );
    _offerPriceController.clear();
    setState(() => _showOfferField = false);
    _scrollToBottom();
  }

  void _onTyping() {
    _typingTimer?.cancel();
    context.read<ChatProvider>().emitTyping(widget.roomId);
    _typingTimer = Timer(const Duration(seconds: 2), () {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.taskTitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'offer') setState(() => _showOfferField = true);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'offer',
                child: Row(
                  children: [
                    Icon(Icons.local_offer_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Kirim Tawaran Harga',
                        style: TextStyle(fontFamily: 'Poppins')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Messages ────────────────────────────────────────────────────
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (_, chatProvider, __) {
                final messages = chatProvider.messagesForRoom(widget.roomId);
                final isLoading = chatProvider.isLoadingMessages(widget.roomId);
                final isTyping = chatProvider.isTypingInRoom(widget.roomId);

                if (isLoading && messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryBlue),
                  );
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined,
                            size: 56, color: AppTheme.textHint),
                        const SizedBox(height: 12),
                        const Text('Mulai percakapan', style: AppTheme.body2),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length + (isTyping ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (isTyping && i == messages.length) {
                      return _buildTypingIndicator();
                    }

                    final message = messages[i];
                    final isMine = message.senderId == currentUser?.id;

                    // Group messages by date
                    final showDateHeader = i == 0 ||
                        !_isSameDay(
                            messages[i - 1].createdAt, message.createdAt);

                    return Column(
                      children: [
                        if (showDateHeader)
                          _buildDateHeader(message.createdAt),
                        if (message.isOffer)
                          PriceOfferBubble(
                            message: message,
                            isMine: isMine,
                            onRespond: !isMine && message.offerPending
                                ? (status) {
                                    chatProvider.respondOffer(
                                        message.id, status);
                                  }
                                : null,
                          )
                        else if (message.isSystem)
                          _buildSystemMessage(message)
                        else
                          _buildMessageBubble(message, isMine),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ─── Offer Price Input ────────────────────────────────────────────
          if (_showOfferField)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppTheme.accentOrange.withOpacity(0.3)),
                  bottom: BorderSide(color: AppTheme.divider),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined,
                      color: AppTheme.accentOrange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _offerPriceController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Harga tawaran (Rp)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _showOfferField = false),
                    child: const Text('Batal',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  ElevatedButton(
                    onPressed: _sendOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Kirim'),
                  ),
                ],
              ),
            ),

          // ─── Input Bar ────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Offer button
                  IconButton(
                    onPressed: () =>
                        setState(() => _showOfferField = !_showOfferField),
                    icon: Icon(
                      Icons.local_offer_outlined,
                      color: _showOfferField
                          ? AppTheme.accentOrange
                          : AppTheme.textSecondary,
                    ),
                    tooltip: 'Kirim Tawaran',
                  ),

                  // Text input
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGrey,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => _onTyping(),
                        decoration: const InputDecoration(
                          hintText: 'Ketik pesan...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppTheme.textHint,
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isMine ? 80 : 16,
          right: isMine ? 16 : 80,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: isMine ? Colors.white : AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatTime(message.createdAt),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: isMine
                    ? Colors.white.withOpacity(0.7)
                    : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(Message message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.content,
          style: AppTheme.caption,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              formatDate(date),
              style: AppTheme.caption,
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'mengetik',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 4),
            _DotAnimation(),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DotAnimation extends StatefulWidget {
  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = (i / 3);
            final value = (_controller.value - offset).abs();
            final opacity = value < 0.5 ? 1.0 : 0.3;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
