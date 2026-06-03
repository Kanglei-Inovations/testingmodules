import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/collections/message_collection.dart';
import '../data/collections/peer_collection.dart';
import '../data/collections/log_collection.dart';
import '../data/collections/user_collection.dart';
import '../data/collections/peer_session_collection.dart';
import '../data/collections/stun_collection.dart';

import '../data/collections/sync_queue_collection.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundSyncHandler());
}

class BackgroundSyncHandler extends TaskHandler {
  Isar? _isar;
  int _syncCount = 0;
  String _nodeStatus = "IDLE";

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('Background Sync Handler Started');
    try {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [
          MessageCollectionSchema,
          PeerCollectionSchema,
          LogCollectionSchema,
          UserCollectionSchema,
          PeerSessionCollectionSchema,
          StunCollectionSchema,
          SyncQueueCollectionSchema,
        ],
        directory: dir.path,
      );
      print('Headless Isar Initialized');
    } catch (e) {
      print('Headless Isar Init Error: $e');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    if (_isar != null) {
      // 1. Monitor Pending Sync Queue
      final pendingCount = await _isar!.syncQueueCollections.count();
      _syncCount = pendingCount;
      
      // 2. Peer Stale Detection (Logic from DiscoveryManager but for background)
      final activeSessions = await _isar!.peerSessionCollections
          .filter()
          .sessionStateEqualTo(SessionState.online)
          .findAll();
      
      final now = DateTime.now();
      int staleCount = 0;
      for (var session in activeSessions) {
        if (now.difference(session.lastSeen).inSeconds > 45) {
          staleCount++;
          // Mark as stale in background if needed
        }
      }

      _nodeStatus = pendingCount > 0 ? "SYNCING ($pendingCount)" : (activeSessions.isNotEmpty ? "ACTIVE NODES: ${activeSessions.length}" : "IDLE");
    }
    
    FlutterForegroundTask.updateService(
      notificationTitle: 'NEURAL LINK: $_nodeStatus',
      notificationText: 'Last Pulse: ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _isar?.close();
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
