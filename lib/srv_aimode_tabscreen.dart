import 'package:flutter/material.dart';
import 'package:my_app/ai_chat_screen.dart';

class SrvAimodeTabscreen extends StatefulWidget {
  final List<Map<String, dynamic>> searchResults;
  final String query;

  const SrvAimodeTabscreen({
    super.key,
    required this.searchResults,
    required this.query,
  });

  @override
  State<SrvAimodeTabscreen> createState() => _SrvAimodeTabscreenState();
}

class _SrvAimodeTabscreenState extends State<SrvAimodeTabscreen> {
  @override
  Widget build(BuildContext context) {
    return AIChatScreen(
      searchResults: widget.searchResults,
      query: widget.query,
    );
  }
}
