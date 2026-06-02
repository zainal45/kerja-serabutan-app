import '../core/api_config.dart';
import '../models/user.dart';
import '../models/review.dart';
import 'api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  Future<User> getProfile() async {
    final response = await _api.get(ApiConfig.userProfile);
    final data = response['user'] ?? response['data'] ?? response;
    return User.fromJson(data as Map<String, dynamic>);
  }

  Future<User> updateProfile({
    String? name,
    String? phone,
    String? bio,
    String? locationName,
    double? lat,
    double? lng,
    List<String>? skills,
    String? avatarPath,
  }) async {
    final fields = <String, String>{};
    if (name != null) fields['name'] = name;
    if (phone != null) fields['phone'] = phone;
    if (bio != null) fields['bio'] = bio;
    if (locationName != null) fields['locationName'] = locationName;
    if (lat != null) fields['lat'] = lat.toString();
    if (lng != null) fields['lng'] = lng.toString();
    if (skills != null) {
      // Send skills as JSON string for multipart
      fields['skills'] = skills.join(',');
    }

    if (avatarPath != null) {
      final response = await _api.putMultipart(
        ApiConfig.userProfile,
        fields: fields,
        filePaths: {'avatar': avatarPath},
      );
      final data = response['user'] ?? response['data'] ?? response;
      return User.fromJson(data as Map<String, dynamic>);
    } else {
      // Use regular JSON PUT if no file upload
      final body = <String, dynamic>{...fields};
      if (skills != null) body['skills'] = skills;
      final response = await _api.put(ApiConfig.userProfile, body);
      final data = response['user'] ?? response['data'] ?? response;
      return User.fromJson(data as Map<String, dynamic>);
    }
  }

  Future<List<User>> getNearbyWorkers({
    required double lat,
    required double lng,
    double radius = ApiConfig.defaultRadius,
  }) async {
    final response = await _api.get(ApiConfig.nearbyWorkers, params: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius': radius.toString(),
    });
    final list = response['workers'] ?? response['users'] ?? response['data'] ?? response;
    if (list is List) {
      return list
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<User> getPublicProfile(String userId) async {
    final response = await _api.get(ApiConfig.userById(userId));
    final data = response['user'] ?? response['data'] ?? response;
    return User.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Review>> getUserReviews(String userId) async {
    final response = await _api.get(ApiConfig.userReviews(userId));
    final list = response['reviews'] ?? response['data'] ?? response;
    if (list is List) {
      return list
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Review> postReview({
    required String revieweeId,
    required String taskId,
    required int rating,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'revieweeId': revieweeId,
      'taskId': taskId,
      'rating': rating,
    };
    if (comment != null && comment.isNotEmpty) body['comment'] = comment;

    final response = await _api.post(ApiConfig.reviews, body);
    final data = response['review'] ?? response['data'] ?? response;
    return Review.fromJson(data as Map<String, dynamic>);
  }
}
