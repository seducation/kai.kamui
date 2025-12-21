import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hero_banner.dart';
import 'status_rail_section.dart';
import 'product_grid.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadContent();
  }

  Future<void> loadContent() async {
    // final service = context.read<AppwriteService>();
    // final data = await service.getMovies();
    setState(() {
      // movies = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("myapps", style: TextStyle(fontSize: 22)),
        actions: const [
          PersistentChip(),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            HeroBanner(items: [
              HeroItem(
                  title: "Foundation",
                  subtitle: "Apple Original",
                  description: "A new empire will rise.",
                  imageUrl:
                      "https://is3-ssl.mzstatic.com/image/thumb/Features116/v4/e2/2b/8c/e22b8c2c-87e6-2b12-b174-a9c6838b8133/U0YtVFZBLVVTQS1GYW1pbHktQ2Fyb3VzZWwtRm91bmRhdGlvbi5wbmc.png/1679x945.webp"),
              HeroItem(
                title: "LOOT",
                subtitle: "TV Show • Comedy • TV-MA",
                description:
                    "A billionaire divorcée continues her hilarious quest to improve the world—and herself.",
                imageUrl: "https://is1-ssl.mzstatic.com/image/thumb/Features122/v4/a4/3c/6e/a43c6e4e-941c-2334-f87c-6b3a9a1491e3/U0YtVFZBLVVTQS1GYW1pbHktQ2Fyb3VzZWwtTG9vdC5wbmc/1679x945.webp",
              ),
              HeroItem(
                title: "Severance",
                subtitle: "Drama • Sci-Fi",
                description: "A unique workplace thriller about split memories.",
                imageUrl: "https://is3-ssl.mzstatic.com/image/thumb/Features116/v4/3c/f1/c1/3cf1c1f7-4a74-a621-3d5f-149b1390906f/U0YtVFZBLVVTQS1GYW1pbHktQ2Fyb3VzZWwtU2V2ZXJhbmNlLnBuZw/1679x945.webp",
              ),
            ]),
            const SizedBox(height: 20),
            const StatusRailSection(
              title: "People",
            ),
            const SizedBox(height: 20),
            ProductGrid(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class PersistentChip extends StatefulWidget {
  const PersistentChip({super.key});

  @override
  State<PersistentChip> createState() => _PersistentChipState();
}

class _PersistentChipState extends State<PersistentChip> {
  final TextEditingController _textController = TextEditingController();
  String _chipText = '';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadChipText();
  }

  Future<void> _loadChipText() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _chipText = prefs.getString('chipText') ?? 'Your Text';
      _textController.text = _chipText;
    });
  }

  Future<void> _saveChipText(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chipText', text);
    setState(() {
      _chipText = text;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return SizedBox(
        width: 150,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                autofocus: true,
                onSubmitted: _saveChipText,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveChipText(_textController.text),
            ),
          ],
        ),
      );
    } else {
      return InkWell(
        onTap: () {
          setState(() {
            _isEditing = true;
          });
        },
        child: Chip(
          label: Text(_chipText),
          avatar: const Icon(Icons.edit),
        ),
      );
    }
  }
}