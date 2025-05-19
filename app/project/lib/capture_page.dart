import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'image_preview_page.dart';

class CaptureImageApp extends StatefulWidget {
  @override
  _CaptureImageAppState createState() => _CaptureImageAppState();
}

class _CaptureImageAppState extends State<CaptureImageApp> {
  String image1Base64 = "";
  String image2Base64 = "";
  DateTime? captureTime;
  bool isLoading = false;
  String ngrokUrl = "Fetching...";

  final _pageController = PageController();
  int _currentPage = 0;

  late Timer _timer;
  String _currentTime = "";

  @override
  void initState() {
    super.initState();
    fetchNgrokUrl();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now().toLocal(); // KST
    final formatter = DateFormat('yyyy / MM / dd / HH : mm : ss');
    setState(() {
      _currentTime = formatter.format(now);
    });
  }

  Future<bool> checkStreamAvailable(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
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

  Future<void> fetchImages() async {
    final url = Uri.parse('$ngrokUrl/capture_images');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            image1Base64 = data['image1'];
            image2Base64 = data['image2'];
            captureTime = DateTime.now();
          });
        } else {
          print("Error: ${data['message']}");
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> sendAlert() async {
    final url = Uri.parse('$ngrokUrl/Alert');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print('Alert sent successfully');
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending alert: $e');
    }
  }

  Widget buildLiveStream(String streamUrl) {
    return Stack(
      children: [
        // ✅ MJPEG 실시간 스트림
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Mjpeg(
            stream: streamUrl,
            isLive: true,
          ),
        ),

        // 🔴 LIVE 뱃지
        Positioned(
          top: 8,
          left: 8,
          child: Row(
            children: [
              Icon(Icons.circle, color: Colors.red, size: 10),
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text("LIVE",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // 🕒 현재 시각 (오른쪽 상단)
        Positioned(
          top: 8,
          right: 8,
          child: Text(
            _currentTime,
            style: const TextStyle(color: Colors.black, fontSize: 12),
          ),
        ),

        // 🟨 노란 테두리 효과 (4모서리)
        ...[
          Alignment.topLeft,
          Alignment.topRight,
          Alignment.bottomLeft,
          Alignment.bottomRight,
        ].map(
              (align) => Align(
            alignment: align,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  top: align == Alignment.topLeft ||
                      align == Alignment.topRight
                      ? BorderSide(color: Colors.yellow, width: 4)
                      : BorderSide.none,
                  left: align == Alignment.topLeft ||
                      align == Alignment.bottomLeft
                      ? BorderSide(color: Colors.yellow, width: 4)
                      : BorderSide.none,
                  bottom: align == Alignment.bottomLeft ||
                      align == Alignment.bottomRight
                      ? BorderSide(color: Colors.yellow, width: 4)
                      : BorderSide.none,
                  right: align == Alignment.topRight ||
                      align == Alignment.bottomRight
                      ? BorderSide(color: Colors.yellow, width: 4)
                      : BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreamWithCheck(String url) {
    return FutureBuilder<bool>(
      future: checkStreamAvailable(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || snapshot.data == false) {
          return Center(child: Text("⚠️ 스트림에 연결할 수 없습니다."));
        } else {
          return buildLiveStream(url);
        }
        return buildLiveStream(url);
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF5E70FF),
        title: Text("실시간 확인"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 이미지 뷰 (비율 조정된 PageView)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildStreamWithCheck("$ngrokUrl/video_feed"),
                  _buildStreamWithCheck("$ngrokUrl/video_feed"),
                ],
              ),
            ),
          ),
          Center(
            child: SmoothPageIndicator(
              controller: _pageController,
              count: 2,
              effect: WormEffect(
                activeDotColor: Colors.blueAccent,
                dotHeight: 8,
                dotWidth: 8,
              ),
            ),
          ),
          SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.warning),
                    label: Text("Alert"),
                    onPressed: sendAlert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 228, 49, 94),
                      padding: EdgeInsets.symmetric(vertical: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.image),
                    label: Text("Capture"),
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });
                      await fetchImages();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ImagePreviewPage(
                                  image1Base64: image1Base64,
                                  image2Base64: image2Base64,
                                  captureTime: DateTime.now(),
                                ),
                          ),
                        );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      side: BorderSide(color: Colors.blueAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
