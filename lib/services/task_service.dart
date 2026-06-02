import '../core/api_config.dart';
import '../models/task.dart';
import 'api_service.dart';

class TaskService {
  final ApiService _api = ApiService();

  // ─── Query ───────────────────────────────────────────────────────────────────

  Future<List<Task>> getNearbyTasks({
    double? lat,
    double? lng,
    double radius = ApiConfig.defaultRadius,
    String? category,
    String? status,
    int page = 1,
    int limit = ApiConfig.pageSize,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (lat != null) params['lat'] = lat.toString();
    if (lng != null) params['lng'] = lng.toString();
    params['radius'] = radius.toString();
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await _api.get(ApiConfig.tasks, params: params);
    final list = response['tasks'] ?? response['data'] ?? response;
    if (list is List) {
      return list
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Task>> getMyPostedTasks() async {
    final response = await _api.get(ApiConfig.myPostedTasks);
    final list = response['tasks'] ?? response['data'] ?? response;
    if (list is List) {
      return list
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Task>> getMyAppliedTasks() async {
    final response = await _api.get(ApiConfig.myAppliedTasks);
    final list = response['tasks'] ?? response['data'] ?? response;
    if (list is List) {
      return list
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Task> getTask(String id) async {
    final response = await _api.get(ApiConfig.taskById(id));
    final data = response['task'] ?? response['data'] ?? response;
    return Task.fromJson(data as Map<String, dynamic>);
  }

  // ─── Create ──────────────────────────────────────────────────────────────────

  Future<Task> createTask({
    required String title,
    required String description,
    required String category,
    required double budgetMin,
    required double budgetMax,
    required String locationAddress,
    double? lat,
    double? lng,
    DateTime? scheduledAt,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'category': category,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'locationAddress': locationAddress,
    };
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;
    if (scheduledAt != null) body['scheduledAt'] = scheduledAt.toIso8601String();

    final response = await _api.post(ApiConfig.tasks, body);
    final data = response['task'] ?? response['data'] ?? response;
    return Task.fromJson(data as Map<String, dynamic>);
  }

  // ─── Applications ─────────────────────────────────────────────────────────────

  Future<TaskApplication> applyToTask(
    String taskId, {
    required double proposedPrice,
    String? message,
  }) async {
    final body = <String, dynamic>{'proposedPrice': proposedPrice};
    if (message != null && message.isNotEmpty) body['message'] = message;

    final response = await _api.post(ApiConfig.applyTask(taskId), body);
    final data = response['application'] ?? response['data'] ?? response;
    return TaskApplication.fromJson(data as Map<String, dynamic>);
  }

  Future<List<TaskApplication>> getTaskApplications(String taskId) async {
    final response = await _api.get(ApiConfig.taskApplications(taskId));
    final list = response['applications'] ?? response['data'] ?? response;
    if (list is List) {
      return list
          .map((e) => TaskApplication.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ─── Status Updates ──────────────────────────────────────────────────────────

  Future<Task> acceptWorker(String taskId, String workerId) async {
    final response =
        await _api.put(ApiConfig.acceptWorker(taskId, workerId), {});
    final data = response['task'] ?? response['data'] ?? response;
    return Task.fromJson(data as Map<String, dynamic>);
  }

  Future<Task> completeTask(String taskId) async {
    final response = await _api.put(ApiConfig.completeTask(taskId), {});
    final data = response['task'] ?? response['data'] ?? response;
    return Task.fromJson(data as Map<String, dynamic>);
  }
}
