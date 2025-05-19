import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class ImagePreviewPage extends StatefulWidget {
  final String image1Base64;
  final String image2Base64;
  final DateTime captureTime;

  const ImagePreviewPage({
    Key? key,
    required this.image1Base64,
    required this.image2Base64,
    required this.captureTime,
  }) : super(key: key);

  @override
  _ImagePreviewPageState createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  Future<void> saveToGallery(String base64Image, String fileName) async {
    if (base64Image.isEmpty) return;
    try {
      final bytes = base64Decode(base64Image);
      final result = await PhotoManager.editor.saveImage(
        bytes,
        title: fileName,
        filename: "$fileName.jpg",
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result != null
              ? "$fileName saved to gallery"
              : "Failed to save $fileName"),
        ),
      );
    } catch (e) {
      print("Error saving $fileName: $e");
    }
  }

  Future<void> saveBothImages() async {
    await saveToGallery(widget.image1Base64, "image1");
    await saveToGallery(widget.image2Base64, "image2");
  }

  @override
  Widget build(BuildContext context) {
    final image1Bytes = base64Decode(widget.image1Base64);
    final image2Bytes = base64Decode(widget.image2Base64);

    return Scaffold(
      appBar: AppBar(
        title: const Text("📸 Captured Images"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  "Captured at: ${widget.captureTime.toLocal()}",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(image1Bytes, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(image2Bytes, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: const Text(
                  "Save Images",
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: saveBothImages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
