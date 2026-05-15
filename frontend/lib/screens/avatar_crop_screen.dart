import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

import '../services/image_processing_service.dart';

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

  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      return await ImageProcessingService.resizeAndCompressJpg(
        bytes: imageBytes,
        maxSide: 512,
        quality: 85,
      );
    } catch (e) {
      debugPrint('⚠️ Compression failed, using original: $e');
      return imageBytes;
    }
  }




  void _cropImage() {
    if (_isSaving) return;
    
    // Start the loading spinner
    setState(() => _isSaving = true);
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
                  // 🚨 REMOVED: setState(() => _isSaving = false);
                  // We keep _isSaving = true so the spinner continues while compressing!
                  
                  try {
                    // Compress in the background (off UI thread)
                    final compressed = await _compressImage(croppedData);
                    if (!mounted) return;
                    // Return compressed bytes to caller
                    Navigator.pop(context, compressed);
                  } catch (e) {

                    if (mounted) {
                      // Only stop the loading spinner if an error occurs
                      setState(() => _isSaving = false);
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