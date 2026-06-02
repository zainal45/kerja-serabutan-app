import 'user.dart';
import 'task.dart';

class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final String type; // 'text' | 'offer' | 'image' | 'system'
  final double? offerPrice;
  final String? offerStatus; // 'pending' | 'accepted' | 'rejected'
  final DateTime createdAt;
  final User? sender;

  const Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.offerPrice,
    this.offerStatus,
    this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ??
          json['sender']?['_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      offerPrice: (json['offerPrice'] as num?)?.toDouble(),
      offerStatus: json['offerStatus']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sender: json['sender'] is Map<String, dynamic>
          ? User.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'senderId': senderId,
        'content': content,
        'type': type,
        if (offerPrice != null) 'offerPrice': offerPrice,
        if (offerStatus != null) 'offerStatus': offerStatus,
        'createdAt': createdAt.toIso8601String(),
      };

  bool get isOffer => type == 'offer';
  bool get isText => type == 'text';
  bool get isSystem => type == 'system';
  bool get offerPending => offerStatus == 'pending';
  bool get offerAccepted => offerStatus == 'accepted';
  bool get offerRejected => offerStatus == 'rejected';

  Message copyWith({String? offerStatus}) {
    return Message(
      id: id,
      roomId: roomId,
      senderId: senderId,
      content: content,
      type: type,
      offerPrice: offerPrice,
      offerStatus: offerStatus ?? this.offerStatus,
      createdAt: createdAt,
      sender: sender,
    );
  }

  @override
  bool operator ==(Object other) => other is Message && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class ChatRoom {
  final String id;
  final String taskId;
  final String clientId;
  final String workerId;
  final Task? task;
  final User? otherUser;
  final Message? lastMessage;
  final int unreadCount;

  const ChatRoom({
    required this.id,
    required this.taskId,
    required this.clientId,
    required this.workerId,
    this.task,
    this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ??
          json['task']?['_id']?.toString() ?? '',
      clientId: json['clientId']?.toString() ??
          json['client']?['_id']?.toString() ?? '',
      workerId: json['workerId']?.toString() ??
          json['worker']?['_id']?.toString() ?? '',
      task: json['task'] is Map<String, dynamic>
          ? Task.fromJson(json['task'] as Map<String, dynamic>)
          : null,
      otherUser: json['otherUser'] is Map<String, dynamic>
          ? User.fromJson(json['otherUser'] as Map<String, dynamic>)
          : null,
      lastMessage: json['lastMessage'] is Map<String, dynamic>
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  ChatRoom copyWith({Message? lastMessage, int? unreadCount}) {
    return ChatRoom(
      id: id,
      taskId: taskId,
      clientId: clientId,
      workerId: workerId,
      task: task,
      otherUser: otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  bool operator ==(Object other) => other is ChatRoom && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
