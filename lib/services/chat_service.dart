import '../core/api_config.dart';
import '../models/message.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  Future<List<ChatRoom>> getRooms() async {
    final response = await _api.get(ApiConfig.chatRooms);
    final list = response['rooms'] ?? response['data'] ?? response;
    if (list is List) {
      return list
          .map((e) => ChatRoom.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Message>> getMessages(String roomId, {int page = 1}) async {
    final response = await _api.get(
      ApiConfig.roomMessages(roomId),
      params: {
        'page': page.toString(),
        'limit': '50',
      },
    );
    final list = response['messages'] ?? response['data'] ?? response;
    if (list is List) {
      return list
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return [];
  }

  Future<ChatRoom> createRoom(String taskId, String otherUserId) async {
    final response = await _api.post(ApiConfig.chatRooms, {
      'taskId': taskId,
      'otherUserId': otherUserId,
    });
    final data = response['room'] ?? response['data'] ?? response;
    return ChatRoom.fromJson(data as Map<String, dynamic>);
  }
}
