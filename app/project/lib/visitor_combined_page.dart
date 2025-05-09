import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

class VisitorCombinedPage extends StatefulWidget {
  @override
  _VisitorCombinedPageState createState() => _VisitorCombinedPageState();
}

class _VisitorCombinedPageState extends State<VisitorCombinedPage> {
  List<Map<String, dynamic>> visitors = [];
  final picker = ImagePicker();
  String selectedFilter = '전체';
  String ngrokUrl = "Fetching...";

  @override
  void initState() {
    super.initState();
    loadVisitors();
    fetchNgrokUrl();
  }

  Future<void> fetchNgrokUrl() async {
    final ref = FirebaseDatabase.instance.ref("server/ngrok_url");
    final snapshot = await ref.get();
    setState(() {
      ngrokUrl = snapshot.exists ? snapshot.value as String : "No URL found in Firebase";
    });
  }

  Future<void> loadVisitors() async {
    final prefs = await SharedPreferences.getInstance();
    final visitorData = prefs.getString('visitors');
    if (visitorData != null) {
      setState(() {
        visitors = List<Map<String, dynamic>>.from(jsonDecode(visitorData));
      });
    }
  }

  Future<void> saveVisitors() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('visitors', jsonEncode(visitors));
  }

  Future<void> addVisitor() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = "${directory.path}/$fileName.jpg";
      final file = File(pickedFile.path);
      await file.copy(filePath);

      setState(() {
        visitors.add({
          "filePath": filePath,
          "timestamp": DateTime.now().toIso8601String(),
        });
      });

      await saveVisitors();
      await uploadToServer(file);
    }
  }

  Future<void> uploadToServer(File file) async {
    final request = http.MultipartRequest('POST', Uri.parse("$ngrokUrl/upload"));
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    await request.send();
  }

  void showFilterMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: ['전체', '오늘', '지난 7일', '한달'].map((option) => ListTile(
          title: Text(option),
          onTap: () {
            setState(() => selectedFilter = option);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  void showRegisterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("방문자 등록 / 확인"),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...visitors.map((visitor) => Card(
                margin: EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text("등록자", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("등록자 정보 없음"),
                ),
              )),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text("방문자를 추가하시겠습니까?", style: TextStyle(color: Colors.blue.shade700)),
                    SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        addVisitor();
                      },
                      icon: Icon(Icons.add, color: Colors.blue),
                      label: Text("추가하기", style: TextStyle(color: Colors.blue)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.transparent),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("닫기"),
          )
        ],
      ),
    );
  }

  List<Map<String, dynamic>> getFilteredVisitors() {
    DateTime now = DateTime.now();
    return visitors.where((v) {
      final date = DateTime.parse(v['timestamp'] ?? now.toIso8601String());
      switch (selectedFilter) {
        case '오늘':
          return date.year == now.year && date.month == now.month && date.day == now.day;
        case '지난 7일':
          return date.isAfter(now.subtract(Duration(days: 7)));
        case '한달':
          return date.isAfter(now.subtract(Duration(days: 30)));
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = getFilteredVisitors();
    return Scaffold(
      appBar: AppBar(
        title: Text("방문자 등록 / 확인"),
        backgroundColor: Colors.blue[700],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DropdownButton<String>(
                value: selectedFilter,
                underline: SizedBox(),
                items: ['전체', '오늘', '지난 7일', '한달']
                    .map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedFilter = value);
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final visitor = filtered[index];
                final date = DateTime.parse(visitor['timestamp']);
                final dateStr =
                    "${date.year} / ${date.month.toString().padLeft(2, '0')} / ${date.day.toString().padLeft(2, '0')}\n${date.hour.toString().padLeft(2, '0')} : ${date.minute.toString().padLeft(2, '0')}";
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(visitor['filePath']),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            dateStr,
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: ElevatedButton.icon(
              onPressed: showRegisterDialog,
              icon: Icon(Icons.person_add_alt),
              label: Text("방문자 등록하기"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {},
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이페이지"),
        ],
      ),
    );
  }
}
