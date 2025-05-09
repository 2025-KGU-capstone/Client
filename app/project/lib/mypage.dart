import 'package:flutter/material.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 둥글게 시작되는 흰색 영역
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.only(top: 0),
            padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 32),
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                const Text("닉네임", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text("프로필 수정"),
                ),
                const SizedBox(height: 32),
                const Divider(thickness: 1),
                ListTile(
                  title: const Text("이용 내역"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text("설정"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text("고객 센터"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ),
        // 약간 아래로 밀어주는 ListView (AppBar 아래 보이게 하기)
        ListView(
          padding: EdgeInsets.zero,
          children: const [
            SizedBox(height: 140), // 둥근 영역 전체 높이 확보용
          ],
        ),
      ],
    );
  }
}
