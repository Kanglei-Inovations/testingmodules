import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../data/collections/peer_session_collection.dart';
import '../features/connection/controller/connection_controller.dart';
import '../services/database_service.dart';
import '../utils/theme_colors.dart';
import '../widgets/mesh_background.dart';

class PeersPage extends StatefulWidget {
  const PeersPage({super.key});

  @override
  State<PeersPage> createState() => _PeersPageState();
}

class _PeersPageState extends State<PeersPage> {
  final DatabaseService _db = Get.find<DatabaseService>();
  final ConnectionController _controller = Get.find<ConnectionController>();
  
  List<PeerSessionCollection> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPeers();
  }

  Future<void> _loadPeers() async {
    setState(() => _isLoading = true);
    final sessions = await _db.isar.peerSessionCollections.where().sortByLastConnectedAtDesc().findAll();
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          MeshBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: ThemeColors.neonPurple))
                    : _buildPeerList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "KNOWN NODES",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          Text(
            "${_sessions.length} identities in your neural registry",
            style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerList() {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 16),
            const Text("Registry is empty", style: TextStyle(color: Colors.white24, letterSpacing: 2)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPeers,
      color: ThemeColors.neonPurple,
      backgroundColor: ThemeColors.darkBg,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final lastSeen = _formatLastSeen(session.lastSeen);
          final isOnline = session.sessionState == SessionState.online;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: ThemeColors.glassBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isOnline ? ThemeColors.terminalGreen.withValues(alpha: 0.3) : Colors.white10),
            ),
            child: ListTile(
              onTap: () {
                _controller.activePeerSession.value = session;
                _controller.resumeSession(session.peerId);
              },
              leading: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isOnline ? ThemeColors.terminalGreen : Colors.white10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22.5),
                      child: session.peerPhoto != null && File(session.peerPhoto!).existsSync()
                          ? Image.file(File(session.peerPhoto!), fit: BoxFit.cover)
                          : const Icon(Icons.person, color: Colors.white24),
                    ),
                  ),
                  if (isOnline)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: ThemeColors.terminalGreen, shape: BoxShape.circle, border: Border.all(color: ThemeColors.darkBg, width: 2)),
                    ),
                ],
              ),
              title: Text(session.peerName ?? "Unknown Node", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text("Last Pulse: $lastSeen", style: const TextStyle(color: Colors.white24, fontSize: 10)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white10),
            ),
          );
        },
      ),
    );
  }

  String _formatLastSeen(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}
