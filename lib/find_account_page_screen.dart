import 'package:flutter/material.dart';
import 'package:my_app/model/chat_model.dart';
import 'package:my_app/chat_messaging_screen.dart';
import 'package:my_app/model/profile.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:appwrite/models.dart' as models;

class FindAccountPageScreen extends StatefulWidget {
  const FindAccountPageScreen({super.key});

  @override
  State<FindAccountPageScreen> createState() => _FindAccountPageScreenState();
}

class _FindAccountPageScreenState extends State<FindAccountPageScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AppwriteService _appwriteService = AppwriteService();
  List<Profile> _searchResults = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
          _error = '';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final models.RowList result = await _appwriteService.searchProfiles(name: query);
      final profiles = result.rows.map((row) => Profile.fromMap(row.data, row.$id)).toList();
      if (mounted) {
        setState(() {
          _searchResults = profiles;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error searching profiles: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.hasAuthority;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find People'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(child: Text(_error));
    }
    if (_searchController.text.isEmpty) {
      return const Center(child: Text('Search for people by their name.'));
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No results found.'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final profile = _searchResults[index];
        final chatModel = ChatModel(
          userId: profile.id,
          name: profile.name,
          message: profile.bio ?? '',
          time: '',
          imgPath: profile.imageUrl ?? '',
        );
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: _isValidUrl(profile.imageUrl)
                ? NetworkImage(profile.imageUrl!)
                : null,
            child: !_isValidUrl(profile.imageUrl)
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(profile.name),
          subtitle: Text(profile.bio ?? ''),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatMessagingScreen(
                  chat: chatModel,
                  onMessageSent: (newMessage) {
                    // This part might need adjustment depending on how you manage state
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
