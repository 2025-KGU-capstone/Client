import 'package:flutter/material.dart';
import 'main_page.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지 (흑백 & 어둡게)
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.black54, // 어둡게
              BlendMode.darken,
            ),
            child: Image.asset(
              'assets/intro.png', // 배경 이미지
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
          ),

          // 콘텐츠 위젯
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 여기만 수정됨: 아이콘 이미지로 교체
                  Image.asset(
                    'assets/intro_icon.png',
                    width: 150,
                    height: 150,
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "함께 시작하는\n스마트한 배달라이프",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MainPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "시작하기",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
