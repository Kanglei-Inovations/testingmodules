import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../utils/theme_colors.dart';
import '../widgets/mesh_background.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  List<File> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> entities = directory.listSync();
      final List<File> files = entities
          .whereType<File>()
          .where((f) => !f.path.split(Platform.pathSeparator).last.startsWith('temp_'))
          .toList();
      
      // Sort by modified date
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading files: $e");
      setState(() => _isLoading = false);
    }
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
                    ? const Center(child: CircularProgressIndicator(color: ThemeColors.neonCyan))
                    : _buildFileList(),
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
            "NEURAL STORAGE",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          Text(
            "${_files.length} verified packets stored locally",
            style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 16),
            const Text("Vault is empty", style: TextStyle(color: Colors.white24, letterSpacing: 2)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFiles,
      color: ThemeColors.neonCyan,
      backgroundColor: ThemeColors.darkBg,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          final name = file.path.split(Platform.pathSeparator).last;
          final size = (file.lengthSync() / 1024 / 1024).toStringAsFixed(2);
          final ext = name.split('.').last.toUpperCase();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: ThemeColors.glassBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: ListTile(
              onTap: () => OpenFilex.open(file.path),
              leading: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(ext, style: const TextStyle(color: ThemeColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text("$size MB", style: const TextStyle(color: Colors.white24, fontSize: 10)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white10),
            ),
          );
        },
      ),
    );
  }
}
