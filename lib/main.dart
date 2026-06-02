import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'core/app_theme.dart';
import 'core/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for mobile-first experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Indonesian date locale
  await initializeDateFormatting('id', null);

  // Register Indonesian timeago messages
  timeago.setLocaleMessages('id', timeago.IdMessages());

  runApp(const KerjaSerabutanApp());
}

class KerjaSerabutanApp extends StatelessWidget {
  const KerjaSerabutanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Kerja Serabutan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,

        // Localization (Indonesian)
        locale: const Locale('id', 'ID'),
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],

        // Routes
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,

        // Builder for global handling
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
