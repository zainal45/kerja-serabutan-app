/// Central configuration for API endpoints and socket connection.
/// Override at build time: flutter build apk --dart-define=API_BASE_URL=https://...
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Default search radius in kilometers for nearby tasks/workers.
  static const double defaultRadius = 10.0;

  /// Number of items per page for paginated requests.
  static const int pageSize = 20;

  /// Connection timeout duration in seconds.
  static const int timeoutSeconds = 30;

  // ─── Auth ───────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // ─── Users ──────────────────────────────────────────────────────────────────
  static const String userProfile = '/users/profile';
  static const String nearbyWorkers = '/users/nearby';
  static String userById(String id) => '/users/$id';
  static String userReviews(String id) => '/users/$id/reviews';

  // ─── Tasks ──────────────────────────────────────────────────────────────────
  static const String tasks = '/tasks';
  static const String myPostedTasks = '/tasks/my/posted';
  static const String myAppliedTasks = '/tasks/my/applied';
  static String taskById(String id) => '/tasks/$id';
  static String applyTask(String id) => '/tasks/$id/apply';
  static String taskApplications(String id) => '/tasks/$id/applications';
  static String acceptWorker(String taskId, String workerId) =>
      '/tasks/$taskId/accept/$workerId';
  static String completeTask(String id) => '/tasks/$id/complete';

  // ─── Chat ───────────────────────────────────────────────────────────────────
  static const String chatRooms = '/chat/rooms';
  static String roomMessages(String roomId) => '/chat/rooms/$roomId/messages';

  // ─── Reviews ────────────────────────────────────────────────────────────────
  static const String reviews = '/reviews';
}
