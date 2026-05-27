import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../features/connection/controller/connection_controller.dart';
import '../utils/theme_colors.dart';
import '../services/database_service.dart';
import '../data/collections/log_collection.dart';
import 'package:isar/isar.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final ConnectionController controller = Get.find();
  final DatabaseService db = Get.find();
  List<LogCollection> logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
    db.watchLogsLazy().listen((_) => _loadLogs());
  }

  Future<void> _loadLogs() async {
    final list = await db.isar.logCollections.where().sortByTimestampDesc().findAll();
    if (mounted) setState(() => logs = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "SYSTEM PROTOCOL MONITOR",
          style: TextStyle(color: ThemeColors.terminalGreen, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: ThemeColors.terminalGreen),
        actions: [
          IconButton(
            onPressed: () => controller.reset(),
            icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          final time = "${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}";
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              "[$time] ${log.message}",
              style: const TextStyle(
                color: ThemeColors.terminalGreen,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          );
        },
      ),
    );
  }
}
