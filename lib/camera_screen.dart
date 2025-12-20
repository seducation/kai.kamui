import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';

import 'package:my_app/main.dart'; // To access the global 'cameras' list

class CameraScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onImageUploaded;

  const CameraScreen({super.key, this.onClose, this.onImageUploaded});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final List<XFile> _capturedImages = []; // Stores the clicked images queue
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;
  bool _isUploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera(_selectedCameraIndex);
  }

  // Initialize Camera Logic
  Future<void> _initCamera(int cameraIndex) async {
    if (cameras.isEmpty) return;

    // Dispose previous controller if exists
    await _controller?.dispose();

    _controller = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  // Logic to switch front/back camera
  void _flipCamera() {
    if (cameras.length < 2) return;

    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
    });
    _initCamera(_selectedCameraIndex);
  }

  // Logic to take picture
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      XFile file = await _controller!.takePicture();
      setState(() {
        // Add to queue, don't stop preview
        _capturedImages.add(file);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _saveAndExit() async {
    // Save all images to gallery
    setState(() => _isUploading = true); // Use uploading state for loading UI

    try {
      // Check permission first (gal handles this internally usually, but best practice)
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      for (var image in _capturedImages) {
        await Gal.putImage(image.path);
      }

      if (mounted) {
        // Exit after saving
        widget.onClose?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save: $e';
          _isUploading = false;
        });
      }
    }
  }

  void _discardAndExit() {
    // Just clear list and exit callback
    setState(() {
      _capturedImages.clear();
    });
    widget.onClose?.call();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isUploading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text("Processing...", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    // Layer 1: Camera Preview (Always Visible)
    // We want the preview to be visible even after capture for multi-capture.
    // However, if we want to show the pill UI properly, we need to ensure the preview layer doesn't obscure anything.
    // The previous implementation was correct in using Stack.
    var preview = _isCameraInitialized && _controller != null
        ? SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width:
                    _controller!.value.previewSize?.height ??
                    MediaQuery.of(context).size.width,
                height:
                    _controller!.value.previewSize?.width ??
                    MediaQuery.of(context).size.height,
                child: CameraPreview(_controller!),
              ),
            ),
          )
        : const Center(child: CircularProgressIndicator(color: Colors.white));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          preview,
          // Layer 2: Top Controls (X and Settings)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _discardAndExit, // Close/Discard all
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          if (_error != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black54,
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ),

          // Layer 3: Bottom Controls
          Positioned(
            bottom: 60, // Adjusted to be above bottom nav if overlaps
            left: 0,
            right: 0,
            child: Column(
              children: [
                // 1. Shutter Button (Always Center) - Only show if NO images are captured yet.
                // If images are captured, the shutter functionality moves to the pill's camera icon.
                if (_capturedImages.isEmpty)
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white.withAlpha(51),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(
                    height: 80,
                  ), // Maintain spacing/layout consistency

                const SizedBox(height: 20), // Spacing below shutter
                // 2. Row with Controls
                // If captured images > 0, show different controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _capturedImages.isEmpty
                      ? _buildInitialControlsRow()
                      : _buildPostCaptureControlsRow(),
                ),

                const SizedBox(height: 20), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialControlsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Gallery Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white24,
          ),
          child: const Icon(Icons.image, color: Colors.white, size: 20),
        ),

        // Mode Texts
        Row(
          children: [
            _buildModeText("POST"),
            const SizedBox(width: 20),
            _buildModeText("STORY", isActive: true),
            const SizedBox(width: 20),
            _buildModeText("REEL"),
          ],
        ),

        // Flip Camera
        IconButton(
          icon: const Icon(
            Icons.flip_camera_ios,
            color: Colors.white,
            size: 35,
          ),
          onPressed: _flipCamera,
        ),
      ],
    );
  }

  Widget _buildPostCaptureControlsRow() {
    // Restored UI: [Thumbnail] ... [Pill] ... [Send]
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Thumbnail of last captured image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(
                image: FileImage(File(_capturedImages.last.path)),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Center: The Pill Container (Discard, Retake/Add, Download)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[850], // Dark grey pill
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                // Cross (Discard)
                GestureDetector(
                  onTap: _discardAndExit,
                  child: const Icon(Icons.close, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 20),

                // Camera (Take another photo)
                GestureDetector(
                  onTap: _takePicture,
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),

                // Download (Save)
                GestureDetector(
                  onTap: _saveAndExit,
                  child: const Icon(
                    Icons.download,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // Right: Send Button
          SendButton(capturedImages: _capturedImages),
        ],
      ),
    );
  }

  Widget _buildModeText(String text, {bool isActive = false}) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        fontSize: 16,
        shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
      ),
    );
  }
}

class SendButton extends StatelessWidget {
  final List<XFile> capturedImages;

  const SendButton({super.key, required this.capturedImages});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.push(
        '/sent_post',
        extra: {'images': capturedImages},
      ),
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      child: const Row(
        children: [
          Text(
            'Send',
            style: TextStyle(color: Colors.white, fontSize: 16.0),
          ),
          SizedBox(width: 8.0),
          Icon(Icons.send, color: Colors.white, size: 20.0),
        ],
      ),
    );
  }
}
