import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/task/task_detail_screen.dart';
import '../screens/task/create_task_screen.dart';
import '../screens/task/task_list_screen.dart';
import '../screens/chat/chat_room_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';

class AppRoutes {
  // ─── Route Names ─────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String map = '/map';
  static const String taskDetail = '/task/detail';
  static const String createTask = '/task/create';
  static const String taskList = '/task/list';
  static const String chatRoom = '/chat/room';
  static const String chatList = '/chat/list';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  // ─── Route Map ───────────────────────────────────────────────────────────────
  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        home: (_) => const HomeScreen(),
        map: (_) => const MapScreen(),
        taskList: (_) => const TaskListScreen(),
        createTask: (_) => const CreateTaskScreen(),
        chatList: (_) => const ChatListScreen(),
        profile: (_) => const ProfileScreen(),
        editProfile: (_) => const EditProfileScreen(),
      };

  // ─── Dynamic Routes ──────────────────────────────────────────────────────────
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case taskDetail:
        final taskId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => TaskDetailScreen(taskId: taskId),
          settings: settings,
        );
      case chatRoom:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            roomId: args['roomId'] as String,
            taskTitle: args['taskTitle'] as String? ?? 'Chat',
            otherUserName: args['otherUserName'] as String? ?? '',
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Halaman tidak ditemukan')),
          ),
        );
    }
  }
}
