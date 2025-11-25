import 'package:flutter/material.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:provider/provider.dart';

// The main dialog widget that contains the form.
class CreateRowDialog extends StatefulWidget {
  const CreateRowDialog({super.key});

  @override
  State<CreateRowDialog> createState() => _CreateRowDialogState();
}

class _CreateRowDialogState extends State<CreateRowDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _profileImageController = TextEditingController();
  final _bannerImageController = TextEditingController();
  String _selectedType = "profile";

  bool _createMore = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _profileImageController.dispose();
    _bannerImageController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final appwriteService =
            Provider.of<AppwriteService>(context, listen: false);
        final user = await appwriteService.getUser();

        // --- Check for existing profile --- 
        if (_selectedType == 'profile') {
          final existingProfiles = await appwriteService.getUserProfiles(ownerId: user.$id);
          if (existingProfiles.rows.any((row) => row.data['type'] == 'profile')) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You can only create one main profile.')),
            );
            return; // Stop the creation process
          }
        }

        await appwriteService.createProfile(
          ownerId: user.$id,
          name: _nameController.text,
          type: _selectedType,
          bio: _bioController.text,
          profileImageUrl: _profileImageController.text,
          bannerImageUrl: _bannerImageController.text,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Created!")),
        );

        if (!_createMore) {
          Navigator.of(context).pop();
        } else {
          // Clear the form for the next entry
          _formKey.currentState!.reset();
          _nameController.clear();
          _bioController.clear();
          _profileImageController.clear();
          _bannerImageController.clear();
          setState(() {
            _selectedType = "profile";
          });
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 500, // Max width for tablet/desktop
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Header Section ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Create Profile",
                      style: theme.textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      color: theme.iconTheme.color,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // --- Scrollable Form Content ---
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomNullTextField(
                        controller: _nameController,
                        label: "Name",
                        hintText: "Enter string",
                        maxLength: 256,
                        minLines: 3,
                        icon: Icons.title,
                      ),
                      const SizedBox(height: 24),
                      DropdownWidget(
                        label: "Type",
                        items: const ["profile", "channel", "thread"],
                        selectedItem: _selectedType,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedType = newValue!;
                          });
                        },
                        icon: Icons.category,
                      ),
                      const SizedBox(height: 24),
                      CustomNullTextField(
                        controller: _bioController,
                        label: "Bio",
                        hintText: "Enter text",
                        isSingleLine: false,
                        minLines: 3,
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 24),
                      CustomNullTextField(
                        controller: _profileImageController,
                        label: "Profile Image",
                        hintText: "Enter image URL",
                        isSingleLine: true,
                        icon: Icons.image,
                      ),
                      const SizedBox(height: 24),
                      CustomNullTextField(
                        controller: _bannerImageController,
                        label: "Banner Image",
                        hintText: "Enter image URL",
                        isSingleLine: true,
                        icon: Icons.image,
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1),

              // --- Footer Section (Toggle and Buttons) ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Create More Switch
                    Row(
                      children: [
                        Switch(
                          value: _createMore,
                          activeThumbColor: theme.colorScheme.primary,
                          inactiveThumbColor: theme.disabledColor,
                          inactiveTrackColor:
                              theme.disabledColor.withAlpha(100),
                          onChanged: (val) => setState(() => _createMore = val),
                        ),
                        const SizedBox(width: 8),
                        const Text("Create more",
                            style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    const Spacer(),

                    // Cancel Button
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.textTheme.bodyMedium?.color,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                      ),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 12),

                    // Create Button
                    ElevatedButton(
                      onPressed: _createProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text("Create",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Reusable Custom Input Field with NULL Checkbox and Counter ---
class CustomNullTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final int? maxLength;
  final int minLines;
  final bool isSingleLine;
  final IconData icon;
  final TextEditingController controller;

  const CustomNullTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.maxLength,
    this.minLines = 1,
    this.isSingleLine = false,
    required this.icon,
    required this.controller,
  });

  @override
  State<CustomNullTextField> createState() => _CustomNullTextFieldState();
}

class _CustomNullTextFieldState extends State<CustomNullTextField> {
  bool isNull = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Row (title optional)
        Row(
          children: [
            Icon(widget.icon, size: 14, color: theme.iconTheme.color),
            const SizedBox(width: 6),
            RichText(
              text: TextSpan(
                text: widget.label,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Input Container with Counter and NULL Checkbox
        Container(
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: widget.controller,
                enabled: !isNull, // Disable input if NULL is checked
                maxLines: widget.isSingleLine ? 1 : widget.minLines,
                maxLength: widget.maxLength,
                style: TextStyle(
                  color: isNull
                      ? theme.disabledColor
                      : theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: theme.inputDecorationTheme.hintStyle,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                  counterText: "", // Hide default counter provided by maxLength
                ),
                validator: (value) {
                  if (!isNull && (value == null || value.isEmpty)) {
                    return 'Please enter a value';
                  }
                  return null;
                },
              ),

              // Footer inside the input box (Counter + Null Checkbox)
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 8, bottom: 4),
                child: Row(
                  children: [
                    // Custom Counter
                    if (widget.maxLength != null)
                      ValueListenableBuilder(
                        valueListenable: widget.controller,
                        builder: (context, TextEditingValue value, _) {
                          return Text(
                            "${value.text.length}/${widget.maxLength}",
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    const Spacer(),
                    // Null Checkbox
                    InkWell(
                      onTap: () {
                        setState(() {
                          isNull = !isNull;
                          if (isNull) widget.controller.clear();
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: isNull,
                            onChanged: (val) {
                              setState(() {
                                isNull = val ?? false;
                                if (isNull) widget.controller.clear();
                              });
                            },
                            side: BorderSide(
                                color: theme.dividerColor, width: 1),
                            activeColor: theme.primaryColor,
                            checkColor: theme.colorScheme.onPrimary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          Text(
                            "NULL",
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DropdownWidget extends StatelessWidget {
  final String label;
  final List<String> items;
  final String selectedItem;
  final ValueChanged<String?> onChanged;
  final IconData icon;

  const DropdownWidget({
    super.key,
    required this.label,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.iconTheme.color),
            const SizedBox(width: 6),
            RichText(
              text: TextSpan(
                text: label,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: " optional",
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.dividerColor),
          ),
          child: DropdownButton<String>(
            value: selectedItem,
            isExpanded: true,
            underline: Container(),
            items: items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
