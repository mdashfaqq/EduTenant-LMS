import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import './database/database_helper.dart';
import './services/api/session_service.dart';
import './services/sync_status_service.dart';
import 'core/app_export.dart';
import 'widgets/network_wrapper.dart';
import 'package:provider/provider.dart';
import 'core/theme_controller.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseHelper.instance.database;

  // Initialize session storage
  await SessionService.instance.init();

  // Initialize sync status service
  SyncStatusService.instance;

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
  ChangeNotifierProvider(
    create: (_) => ThemeController(),
    child: const MyApp(),
  ),
);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'Edutenant LMS',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: context.watch<ThemeController>().themeMode,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
builder: (context, child) {
  return MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(1.0)),
    child: NetworkWrapper(
      child: child!,
    ),
  );
},

          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
        );
      },
    );
  }
}
