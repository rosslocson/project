import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';

class AvatarCropScreen extends StatefulWidget {
  final File imageFile;

  const AvatarCropScreen({super.key, required this.imageFile});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final CropController _controller = CropController();
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    _imageBytes = await widget.imageFile.readAsBytes();
    setState(() {});
  }

  void _cropImage() {
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    if (_imageBytes == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              image: _imageBytes!,
              controller: _controller,
              withCircleUi: true,
              onCropped: (croppedData) async {
                final tempDir = await getTemporaryDirectory();
                final file = File('${tempDir.path}/avatar.png');
                await file.writeAsBytes(croppedData);

                Navigator.pop(context, file); // VERY IMPORTANT
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _cropImage,
                child: const Text("Save"),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}