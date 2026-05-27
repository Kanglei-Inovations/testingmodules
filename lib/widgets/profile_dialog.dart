import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../features/connection/controller/connection_controller.dart';
import '../services/database_service.dart';
import '../utils/theme_colors.dart';
import '../widgets/cyber_button.dart';

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key});

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  final ConnectionController controller = Get.find();
  final DatabaseService db = Get.find();
  final TextEditingController nameController = TextEditingController();
  String? _tempPhotoPath;

  @override
  void initState() {
    super.initState();
    nameController.text = controller.localUser?.name ?? "";
    _tempPhotoPath = controller.localUser?.profilePhotoPath;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _tempPhotoPath = image.path);
    }
  }

  Future<void> _updateProfile() async {
    if (controller.localUser == null) return;
    
    final user = controller.localUser!;
    user.name = nameController.text.trim();
    user.profilePhotoPath = _tempPhotoPath;
    user.updatedAt = DateTime.now();

    await db.saveUser(user);
    controller.localUser = user;
    controller.update(); // Update observers
    Get.back();
    Get.snackbar("SYSTEM UPDATE", "Neural Identity Synchronized", 
      backgroundColor: ThemeColors.neonCyan.withOpacity(0.3), colorText: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: ThemeColors.darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: ThemeColors.neonPurple, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("MANAGE IDENTITY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 30),
          _buildPhotoPicker(),
          const SizedBox(height: 30),
          _buildNameInput(),
          const SizedBox(height: 40),
          CyberButton(
            label: "UPDATE PROTOCOL",
            color: ThemeColors.neonPurple,
            onPressed: _updateProfile,
            fullWidth: true,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ThemeColors.neonCyan, width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white10,
              backgroundImage: _tempPhotoPath != null ? FileImage(File(_tempPhotoPath!)) : null,
              child: _tempPhotoPath == null ? const Icon(Icons.person, color: ThemeColors.neonCyan, size: 40) : null,
            ),
          ),
          Positioned(bottom: 0, right: 0, child: const Icon(Icons.add_a_photo, color: ThemeColors.neonPink, size: 20)),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return TextField(
      controller: nameController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "NEURAL ALIAS",
        labelStyle: const TextStyle(color: Colors.white24, fontSize: 10),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: ThemeColors.neonCyan.withOpacity(0.3))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: ThemeColors.neonCyan)),
      ),
    );
  }
}
