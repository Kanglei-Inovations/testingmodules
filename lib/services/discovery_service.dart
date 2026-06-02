import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:isar/isar.dart';
import '../services/database_service.dart';
import '../data/collections/user_collection.dart';
import '../data/collections/peer_session_collection.dart';

class DiscoveryService extends GetxService {
  final DatabaseService _db = Get.find<DatabaseService>();
  final String _serviceType = '_neurallink._tcp.local';
  
  MDnsClient? _mdnsClient;
  // PeerID -> { "ip": IP, "name": Name }
  final discoveredNodes = <String, Map<String, String>>{}.obs; 
  
  Function(String peerId, String ip)? onKnownPeerDiscovered;

  bool _isBroadcasting = false;
  bool _isScanning = false;
  
  String? _localPeerId;

  Future<void> startDiscovery() async {
    if (_isScanning) return;
    _isScanning = true;
    
    final user = await _db.getUser();
    _localPeerId = user?.peerId;
    
    _mdnsClient = MDnsClient();
    await _mdnsClient!.start();

    // Listen for Neural Link services
    await for (final PtrResourceRecord ptr in _mdnsClient!.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(_serviceType))) {
      
      await for (final SrvResourceRecord srv in _mdnsClient!.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName))) {
        
        await for (final IPAddressResourceRecord ip in _mdnsClient!.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target))) {
          
          final peerId = ptr.domainName.split('.').first;
          
          // Skip self
          if (peerId == _localPeerId) continue;
          
          discoveredNodes[peerId] = {"ip": ip.address.address, "name": "Neural Node"};
          print("DEBUG: Discovered Node: $peerId at ${ip.address.address}");
          
          // Check if this is a known peer
          _checkAndNotifyKnownPeer(peerId, ip.address.address);
        }
      }
    }
  }

  Future<void> startBroadcast(String peerId, String name) async {
    if (_isBroadcasting) return;
    _isBroadcasting = true;
    _localPeerId = peerId;

    // For Phase 7, we'll start with a UDP Announcer for simplicity and reliability in Flutter.
    _startUdpAnnouncer(peerId, name);
  }

  void _startUdpAnnouncer(String peerId, String name) async {
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((RawDatagramSocket socket) {
      socket.broadcastEnabled = true;
      Timer.periodic(const Duration(seconds: 5), (timer) {
        // Broadcast both ID and Name safely
        final data = "NEURAL_LINK_NODE:$peerId:${Uri.encodeComponent(name)}";
        socket.send(data.codeUnits, InternetAddress("255.255.255.255"), 5555);
      });
    });

    // Also listen for broadcasts
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 5555).then((RawDatagramSocket socket) {
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = socket.receive();
          if (dg != null) {
            final message = String.fromCharCodes(dg.data);
            if (message.startsWith("NEURAL_LINK_NODE:")) {
              final parts = message.split(":");
              if (parts.length >= 3) {
                final id = parts[1];
                final peerName = Uri.decodeComponent(parts[2]);
                
                // Skip self
                if (id == _localPeerId) return;
                
                if (!discoveredNodes.containsKey(id)) {
                  discoveredNodes[id] = {"ip": dg.address.address, "name": peerName};
                  print("DEBUG: UDP Discovered Node: $id ($peerName) at ${dg.address.address}");
                  _checkAndNotifyKnownPeer(id, dg.address.address);
                } else if (discoveredNodes[id]!["name"] != peerName) {
                  // Update name if changed
                  discoveredNodes[id]!["name"] = peerName;
                  discoveredNodes.refresh();
                }
              }
            }
          }
        }
      });
    });
  }

  Future<void> _checkAndNotifyKnownPeer(String peerId, String ip) async {
    final session = await _db.isar.peerSessionCollections.filter().peerIdEqualTo(peerId).findFirst();
    if (session != null) {
      print("DEBUG: Known Peer $peerId discovered at $ip. Triggering Auto-Sync.");
      if (onKnownPeerDiscovered != null) {
        onKnownPeerDiscovered!(peerId, ip);
      }
    }
  }

  void stopDiscovery() {
    _mdnsClient?.stop();
    _isScanning = false;
  }
}
