import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../data/collections/user_collection.dart';
import '../utils/theme_colors.dart';
import '../widgets/cyber_button.dart';
import 'home_page.dart';

class UserSetupPage extends StatefulWidget {
  const UserSetupPage({super.key});

  @override
  State<UserSetupPage> createState() => _UserSetupPageState();
}

class _UserSetupPageState extends State<UserSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  String? _photoPath;
  double _lat = 0;
  double _lng = 0;
  final String _peerId = "NODE-${const Uuid().v4().substring(0, 8).toUpperCase()}";
  bool _isLoadingGps = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _photoPath = image.path);
    }
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoadingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'GPS hardware is disabled. Please enable it in system settings.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        addLog("Requesting GPS permission...");
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are required to establish Grid Sector.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: ThemeColors.darkBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: ThemeColors.neonPink)),
            title: const Text("PERMISSION REQUIRED", style: TextStyle(color: Colors.white, fontSize: 16)),
            content: const Text("Location permissions are permanently denied. Please enable them in app settings to sync coordinates.", style: TextStyle(color: Colors.white70, fontSize: 12)),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
              CyberButton(
                label: "OPEN SETTINGS",
                color: ThemeColors.neonPink,
                onPressed: () {
                  Geolocator.openAppSettings();
                  Get.back();
                },
                height: 40,
              ),
            ],
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(_lat, _lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() => _addressController.text = "${p.locality}, ${p.country}");
      }
    } catch (e) {
      Get.snackbar(
        "NEURAL LINK ERROR",
        e.toString(),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.3),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isLoadingGps = false);
    }
  }

  void addLog(String msg) {
    Get.find<DatabaseService>().saveLog(msg, level: "DEBUG");
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    final db = Get.find<DatabaseService>();
    final user = UserCollection()
      ..name = _nameController.text
      ..phone = _phoneController.text
      ..address = _addressController.text
      ..latitude = _lat
      ..longitude = _lng
      ..profilePhotoPath = _photoPath
      ..peerId = _peerId
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await db.saveUser(user);
    Get.offAllNamed('/hub');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.darkBg,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildPhotoPicker(),
                  const SizedBox(height: 30),
                  _buildPeerIdCard(),
                  const SizedBox(height: 30),
                  _buildInputFields(),
                  const SizedBox(height: 20),
                  _buildLocationCard(),
                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          "IDENTITY REGISTRATION",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
        ),
        Text(
          "ESTABLISH LOCAL NODE FINGERPRINT",
          style: TextStyle(color: ThemeColors.neonPink, fontSize: 8, letterSpacing: 2),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ThemeColors.neonCyan, width: 2),
              boxShadow: [BoxShadow(color: ThemeColors.neonCyan.withValues(alpha: 0.2), blurRadius: 15)],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white10,
              backgroundImage: _photoPath != null && File(_photoPath!).existsSync()
                  ? FileImage(File(_photoPath!)) 
                  : null,
              child: _photoPath == null || !File(_photoPath!).existsSync()
                  ? const Icon(Icons.add_a_photo_outlined, color: ThemeColors.neonCyan, size: 30) 
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: ThemeColors.neonCyan, shape: BoxShape.circle),
              child: const Icon(Icons.edit, color: Colors.black, size: 14),
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildPeerIdCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("PROTOCOL ID", style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1)),
          Text(_peerId, style: const TextStyle(color: ThemeColors.neonPurple, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        _CyberTextField(controller: _nameController, label: "NEURAL ALIAS", icon: Icons.person_outline_rounded),
        const SizedBox(height: 15),
        _CyberTextField(controller: _phoneController, label: "COMM LINK", icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
        const SizedBox(height: 15),
        _CyberTextField(controller: _addressController, label: "GRID SECTOR", icon: Icons.map_outlined),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ThemeColors.glassBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ThemeColors.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (_isLoadingGps)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: ThemeColors.neonCyan))
          else
            const Icon(Icons.gps_fixed_rounded, color: ThemeColors.neonCyan, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("GEOSPATIAL COORDINATES", style: TextStyle(color: Colors.white30, fontSize: 8)),
                Text(_lat != 0 ? "$_lat, $_lng" : "LOCKING SATELLITE...", style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
              ],
            ),
          ),
          IconButton(onPressed: _determinePosition, icon: const Icon(Icons.refresh_rounded, color: ThemeColors.neonCyan, size: 18)),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _saveUser,
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(colors: [ThemeColors.neonCyan, ThemeColors.neonPurple.withValues(alpha: 0.8)]),
          boxShadow: [BoxShadow(color: ThemeColors.neonCyan.withValues(alpha: 0.2), blurRadius: 20)],
        ),
        alignment: Alignment.center,
        child: const Text("INITIALIZE NODE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 3)),
      ),
    ).animate().fadeIn(delay: 800.ms);
  }
}

class _CyberTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;

  const _CyberTextField({required this.controller, required this.label, required this.icon, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 10),
          prefixIcon: Icon(icon, color: ThemeColors.neonPink, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
