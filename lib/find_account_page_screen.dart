import 'package:flutter/material.dart';
import 'package:my_app/model/chat_model.dart';
import 'package:my_app/chat_messaging_screen.dart';
import 'package:my_app/model/profile.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:appwrite/models.dart' as models;
import 'package:provider/provider.dart';

class FindAccountPageScreen extends StatefulWidget {
  const FindAccountPageScreen({super.key});

  @override
  State<FindAccountPageScreen> createState() => _FindAccountPageScreenState();
}

class _FindAccountPageScreenState extends State<FindAccountPageScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final AppwriteService _appwriteService;
  List<Profile> _searchResults = [];
  bool _isLoading = false;
  String _error = '';
  models.User? _currentUser;
  String? _currentUserProfileId;
  Set<String> _followingProfileIds = {};

  @override
  void initState() {
    super.initState();
    _appwriteService = context.read<AppwriteService>();
    _searchController.addListener(_onSearchChanged);
    _loadCurrentUserAndFollowing();
  }

  Future<void> _loadCurrentUserAndFollowing() async {
    try {
      final user = await _appwriteService.getUser();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
      });
      if (user != null) {
        // Use active identity logic or fallback to main profile.
        // During init, we can try to fetch the main profile ID using the new method name.
        _currentUserProfileId = await _appwriteService.getMainUserProfileId(
          user.$id,
        );
      }
      await _loadFollowingProfiles();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadFollowingProfiles() async {
    if (_currentUser == null) return;
    try {
      final result = await _appwriteService.getFollowingProfiles(
        userId: _currentUser!.$id,
      );
      if (mounted) {
        setState(() {
          _followingProfileIds = result.rows.map((row) => row.$id).toSet();
        });
      }
    } catch (e) {
      // Handle error
    }
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
      final models.RowList result = await _appwriteService.searchProfiles(
        query: query,
      );
      // Get the profile ID of the current user to exclude it
      final userProfiles = await _appwriteService.getUserProfiles(
        ownerId: _currentUser!.$id,
      );
      final selfProfileId = userProfiles.rows.isNotEmpty
          ? userProfiles.rows.first.$id
          : null;

      final profiles = result.rows
          .where((row) => row.$id != selfProfileId) // Exclude self
          .map((row) => Profile.fromMap(row.data, row.$id))
          .toList();

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

  Future<void> _toggleFollowStatus(String profileId) async {
    if (_currentUser == null) return;

    final isFollowing = _followingProfileIds.contains(profileId);
    try {
      if (_currentUserProfileId == null) return;

      if (isFollowing) {
        await _appwriteService.unfollowEntity(
          senderId: _currentUserProfileId!,
          targetId: profileId,
          targetType: 'profile',
        );
      } else {
        await _appwriteService.followEntity(
          senderId: _currentUserProfileId!,
          targetId: profileId,
          isAnonymous:
              false, // Defaulting to public for 'Search' context if untracked, or use 'private' if that's desired default.
          // Since this screen doesn't seem to have full active-identity awareness yet,
          // we are using the fetched _currentUserProfileId (likely main profile).
          // Assuming main profile follows are 'public' or 'private' based on user preference?
          // For now, let's assume 'private' (anonymous/persona) as it's safer, OR
          // since this is a "Find Accounts" page, maybe public?
          // The prompt mentioned: "If isAnonymous is true... Private Profile ID".
          // Here we are using _currentUserProfileId which IS the profile ID.
          // Let's set isAnonymous = true for now to match "Private Profile" behavior
          // if we treat the main profile as the private identity.
          targetType: 'profile',
        );
      }
      if (mounted) {
        setState(() {
          if (isFollowing) {
            _followingProfileIds.remove(profileId);
          } else {
            _followingProfileIds.add(profileId);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating follow status: $e")),
      );
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
      appBar: AppBar(title: const Text('Find People')),
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
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }
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
        final isFollowing = _followingProfileIds.contains(profile.id);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: _isValidUrl(profile.profileImageUrl)
                ? NetworkImage(profile.profileImageUrl!)
                : null,
            child: !_isValidUrl(profile.profileImageUrl)
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(profile.name),
          subtitle: Text(profile.bio ?? ''),
          trailing: ElevatedButton(
            onPressed: () => _toggleFollowStatus(profile.id),
            child: Text(isFollowing ? 'Unfollow' : 'Follow'),
          ),
          onTap: () {
            // Optional: Navigate to profile details page or chat
            final chatModel = ChatModel(
              userId: profile.id, // This should be the PROFILE ID
              name: profile.name,
              message: profile.bio ?? '',
              time: '',
              imgPath: profile.profileImageUrl ?? '',
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatMessagingScreen(
                  chat: chatModel,
                  onMessageSent: (newMessage) {
                    // State management for chat updates
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
