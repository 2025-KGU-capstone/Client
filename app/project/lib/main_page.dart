import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'capture_page.dart';
import 'fcm_check_page.dart';
import 'notification_check_page.dart';
import 'visitor_check_page.dart';
import 'visitor_registration_page.dart';
import 'mypage.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const MyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        elevation: 0,
        title: const Text(" ", style: TextStyle(color: Colors.white)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Get.to(() => NotificationHistoryPage());
            },
          ),
        ],
      ),
      drawer: _buildDrawer(), // 드로어 표시
      body: _pages[_selectedIndex],
      bottomNavigationBar: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 10,
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
            ),
          ),
          BottomNavigationBar(
            iconSize: 30,
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blueAccent,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
            ],
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircleAvatar(radius: 40),
                SizedBox(height: 10),
                Text(
                  "Welcome, User",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera, color: Colors.blueAccent),
                  title: const Text("Image Capture"),
                  onTap: () {
                    Navigator.pop(context);
                    Get.to(() => CaptureImageApp());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.orange),
                  title: const Text("FCM Check"),
                  onTap: () {
                    Navigator.pop(context);
                    Get.to(() => FCMCheckPage());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.green),
                  title: const Text("Settings"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("App Version: 1.0.0", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

// 홈 화면 내용
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          const Text(
            "비대면으로 내 택배를 관리해보세요",
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 30),
          Image.asset(
            'assets/main_illustration.png',
            height: 180,
          ),
          const SizedBox(height: 50),
          ElevatedButton.icon(
            onPressed: () {
              Get.to(() => CaptureImageApp());
            },
            icon: const Icon(Icons.videocam),
            label: const Text("실시간 확인"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 80),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Get.to(() => VisitorCheckPage());
            },
            icon: const Icon(Icons.person_search),
            label: const Text("방문자 등록 확인"),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 80),
              side: const BorderSide(color: Colors.blueAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
