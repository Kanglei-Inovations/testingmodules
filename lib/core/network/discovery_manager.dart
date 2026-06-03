import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:isar/isar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../services/database_service.dart';
import '../../data/collections/peer_session_collection.dart';

class DiscoveryManager extends GetxService {
  final DatabaseService _db = Get.find<DatabaseService>();
  final String _serviceType = '_neurallink._tcp.local';
  
  MDnsClient? _mdnsClient;
  
  // PeerID -> { "ip": IP, "name": Name, "lastSeen": Timestamp }
  final discoveredNodes = <String, Map<String, dynamic>>{}.obs; 
  final discoveryStatus = "IDLE".obs;
  
  Function(String peerId, String ip)? onKnownPeerDiscovered;

  bool _isBroadcasting = false;
  bool _isScanning = false;
  
  String? _localPeerId;

  // Sockets and Timers for robust lifecycle management
  RawDatagramSocket? _broadcastSocket;
  RawDatagramSocket? _listenerSocket;
  Timer? _broadcastTimer;
  Timer? _stalePeerTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _initConnectivityListener();
    _startStalePeerTimer();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        print("[DEBUG-DISCOVERY] Network change detected: $results. Restarting discovery...");
        _restartDiscovery();
      }
    });
  }

  void _startStalePeerTimer() {
    _stalePeerTimer?.cancel();
    _stalePeerTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final staleKeys = <String>[];
      
      discoveredNodes.forEach((id, data) {
        final lastSeen = data["lastSeen"] as int;
        if (now - lastSeen > 30000) { // 30 seconds timeout
          staleKeys.add(id);
        }
      });

      if (staleKeys.isNotEmpty) {
        print("[DEBUG-DISCOVERY] Pruning ${staleKeys.length} stale peers.");
        for (final key in staleKeys) {
          discoveredNodes.remove(key);
        }
        discoveredNodes.refresh();
      }
    });
  }

  Future<void> _restartDiscovery() async {
    final wasScanning = _isScanning;
    final wasBroadcasting = _isBroadcasting;
    
    stopDiscovery();
    discoveredNodes.clear();
    
    if (wasScanning) await startDiscovery();
    if (wasBroadcasting && _localPeerId != null) {
      final user = await _db.getUser();
      if (user != null) {
        await startBroadcast(user.peerId, user.name);
      }
    }
  }

  Future<void> startDiscovery() async {
    if (_isScanning) return;
    _isScanning = true;
    discoveryStatus.value = "SCANNING";
    
    final user = await _db.getUser();
    _localPeerId = user?.peerId;
    
    _mdnsClient = MDnsClient();
    await _mdnsClient!.start();

    print("[DEBUG-DISCOVERY] mDNS Scanning started.");

    // Listen for Neural Link services
    try {
      await for (final PtrResourceRecord ptr in _mdnsClient!.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer(_serviceType))) {
        
        await for (final SrvResourceRecord srv in _mdnsClient!.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName))) {
          
          await for (final IPAddressResourceRecord ip in _mdnsClient!.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {
            
            final peerId = ptr.domainName.split('.').first;
            
            // Skip self
            if (peerId == _localPeerId) continue;
            
            _updateDiscoveredNode(peerId, ip.address.address, "Neural Node");
          }
        }
      }
    } catch (e) {
      print("[DEBUG-DISCOVERY] mDNS Lookup Error: $e");
    }
  }

  Future<void> startBroadcast(String peerId, String name) async {
    if (_isBroadcasting) return;
    _isBroadcasting = true;
    _localPeerId = peerId;
    discoveryStatus.value = "BROADCASTING";

    print("[DEBUG-DISCOVERY] LAN Broadcast started for $peerId ($name)");
    _startUdpAnnouncer(peerId, name);
  }

  Future<void> _startUdpAnnouncer(String peerId, String name) async {
    try {
      final broadcastSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      if (!_isBroadcasting) {
        broadcastSocket.close();
        return;
      }
      _broadcastSocket = broadcastSocket;
      _broadcastSocket!.broadcastEnabled = true;
      
      _broadcastTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        final data = "NEURAL_LINK_NODE:$peerId:${Uri.encodeComponent(name)}";
        _broadcastSocket?.send(data.codeUnits, InternetAddress("255.255.255.255"), 5555);
      });

      final listenerSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5555);
      if (!_isBroadcasting) {
        listenerSocket.close();
        return;
      }
      _listenerSocket = listenerSocket;
      _listenerSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = _listenerSocket!.receive();
          if (dg != null) {
            final message = String.fromCharCodes(dg.data);
            if (message.startsWith("NEURAL_LINK_NODE:")) {
              final parts = message.split(":");
              if (parts.length >= 3) {
                final id = parts[1];
                final peerName = Uri.decodeComponent(parts[2]);
                
                // Skip self
                if (id == _localPeerId) return;
                
                _updateDiscoveredNode(id, dg.address.address, peerName);
              }
            }
          }
        }
      });
    } catch (e) {
      print("[DEBUG-DISCOVERY] UDP Socket Error: $e");
      _isBroadcasting = false;
      _broadcastSocket?.close();
      _broadcastSocket = null;
      _listenerSocket?.close();
      _listenerSocket = null;
    }
  }

  void _updateDiscoveredNode(String peerId, String ip, String name) {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (!discoveredNodes.containsKey(peerId)) {
      discoveredNodes[peerId] = {
        "ip": ip, 
        "name": name, 
        "lastSeen": now
      };
      print("[DEBUG-DISCOVERY] Node Added: $peerId ($name) at $ip");
      _checkAndNotifyKnownPeer(peerId, ip);
    } else {
      // Update existing node
      discoveredNodes[peerId]!["lastSeen"] = now;
      if (discoveredNodes[peerId]!["ip"] != ip || discoveredNodes[peerId]!["name"] != name) {
        discoveredNodes[peerId]!["ip"] = ip;
        discoveredNodes[peerId]!["name"] = name;
        discoveredNodes.refresh();
      }
    }
  }

  Future<void> _checkAndNotifyKnownPeer(String peerId, String ip) async {
    final session = await _db.isar.peerSessionCollections.filter().peerIdEqualTo(peerId).findFirst();
    if (session != null) {
      print("[DEBUG-DISCOVERY] Known Peer $peerId discovered at $ip. Triggering Auto-Sync.");
      if (onKnownPeerDiscovered != null) {
        onKnownPeerDiscovered!(peerId, ip);
      }
    }
  }

  void stopDiscovery() {
    print("[DEBUG-DISCOVERY] Stopping discovery resources...");
    _mdnsClient?.stop();
    _isScanning = false;
    discoveryStatus.value = "IDLE";
    
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    
    _broadcastSocket?.close();
    _broadcastSocket = null;
    
    _listenerSocket?.close();
    _listenerSocket = null;
    
    _isBroadcasting = false;
  }

  @override
  void onClose() {
    stopDiscovery();
    _stalePeerTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
