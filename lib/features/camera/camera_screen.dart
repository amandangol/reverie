import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import '../gallery/provider/media_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRearCameraSelected = true;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![_isRearCameraSelected ? 0 : 1],
          ResolutionPreset.high,
          enableAudio: true,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile photo = await _controller!.takePicture();
      final File imageFile = File(photo.path);

      // Save the image to gallery
      final result = await PhotoManager.editor.saveImageWithPath(
        imageFile.path,
        title: 'Camera_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result != null) {
        // Refresh the media provider
        if (mounted) {
          context.read<MediaProvider>().refreshMedia();
        }
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Save the image to gallery
        final result = await PhotoManager.editor.saveImageWithPath(
          imageFile.path,
          title: 'Gallery_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (result != null) {
          // Refresh the media provider
          if (mounted) {
            context.read<MediaProvider>().refreshMedia();
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_controller!),
          ),

          // Camera controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: Colors.black54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery button
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),

                  // Capture button
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.circle,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ),

                  // Camera flip button
                  IconButton(
                    icon:
                        const Icon(Icons.flip_camera_ios, color: Colors.white),
                    onPressed: () async {
                      setState(() {
                        _isRearCameraSelected = !_isRearCameraSelected;
                      });
                      await _controller!.dispose();
                      _controller = CameraController(
                        _cameras![_isRearCameraSelected ? 0 : 1],
                        ResolutionPreset.high,
                        enableAudio: true,
                      );
                      await _controller!.initialize();
                      if (mounted) setState(() {});
                    },
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
