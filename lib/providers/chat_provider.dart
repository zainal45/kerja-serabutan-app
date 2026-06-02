import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService();

  List<ChatRoom> _rooms = [];
  final Map<String, List<Message>> _messages = {};
  final Map<String, bool> _isTyping = {};
  bool _isLoadingRooms = false;
  final Map<String, bool> _isLoadingMessages = {};
  String? _errorMessage;

  List<ChatRoom> get rooms => _rooms;
  Map<String, List<Message>> get allMessages => _messages;
  bool get isLoadingRooms => _isLoadingRooms;
  String? get errorMessage => _errorMessage;

  List<Message> messagesForRoom(String roomId) =>
      _messages[roomId] ?? [];

  bool isLoadingMessages(String roomId) =>
      _isLoadingMessages[roomId] ?? false;

  bool isTypingInRoom(String roomId) => _isTyping[roomId] ?? false;

  int get totalUnread =>
      _rooms.fold(0, (sum, r) => sum + r.unreadCount);

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Socket Setup ─────────────────────────────────────────────────────────────

  void setupSocketListeners() {
    _socketService.addMessageListener(_onNewMessage);
    _socketService.addOfferListener(_onOfferUpdated);
    _socketService.addTypingListener(_onUserTyping);
  }

  void removeSocketListeners() {
    _socketService.removeMessageListener(_onNewMessage);
    _socketService.removeOfferListener(_onOfferUpdated);
    _socketService.removeTypingListener(_onUserTyping);
  }

  void _onNewMessage(Message message) {
    addIncomingMessage(message);
  }

  void _onOfferUpdated(Map<String, dynamic> data) {
    final messageId = data['messageId']?.toString();
    final status = data['status']?.toString();
    if (messageId == null || status == null) return;

    for (final roomId in _messages.keys) {
      final msgs = _messages[roomId]!;
      final idx = msgs.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        _messages[roomId]![idx] = msgs[idx].copyWith(offerStatus: status);
        notifyListeners();
        break;
      }
    }
  }

  void _onUserTyping(String roomId, String userId) {
    _isTyping[roomId] = true;
    notifyListeners();
    // Reset typing indicator after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _isTyping[roomId] = false;
      notifyListeners();
    });
  }

  // ─── Rooms ────────────────────────────────────────────────────────────────────

  Future<void> loadRooms() async {
    _isLoadingRooms = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _rooms = await _chatService.getRooms();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Gagal memuat daftar chat';
    } finally {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  // ─── Messages ─────────────────────────────────────────────────────────────────

  Future<void> loadMessages(String roomId) async {
    _isLoadingMessages[roomId] = true;
    notifyListeners();
    try {
      final msgs = await _chatService.getMessages(roomId);
      _messages[roomId] = msgs;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Gagal memuat pesan';
    } finally {
      _isLoadingMessages[roomId] = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(
    String roomId,
    String content, {
    double? offerPrice,
  }) async {
    final type = offerPrice != null ? 'offer' : 'text';
    _socketService.sendMessage(
      roomId,
      content,
      type: type,
      offerPrice: offerPrice,
    );
    // Optimistic update not done here — wait for new_message event from server
  }

  void addIncomingMessage(Message message) {
    final roomId = message.roomId;
    if (!_messages.containsKey(roomId)) {
      _messages[roomId] = [];
    }

    // Avoid duplicates
    final exists = _messages[roomId]!.any((m) => m.id == message.id);
    if (!exists) {
      _messages[roomId]!.add(message);
      // Sort by time
      _messages[roomId]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    // Update room's last message
    final roomIdx = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIdx != -1) {
      _rooms[roomIdx] = _rooms[roomIdx].copyWith(lastMessage: message);
    }

    notifyListeners();
  }

  // ─── Create Room ─────────────────────────────────────────────────────────────

  Future<ChatRoom?> createRoom(String taskId, String otherUserId) async {
    try {
      // Check if room already exists
      final existing = _rooms.where((r) => r.taskId == taskId).toList();
      if (existing.isNotEmpty) return existing.first;

      final room = await _chatService.createRoom(taskId, otherUserId);
      _rooms = [room, ..._rooms];
      notifyListeners();
      return room;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Gagal membuat ruang chat';
      notifyListeners();
      return null;
    }
  }

  // ─── Offer Response ──────────────────────────────────────────────────────────

  void respondOffer(String messageId, String status) {
    _socketService.respondOffer(messageId, status);
  }

  void emitTyping(String roomId) {
    _socketService.emitTyping(roomId);
  }

  void joinRoom(String roomId) {
    _socketService.joinRoom(roomId);
  }

  void leaveRoom(String roomId) {
    _socketService.leaveRoom(roomId);
  }
}
