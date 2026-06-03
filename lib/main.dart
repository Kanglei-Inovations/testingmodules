import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'pages/splash_screen.dart';
import 'pages/main_hub.dart';
import 'utils/theme_colors.dart';
import 'core/network/discovery_manager.dart';
import 'core/network/webrtc_manager.dart';
import 'core/network/transport_manager.dart';
import 'core/network/call_manager.dart';
import 'features/connection/controller/connection_controller.dart';
import 'services/database_service.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/sync/sync_engine.dart';
import 'features/connection/controller/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print("[DEBUG-MAIN] Starting Services Initialization...");
    
    // 1. Initialize Database
    final dbService = DatabaseService();
    await dbService.init();
    await dbService.pruneData(); // Clean up old data on boot
    Get.put(dbService, permanent: true);
    print("[DEBUG-MAIN] Database Ready.");

    // 2. Initialize Notifications
    Get.put(NotificationService(), permanent: true);
    print("[DEBUG-MAIN] Notifications Ready.");

    // 3. Initialize Sync Engine
    Get.put(SyncEngine(), permanent: true);
    print("[DEBUG-MAIN] Sync Engine Ready.");

    // 4. Initialize Network Stack
    Get.put(DiscoveryManager(), permanent: true);
    Get.put(TransportManager(), permanent: true);
    Get.put(WebRtcManager(), permanent: true);
    final callManager = CallManager();
    await callManager.init();
    Get.put(callManager, permanent: true);
    print("[DEBUG-MAIN] Network Stack Ready.");

    // 4. Initialize Background Service
    final bgService = BackgroundService();
    bgService.initForegroundTask();
    Get.put(bgService, permanent: true);
    print("[DEBUG-MAIN] Background Service Ready.");

    // 5. Initialize Global Settings
    Get.put(SettingsController(), permanent: true);
    print("[DEBUG-MAIN] Settings Ready.");

    // 6. Initialize Neural Connection Controller (UI Bridge)
    Get.put(ConnectionController(), permanent: true);
    print("[DEBUG-MAIN] UI Bridge Ready.");
    
    runApp(const NeuralLinkApp());
  } catch (e, stack) {
    print("[FATAL-ERROR] Initialization failed: $e");
    print(stack);
    // Even if init fails, try to show an error app instead of just closing
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text("FATAL BOOT ERROR:\n$e", style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
          ),
        ),
      ),
    ));
  }
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
