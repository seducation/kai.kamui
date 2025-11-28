import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'appwrite_service.dart';
import 'auth_service.dart';
import 'model/profile.dart';

class WhereToPostScreen extends StatefulWidget {
  final Map<String, dynamic> postData;

  const WhereToPostScreen({super.key, required this.postData});

  @override
  State<WhereToPostScreen> createState() => _WhereToPostScreenState();
}

class _WhereToPostScreenState extends State<WhereToPostScreen> {
  late Future<List<Profile>> _profilesFuture;
  final AppwriteService _appwriteService = AppwriteService();
  final List<String> _selectedProfileIds = [];
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _profilesFuture = _fetchUserProfiles(authService.currentUser!.id);
  }

  Future<List<Profile>> _fetchUserProfiles(String userId) async {
    try {
      final response = await _appwriteService.getUserProfiles(ownerId: userId);
      return response.rows.map((row) => Profile.fromMap(row.data, row.$id)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profiles: $e')),
        );
      }
      return [];
    }
  }

  void _toggleProfileSelection(String profileId) {
    setState(() {
      if (_selectedProfileIds.contains(profileId)) {
        _selectedProfileIds.remove(profileId);
      } else {
        _selectedProfileIds.add(profileId);
      }
    });
  }

  Future<void> _publishPosts() async {
    if (_selectedProfileIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one account to post to.')),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final postFutures = _selectedProfileIds.map((profileId) {
        final postData = {
          ...widget.postData,
          'profile_id': profileId, 
        };
        return authService.createPost(postData);
      });

      await Future.wait(postFutures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully posted to ${_selectedProfileIds.length} account(s).')),
        );
        context.go('/');
      }
    } on AppwriteException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create one or more posts: ${e.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post to...'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _selectedProfileIds.isEmpty || _isPublishing ? null : _publishPosts,
              child: _isPublishing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Publish'),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Profile>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error loading profiles.'));
          }

          final profiles = snapshot.data!;

          if (profiles.isEmpty) {
            return const Center(
              child: Text(
                'You don\'t have any profiles to post to.\nGo to your profile to create one.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final isSelected = _selectedProfileIds.contains(profile.id);

              return CheckboxListTile(
                secondary: CircleAvatar(
                  backgroundImage: NetworkImage(profile.profileImageUrl ?? ''),
                ),
                title: Text(profile.name),
                subtitle: Text(profile.type), // e.g., 'profile', 'channel'
                value: isSelected,
                onChanged: (bool? value) {
                   if (value != null) {
                     _toggleProfileSelection(profile.id);
                   }
                },
              );
            },
          );
        },
      ),
    );
  }
}
