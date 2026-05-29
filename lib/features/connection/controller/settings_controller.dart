import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../../../services/database_service.dart';
import '../../../data/collections/stun_collection.dart';
import 'package:isar/isar.dart';

class SettingsController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();
  SharedPreferences? _prefs;
  
  // Observables
  var stunServers = <StunCollection>[].obs;
  var smartNetworkMode = true.obs;
  var activeStunUrls = <String>["stun:stun.l.google.com:19302"].obs;
  
  // Boot sequence status
  var isStunTesting = false.obs;
  var currentTestingServer = "".obs;

  // WebRTC Settings
  var chunkSize = 16384.obs;
  var compressionQuality = 70.obs;
  var reconnectInterval = 5.obs;
  var keepAliveInterval = 15.obs;

  // P2P Settings
  var localDiscovery = true.obs;
  var ipv6Enabled = false.obs;
  var dhtExperimental = false.obs;

  // Encryption
  var encryptionEnabled = true.obs;
  var devicePeerId = "NODE-IDLE".obs;

  // Background Sync
  var isBatteryOptimized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initAsync();
  }

  Future<void> _initAsync() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadStunServers();
    await _loadGeneralSettings();
    await checkBatteryOptimization();
  }

  Future<void> checkBatteryOptimization() async {
    isBatteryOptimized.value = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
  }

  Future<void> requestBatteryOptimization() async {
    final success = await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    if (success) {
      isBatteryOptimized.value = true;
    }
  }

  Future<void> _loadStunServers() async {
    final stuns = await _db.getStuns();
    if (stuns.isEmpty) {
      final defaults = [
        StunCollection()..url = 'stun:stun.l.google.com:19302'..isEnabled = true,
        StunCollection()..url = 'stun:stun1.l.google.com:19302'..isEnabled = true,
        StunCollection()..url = 'stun:stun.services.mozilla.com'..isEnabled = true,
        StunCollection()..url = 'stun:stun.nextcloud.com:443'..isEnabled = true,
        StunCollection()..url = 'stun:stunprotocol.org'..isEnabled = true,
      ];
      for (var s in defaults) {
        await _db.saveStun(s);
      }
      stunServers.assignAll(defaults);
    } else {
      stunServers.assignAll(stuns);
    }
    _updateActiveStunUrls();
  }

  Future<void> _loadGeneralSettings() async {
    if (_prefs == null) return;
    smartNetworkMode.value = _prefs!.getBool('smart_network') ?? true;
    chunkSize.value = _prefs!.getInt('chunk_size') ?? 16384;
    compressionQuality.value = _prefs!.getInt('comp_quality') ?? 70;
    
    final user = await _db.getUser();
    if (user != null) {
      devicePeerId.value = user.peerId;
    }
  }

  void _updateActiveStunUrls() {
    final enabled = stunServers.where((s) => s.isEnabled).map((s) => s.url).toList();
    if (enabled.isNotEmpty) {
      activeStunUrls.value = enabled;
    } else {
      activeStunUrls.value = ["stun:stun.l.google.com:19302"];
    }
  }

  /// Specialized boot sequence to optimize network paths for the session.
  Future<void> performNeuralBootSync() async {
    isStunTesting.value = true;
    
    // 1. Run real speed tests
    for (var server in stunServers) {
      if (!server.isEnabled) continue;
      currentTestingServer.value = server.url.replaceFirst("stun:", "");
      
      try {
        final stopwatch = Stopwatch()..start();
        final host = currentTestingServer.value.split(':').first;
        final address = await InternetAddress.lookup(host).timeout(const Duration(seconds: 1));
        if (address.isNotEmpty) {
          server.latency = stopwatch.elapsedMilliseconds;
        }
      } catch (_) {
        server.latency = 9999;
      }
      stunServers.refresh();
      await Future.delayed(const Duration(milliseconds: 100)); // Visual spacing
    }

    // 2. Select top 2 for this session
    final valid = stunServers.where((s) => s.isEnabled && (s.latency ?? 9999) < 5000).toList();
    if (valid.isNotEmpty) {
      valid.sort((a, b) => (a.latency ?? 9999).compareTo(b.latency ?? 9999));
      final top2 = valid.take(2).map((s) => s.url).toList();
      activeStunUrls.value = top2;
    }

    isStunTesting.value = false;
  }

  void toggleStun(StunCollection stun, bool enabled) async {
    stun.isEnabled = enabled;
    await _db.saveStun(stun);
    stunServers.refresh();
    _updateActiveStunUrls();
  }

  Future<void> addStun(String url) async {
    if (!url.startsWith("stun:")) url = "stun:$url";
    final stun = StunCollection()..url = url..isEnabled = true;
    await _db.saveStun(stun);
    await _loadStunServers();
  }

  Future<void> deleteStun(int id) async {
    await _db.deleteStun(id);
    await _loadStunServers();
  }

  Future<void> runStunSpeedTest() async {
    await performNeuralBootSync();
  }

  void toggleSmartMode(bool val) {
    smartNetworkMode.value = val;
    _prefs?.setBool('smart_network', val);
    if (val) runStunSpeedTest();
  }
}
