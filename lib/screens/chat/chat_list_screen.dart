import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/app_theme.dart';
import '../../core/routes.dart';
import '../../providers/chat_provider.dart';
import '../../models/message.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<ChatProvider>(
        builder: (_, chatProvider, __) {
          if (chatProvider.isLoadingRooms) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            );
          }

          if (chatProvider.rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 72,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(height: 16),
                  const Text('Belum ada percakapan', style: AppTheme.subtitle2),
                  const SizedBox(height: 8),
                  const Text(
                    'Mulai chat dari halaman detail tugas',
                    style: AppTheme.body2,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => chatProvider.loadRooms(),
            color: AppTheme.primaryBlue,
            child: ListView.separated(
              itemCount: chatProvider.rooms.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 80),
              itemBuilder: (_, i) {
                final room = chatProvider.rooms[i];
                return _ChatRoomTile(room: room);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoom room;

  const _ChatRoomTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final otherUser = room.otherUser;
    final lastMsg = room.lastMessage;
    final avatarUrl = otherUser?.avatarUrl;
    final name = otherUser?.name ?? 'Pengguna';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.chatRoom,
        arguments: {
          'roomId': room.id,
          'taskTitle': room.task?.title ?? 'Tugas',
          'otherUserName': name,
        },
      ),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: avatarUrl != null
                ? CachedNetworkImageProvider(avatarUrl)
                : null,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  )
                : null,
          ),
          if (otherUser?.isOnline == true)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.statusOpen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lastMsg != null)
            Text(
              timeago.format(lastMsg.createdAt, locale: 'id'),
              style: AppTheme.caption,
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (room.task?.title != null)
            Text(
              room.task!.title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (lastMsg != null)
            Text(
              lastMsg.type == 'offer'
                  ? 'Tawaran harga dikirim'
                  : lastMsg.content,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: room.unreadCount > 0
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontWeight: room.unreadCount > 0
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: room.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${room.unreadCount}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}
