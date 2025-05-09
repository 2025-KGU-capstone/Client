import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

class LiveStreamPage extends StatelessWidget {
  final String streamUrl;

  const LiveStreamPage({super.key, required this.streamUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("실시간 스트리밍"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Mjpeg(
            stream: streamUrl,
            isLive: true,
          ),
        ),
      ),
    );
  }
}
