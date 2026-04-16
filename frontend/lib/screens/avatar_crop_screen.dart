import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

class AvatarCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String? fileName;

  const AvatarCropScreen({super.key, required this.imageBytes, this.fileName});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final CropController _controller = CropController();

  @override
  void initState() {
    super.initState();
    print("Crop screen opened with ${widget.imageBytes.length} bytes");
  }

  void _cropImage() {
    print("🖼️ Crop button pressed");
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Crop & Rotate"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.imageBytes,
              controller: _controller,
              withCircleUi: true,
              onCropped: (croppedData) async {
                try {
                  print("✂️ Image cropped, returning ${croppedData.length} bytes");
                  
                  print("🔙 Returning cropped bytes to previous screen");
                  if (mounted) {
                    Navigator.pop(context, croppedData);
                  }
                } catch (e) {
                  print("❌ Error cropping image: $e");
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error cropping image: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _cropImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}