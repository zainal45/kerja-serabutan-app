import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/api_config.dart';
import '../models/message.dart';

typedef MessageCallback = void Function(Message message);
typedef OfferCallback = void Function(Map<String, dynamic> data);
typedef TypingCallback = void Function(String roomId, String userId);

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;

  final List<MessageCallback> _messageListeners = [];
  final List<OfferCallback> _offerListeners = [];
  final List<TypingCallback> _typingListeners = [];

  // ─── Connection ───────────────────────────────────────────────────────────────

  void connect(String token) {
    if (_isConnected) return;

    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    _socket!.onConnectError((err) {
      _isConnected = false;
    });

    // ─── Listen for incoming events ──────────────────────────────────────────────

    _socket!.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        final message = Message.fromJson(data);
        for (final cb in List.of(_messageListeners)) {
          cb(message);
        }
      }
    });

    _socket!.on('offer_updated', (data) {
      if (data is Map<String, dynamic>) {
        for (final cb in List.of(_offerListeners)) {
          cb(data);
        }
      }
    });

    _socket!.on('user_typing', (data) {
      if (data is Map<String, dynamic>) {
        final roomId = data['roomId']?.toString() ?? '';
        final userId = data['userId']?.toString() ?? '';
        for (final cb in List.of(_typingListeners)) {
          cb(roomId, userId);
        }
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _messageListeners.clear();
    _offerListeners.clear();
    _typingListeners.clear();
  }

  bool get isConnected => _isConnected;

  // ─── Room Management ─────────────────────────────────────────────────────────

  void joinRoom(String roomId) {
    _socket?.emit('join_room', {'roomId': roomId});
  }

  void leaveRoom(String roomId) {
    _socket?.emit('leave_room', {'roomId': roomId});
  }

  // ─── Emit Events ─────────────────────────────────────────────────────────────

  void sendMessage(
    String roomId,
    String content, {
    String type = 'text',
    double? offerPrice,
  }) {
    final payload = <String, dynamic>{
      'roomId': roomId,
      'content': content,
      'type': type,
    };
    if (offerPrice != null) payload['offer_price'] = offerPrice;
    _socket?.emit('send_message', payload);
  }

  void respondOffer(String messageId, String status) {
    // status: 'accepted' | 'rejected'
    _socket?.emit('respond_offer', {
      'messageId': messageId,
      'status': status,
    });
  }

  void emitTyping(String roomId) {
    _socket?.emit('typing', {'roomId': roomId});
  }

  // ─── Event Listeners ─────────────────────────────────────────────────────────

  void addMessageListener(MessageCallback callback) {
    if (!_messageListeners.contains(callback)) {
      _messageListeners.add(callback);
    }
  }

  void removeMessageListener(MessageCallback callback) {
    _messageListeners.remove(callback);
  }

  void addOfferListener(OfferCallback callback) {
    if (!_offerListeners.contains(callback)) {
      _offerListeners.add(callback);
    }
  }

  void removeOfferListener(OfferCallback callback) {
    _offerListeners.remove(callback);
  }

  void addTypingListener(TypingCallback callback) {
    if (!_typingListeners.contains(callback)) {
      _typingListeners.add(callback);
    }
  }

  void removeTypingListener(TypingCallback callback) {
    _typingListeners.remove(callback);
  }
}
