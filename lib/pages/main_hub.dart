import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/theme_colors.dart';
import 'home_page.dart';
import 'chat_page.dart';
import 'files_page.dart';
import 'peers_page.dart';
import 'settings_page.dart';

class MainHub extends StatefulWidget {
  const MainHub({super.key});

  @override
  State<MainHub> createState() => _MainHubState();
}

class _MainHubState extends State<MainHub> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    const ChatPage(),
    const FilesPage(),
    const PeersPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.darkBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.darkBg,
        border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        boxShadow: [
          BoxShadow(color: ThemeColors.neonPurple.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 1),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ThemeColors.neonCyan,
        unselectedItemColor: Colors.white24,
        selectedLabelStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
        unselectedLabelStyle: const TextStyle(fontSize: 8, letterSpacing: 1),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Chats"),
          BottomNavigationBarItem(icon: Icon(Icons.file_copy_rounded), label: "Files"),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: "Peers"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.darkBg,
      body: const Center(
        child: Text(
          "PROFILE SETTINGS",
          style: TextStyle(color: Colors.white24, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
        ),
      ),
    );
  }
}
