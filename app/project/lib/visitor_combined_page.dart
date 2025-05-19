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

  Future<List<String>> fetchImageFilenames(String serverUrl) async {
    final url = Uri.parse('$serverUrl/get_images');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> imageList = data['images'];
        return imageList.cast<String>();
      } else {
        print('❌ 이미지 목록 요청 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('🔥 이미지 목록 요청 중 에러: $e');
      return [];
    }
  }

  Future<void> fetchNgrokUrl() async {
    final ref = FirebaseDatabase.instance.ref("server/ngrok_url");
    final snapshot = await ref.get();
    setState(() {
      ngrokUrl = snapshot.exists
          ? snapshot.value as String
          : "No URL found in Firebase";
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

  Future<void> uploadToServer(File file, String name) async {
    final request =
        http.MultipartRequest('POST', Uri.parse("$ngrokUrl/upload"));
    request.fields['name'] = name;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        print("✅ 서버 업로드 성공: $name");
      } else {
        print("❌ 서버 업로드 실패: 상태 코드 ${response.statusCode}");
        final respStr = await response.stream.bytesToString();
        print("🔴 서버 응답 본문: $respStr");
      }
    } catch (e) {
      print("🔥 업로드 중 예외 발생: $e");
    }
  }

  Future<void> deleteToServer(String name) async {
    final request =
        http.MultipartRequest('POST', Uri.parse("$ngrokUrl/delete"));
    request.fields['name'] = name;
    await request.send();
  }

  Future<void> addVisitorWithPickedFile(String name, XFile pickedFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final filePath = "${directory.path}/$fileName.jpg";
    final file = File(pickedFile.path);
    await file.copy(filePath);

    setState(() {
      visitors.add({
        "filePath": filePath,
        "name": name,
      });
    });

    await saveVisitors();
    await uploadToServer(file, name);
  }

  void showRegisterDialog() {
    final TextEditingController nameController = TextEditingController();
    XFile? pickedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Stack(
              children: [
                Container(
                  width: 400,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_add_alt, color: Colors.blue[700]),
                          SizedBox(width: 8),
                          Text("방문자 등록",
                              style: TextStyle(
                                  fontSize: 20, color: Colors.blue[700])),
                        ],
                      ),
                      SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final image = await picker.pickImage(
                                  source: ImageSource.gallery);
                              if (image != null) {
                                setState(() => pickedImage = image);
                              }
                            },
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue.shade200),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.blue.shade50,
                              ),
                              child: pickedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(pickedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo,
                                            color: Colors.blue[400]),
                                        SizedBox(height: 4),
                                        Text("사진",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue[400])),
                                      ],
                                    ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: "이름 입력",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon:
                                    Icon(Icons.person, color: Colors.blue[400]),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.blue, width: 2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("이름을 입력해주세요.")),
                            );
                            return;
                          }
                          if (pickedImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("사진을 선택해주세요.")),
                            );
                            return;
                          }

                          Navigator.pop(context);
                          addVisitorWithPickedFile(name, pickedImage!);
                        },
                        icon: Icon(Icons.check),
                        label: Text("방문자 등록"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                // 🔺 오른쪽 상단 닫기 버튼
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> handleVisitorDelete(int index) async {
    final removed = visitors[index];
    final name = removed['name'];
    final filePath = removed['filePath'];

    setState(() {
      visitors.removeAt(index); // 리스트에서 제거
    });
    // 로컬 파일 삭제
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("로컬 파일 삭제 실패: $e");
    }
    // SharedPreferences 갱신
    await saveVisitors();
    // 서버에 삭제 요청
    try {
      final response = await http.post(
        Uri.parse('$ngrokUrl/delete'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name}),
      );

      if (response.statusCode == 200) {
        print("서버 삭제 완료");
      } else {
        print("서버 삭제 실패: ${response.statusCode} / ${response.body}");
      }
    } catch (e) {
      print("서버 삭제 요청 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("방문자 등록 및 확인"),
          backgroundColor: Colors.blue[700],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list_alt), text: "방문자 확인"),
              Tab(icon: Icon(Icons.person_add_alt), text: "방문자 등록"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ServerImageTab(serverUrl: ngrokUrl),
            VisitorRegisterTab(
              onRegisterPressed: showRegisterDialog,
              visitors: visitors,
              onDeletePressed: handleVisitorDelete,
            )
          ],
        ),
      ),
    );
  }
}

class VisitorRegisterTab extends StatelessWidget {
  final VoidCallback onRegisterPressed;
  final List<Map<String, dynamic>> visitors;
  final void Function(int index) onDeletePressed;

  const VisitorRegisterTab({
    required this.onRegisterPressed,
    required this.visitors,
    required this.onDeletePressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 12),
        Expanded(
          child: visitors.isEmpty
              ? Center(child: Text("등록된 방문자가 없습니다."))
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: visitors.length,
                  itemBuilder: (context, index) {
                    final visitor = visitors[index];
                    final name = visitor["name"] ?? "이름 없음";
                    final filePath = visitor["filePath"];

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(filePath),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // 삭제 확인 다이얼로그 띄우기
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text("방문자 삭제"),
                                  content: Text("정말로 삭제하시겠습니까?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text("취소"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        onDeletePressed(index);
                                      },
                                      child: Text("삭제",
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
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
            onPressed: onRegisterPressed,
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
        ),
      ],
    );
  }
}

class ServerImageTab extends StatelessWidget {
  final String serverUrl;

  const ServerImageTab({required this.serverUrl, super.key});

  Future<List<String>> fetchImageFilenames() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/get_images_all'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> imageList = data['images'];
        return imageList.cast<String>();
      } else {
        print('❌ 이미지 목록 불러오기 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('🔥 네트워크 오류: $e');
      return [];
    }
  }

  String buildImageUrl(String filename) {
    return '$serverUrl/get_image/$filename';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: fetchImageFilenames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('이미지가 없습니다.'));
        }

        final filenames = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filenames.length,
          itemBuilder: (context, index) {
            final imageUrl = buildImageUrl(filenames[index]);

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                          child: Icon(Icons.broken_image, color: Colors.red)),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
