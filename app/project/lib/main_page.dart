import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_project/visitor_combined_page.dart';
import 'capture_page.dart';
import 'fcm_check_page.dart';
import 'notification_check_page.dart';
import 'mypage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

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
      drawer: _buildDrawer(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
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
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSafetyModeOn = false;
  String ngrokUrl = "Fetching...";

  void initState() {
    super.initState();
    fetchNgrokUrl();
  }


  Future<void> sendAlert() async {
    final url = Uri.parse('$ngrokUrl/pir');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print('sent successfully');
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchNgrokUrl() async {
    final ref = FirebaseDatabase.instance.ref("server/ngrok_url");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      setState(() {
        ngrokUrl = snapshot.value as String;
      });
    } else {
      setState(() {
        ngrokUrl = "No URL found in Firebase";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          const Text(
            "비대면으로\n내 택배를 관리해보세요",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 24),

          Image.asset(
            'assets/main_illustration.png',
            height: 220,
          ),

          const SizedBox(height: 40),

          ElevatedButton.icon(
            onPressed: () {
              Get.to(() => CaptureImageApp());
            },
            icon: const Icon(Icons.videocam, size: 32),
            label: const Text(
              "실시간 확인",
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 70),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () {
              Get.to(() => VisitorCombinedPage());
            },
            icon: const Icon(Icons.person_search, size: 28),
            label: const Text(
              "방문자 등록 / 확인",
              style: TextStyle(fontSize: 18),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 70),
              side: const BorderSide(color: Colors.blueAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "안전모드",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Switch(
                value: isSafetyModeOn,
                onChanged: (value) {
                  setState(() {
                    isSafetyModeOn = value;
                    sendAlert();
                  });
                },
                activeColor: Colors.green,
              ),
            ],
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
