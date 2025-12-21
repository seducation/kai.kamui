import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:provider/provider.dart';

class AddToStoryScreen extends StatefulWidget {
  const AddToStoryScreen({super.key});

  @override
  State<AddToStoryScreen> createState() => _AddToStoryScreenState();
}

class _AddToStoryScreenState extends State<AddToStoryScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _uploadAndNavigate() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final appwriteService = context.read<AppwriteService>();
      final imageBytes = await _imageFile!.readAsBytes();
      final filename = _imageFile!.name;

      final uploadedFile = await appwriteService.uploadFile(
        bytes: imageBytes,
        filename: filename,
      );

      final mediaUrl = appwriteService.getFileViewUrl(uploadedFile.$id);

      final storyData = {
        'mediaUrl': mediaUrl,
        'mediaType': 'image',
        'caption': _captionController.text,
        'location': _locationController.text,
      };

      if (mounted) {
        final storyDataEncoded = jsonEncode(storyData);
        context.push('/where_to_post_story?storyData=$storyDataEncoded');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Story'),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadAndNavigate,
            child: _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Next'),
          ),
        ],
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              width: double.infinity,
              color: Colors.grey[300],
              child: _imageFile != null
                  ? Image.file(File(_imageFile!.path), fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.add_a_photo, size: 50)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: 'Add a caption...',
                border: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Add a location...',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
