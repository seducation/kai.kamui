import 'package:flutter/material.dart';
import 'package:my_app/widgets/add_pop_up_menu.dart';

class EditProfileFAB extends StatelessWidget {
  const EditProfileFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const ChannelSettingsDialog(),
        );
      },
      backgroundColor: Colors.black,
      child: const Icon(Icons.edit),
    );
  }
}

class ChannelSettingsDialog extends StatefulWidget {
  const ChannelSettingsDialog({super.key});

  @override
  State<ChannelSettingsDialog> createState() => _ChannelSettingsDialogState();
}

class _ChannelSettingsDialogState extends State<ChannelSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: "মজার তথ্য");
  final _handleController = TextEditingController(text: "@RbEducation-c3o");
  final _descriptionController =
      TextEditingController(text: "Tjis channel is for education and facts related you...");

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      // In a real app, you would save these settings.
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const Divider(color: Colors.white12, thickness: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: <Widget>[
                      const ChannelHeader(),
                      const SizedBox(height: 24),
                      CustomNullTextField(
                        controller: _nameController,
                        label: "Name",
                        hintText: "Enter your channel name",
                        icon: Icons.edit,
                      ),
                      const SizedBox(height: 24),
                      CustomNullTextField(
                        controller: _handleController,
                        label: "Handle",
                        hintText: "Enter your channel handle",
                        icon: Icons.alternate_email,
                      ),
                      const SizedBox(height: 24),
                      CustomNullTextField(
                        controller: _descriptionController,
                        label: "Description",
                        hintText: "Enter your channel description",
                        minLines: 3,
                        isSingleLine: false,
                        icon: Icons.description,
                      ),
                      const SizedBox(height: 24),
                      _buildNoteSection(context),
                    ],
                  ),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              _buildFooter(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Channel settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(Icons.info_outline, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.grey, fontSize: 13),
                children: <TextSpan>[
                  TextSpan(
                    text:
                        'Changes made to your name and profile picture are visible only on YouTube and not other Google services. ',
                  ),
                  TextSpan(
                    text: 'Learn more',
                    style: TextStyle(color: Colors.blueAccent),
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

class ChannelHeader extends StatelessWidget {
  const ChannelHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 100,
          color: Colors.deepPurple[900],
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('মজার তথ্য',
                        style: TextStyle(color: Colors.white38, fontSize: 18)),
                    SizedBox(height: 5),
                    Text('Biology',
                        style:
                            TextStyle(color: Colors.greenAccent, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Container(
                color: Colors.black,
                child: const Icon(
                  Icons.handshake,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
