import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'pages/splash_screen.dart';
import 'pages/main_hub.dart';
import 'utils/theme_colors.dart';
import 'features/connection/controller/settings_controller.dart';
import 'features/connection/controller/connection_controller.dart';
import 'services/database_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Database
  final dbService = DatabaseService();
  await dbService.init();
  Get.put(dbService, permanent: true);

  // 2. Initialize Background Service
  final bgService = BackgroundService();
  bgService.initForegroundTask();
  Get.put(bgService, permanent: true);

  // 3. Initialize Global Settings
  Get.put(SettingsController(), permanent: true);

  // 4. Initialize Neural Connection Controller
  Get.put(ConnectionController(), permanent: true);
  
  runApp(const NeuralLinkApp());
}

class NeuralLinkApp extends StatelessWidget {
  const NeuralLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: GetMaterialApp(
        title: 'Neural Link P2P',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: ThemeColors.neonCyan,
          fontFamily: 'Inter',
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        getPages: [
          GetPage(name: '/hub', page: () => const MainHub()),
        ],
      ),
    );
  }
}
