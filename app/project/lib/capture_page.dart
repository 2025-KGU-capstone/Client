import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'LiveStreamPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CaptureImageApp(),
  ));
}

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

  @override
  void initState() {
    super.initState();
    fetchNgrokUrl();
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
    setState(() {
      isLoading = true;
    });
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

  Future<void> saveToGallery(String base64Image, String fileName) async {
    if (base64Image.isEmpty) return;
    try {
      final bytes = base64Decode(base64Image);
      final result = await PhotoManager.editor.saveImage(
        bytes,
        title: fileName,
        filename: "$fileName.jpg",
      );
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$fileName saved to gallery")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save $fileName")),
        );
      }
    } catch (e) {
      print("Error saving to gallery: $e");
    }
  }

  Widget buildLiveImage(String base64Image) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[300],
            image: base64Image.isNotEmpty
                ? DecorationImage(
              image: MemoryImage(base64Decode(base64Image)),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: base64Image.isEmpty
              ? Center(child: Text("No image"))
              : null,
        ),
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
        Positioned(
          top: 8,
          right: 8,
          child: Text(
            "2025 / 04 / 07 / 14 : 30 : 31",
            style: TextStyle(color: Colors.black, fontSize: 12),
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF5E70FF),
        title: Text("실시간 라이브"),
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
              aspectRatio: 4 / 3,
              child: PageView(
                children: [
                  buildLiveImage(image1Base64),
                  buildLiveImage(image2Base64),
                ],
              ),
            ),
          ),
          // 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.call),
                    label: Text("SOS call"),
                    onPressed: isLoading ? null : fetchImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 228, 49, 94),
                      padding: EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.image),
                    label: Text("save photo"),
                    onPressed: () {
                      if (image1Base64.isNotEmpty)
                        saveToGallery(image1Base64, 'image1');
                      if (image2Base64.isNotEmpty)
                        saveToGallery(image2Base64, 'image2');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: Colors.blueAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          /// ✅ 새 스트리밍 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.live_tv),
              label: Text("실시간 스트리밍 보기"),
              onPressed: () {
                if (ngrokUrl.startsWith("http")) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveStreamPage(streamUrl: "$ngrokUrl/video_feed"),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("ngrok URL을 가져오지 못했습니다.")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }
}
