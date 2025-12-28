import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/camera_screen.dart'; // Added import
import 'package:my_app/lens_screen/staggered_grid.dart';
import 'package:provider/provider.dart';

class LensScreen extends StatefulWidget {
  const LensScreen({super.key});

  @override
  State<LensScreen> createState() => _LensScreenState();
}

class _LensScreenState extends State<LensScreen> {
  final List<models.Row> _items = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  String? _lastRowId;
  AppwriteService? _appwriteService;
  bool _isCameraOpen = false; // Added state

  final _scrollController = ScrollController();
  // final ImagePicker _picker = ImagePicker(); // Removed ImagePicker

  @override
  void initState() {
    super.initState();
    _appwriteService = context.read<AppwriteService>();
    _fetchData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _appwriteService!.getImages(cursor: _lastRowId);

      if (response.rows.isNotEmpty) {
        setState(() {
          _items.addAll(response.rows);
          _lastRowId = response.rows.last.$id;
          if (response.rows.length < 10) {
            _hasMore = false;
          }
        });
      } else {
        setState(() {
          _hasMore = false;
        });
      }
    } on AppwriteException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _items.clear();
      _lastRowId = null;
      _hasMore = true;
    });
    await _fetchData();
  }

  void _onCameraTap() {
    setState(() {
      _isCameraOpen = true;
    });
  }

  Future<void> _closeCamera({bool refreshed = false}) async {
    setState(() {
      _isCameraOpen = false;
    });
    if (refreshed) {
      await _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCameraOpen) {
      return CameraScreen(
        onClose: () => _closeCamera(),
        onImageUploaded: () => _closeCamera(refreshed: true),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            title: const Text('gvone'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
              ),
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  context.push('/profile');
                },
              ),
            ],
            pinned: true,
            floating: true,
          ),
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: _onCameraTap, // Changed to _onCameraTap
              child: const Card(
                margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined),
                      SizedBox(width: 8),
                      Text('Camera'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_error != null)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: $_error'),
                ),
              ),
            ),
          LensStaggeredGrid(
            items: _items,
            scrollController: _scrollController,
            isLoading: _isLoading,
            error: _error,
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
