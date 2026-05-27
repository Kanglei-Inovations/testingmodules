import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundSyncHandler());
}

class BackgroundSyncHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('Background Sync Handler Started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    // This is where we will trigger sync logic in the background isolate
    // We will eventually need to re-initialize a minimal version of the DB/Sync engine here
    FlutterForegroundTask.updateService(
      notificationTitle: 'NEURAL LINK ACTIVE',
      notificationText: 'Last Sync: ${DateTime.now().hour}:${DateTime.now().minute}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print('Background Sync Handler Destroyed');
  }
}

class BackgroundService extends GetxService {
  void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'neural_sync_channel',
        channelName: 'Neural Sync Service',
        channelDescription: 'Maintains P2P connectivity and data synchronization.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), // Every 5 seconds
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }

    // Request permissions
    if (Platform.isAndroid) {
      if (!await Permission.notification.isGranted) {
        await Permission.notification.request();
      }
    }

    final ServiceRequestResult result = await FlutterForegroundTask.startService(
      notificationTitle: 'NEURAL LINK ACTIVE',
      notificationText: 'Synchronizing Protocol Stream...',
      callback: startCallback,
    );

    return result is ServiceRequestSuccess;
  }

  Future<bool> stopService() async {
    final result = await FlutterForegroundTask.stopService();
    return result is ServiceRequestSuccess;
  }
}
