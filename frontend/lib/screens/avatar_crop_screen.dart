import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:image/image.dart' as img;

class AvatarCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String? fileName;

  const AvatarCropScreen({super.key, required this.imageBytes, this.fileName});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final CropController _controller = CropController();
  bool _isSaving = false;

  /// Compress and resize image for faster upload
  /// - Max dimension: 512x512
  /// - Quality: 85% JPEG compression
  /// - Reduces file size by ~70-80%
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      // Resize to max 512x512 while maintaining aspect ratio
      int size = 512;
      int newWidth = image.width;
      int newHeight = image.height;

      if (newWidth > size || newHeight > size) {
        if (newWidth > newHeight) {
          newHeight = (size * newHeight) ~/ newWidth;
          newWidth = size;
        } else {
          newWidth = (size * newWidth) ~/ newHeight;
          newHeight = size;
        }
      }

      final resized = img.copyResize(image, width: newWidth, height: newHeight);

      // Encode as JPEG with 85% quality for compression
      final compressed = img.encodeJpg(resized, quality: 85);
      debugPrint('🗜️ Compressed: ${imageBytes.length} → ${compressed.length} bytes (${((1 - compressed.length / imageBytes.length) * 100).toStringAsFixed(1)}% reduction)');
      
      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('⚠️ Compression failed, using original: $e');
      return imageBytes;
    }
  }

  @override
  void initState() {
    super.initState();
    //print("Crop screen opened with ${widget.imageBytes.length} bytes");
  }

  void _cropImage() {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    //print("🖼️ Crop button pressed");
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Crop and Resize",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: Crop(
                image: widget.imageBytes,
                controller: _controller,
                withCircleUi: true,
                aspectRatio: 1.0,
                onCropped: (croppedData) async {
                  setState(() => _isSaving = false);
                  try {
                    //print("✂️ Image cropped: ${croppedData.length} bytes");
                    
                    // Compress for faster upload
                    final compressed = await _compressImage(croppedData);
                    
                    //print("📦 Compressed to ${compressed.length} bytes");
                    //print("🔙 Returning optimized bytes");
                    if (mounted) {
                      Navigator.pop(context, compressed);
                    }
                  } catch (e) {
                    //print("❌ Error cropping image: $e");
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
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _cropImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text(
                      "Save",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
