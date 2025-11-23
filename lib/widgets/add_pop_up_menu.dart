import 'package:flutter/material.dart';

// The main dialog widget that contains the form.
class CreateRowDialog extends StatefulWidget {
  const CreateRowDialog({super.key});

  @override
  State<CreateRowDialog> createState() => _CreateRowDialogState();
}

class _CreateRowDialogState extends State<CreateRowDialog> {
  // State for the "Create more" toggle switch.
  bool _createMore = false;

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
                    "Create row",
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
                  children: const [
                    // Input fields using the custom widget
                    CustomNullTextField(
                      label: "user id",
                      hintText: "Enter string",
                      maxLength: 256,
                      minLines: 3,
                      icon: Icons.title,
                    ),
                    SizedBox(height: 24),

                    DropdownWidget(
                      label: "type",
                      items: ["channel", "group", "community"],
                      icon: Icons.category,
                    ),
                    SizedBox(height: 24),

                    CustomNullTextField(
                      label: "bio",
                      hintText: "Enter text",
                      isSingleLine: false,
                      minLines: 3,
                      icon: Icons.person,
                    ),
                    SizedBox(height: 24),

                    CustomNullTextField(
                      label: "profile image",
                      hintText: "Enter image URL",
                      isSingleLine: true,
                      icon: Icons.image,
                    ),
                    SizedBox(height: 24),

                    CustomNullTextField(
                      label: "banner image",
                      hintText: "Enter image URL",
                      isSingleLine: true,
                      icon: Icons.image,
                    ),
                    SizedBox(height: 24),

                    // Row ID Dropdown
                    DropdownWidget(
                      label: "Category",
                      items: ["profile", "channel", "group", "hashtags"],
                      icon: Icons.edit,
                    ),
                    SizedBox(height: 24),

                    // Permission Text
                    Text(
                      "Make sure this channel follows community guidelines.",
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    SizedBox(height: 16),

                    // Info Box
                    InfoBox(),
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
                        inactiveTrackColor: theme.disabledColor.withAlpha(100),
                        onChanged: (val) => setState(() => _createMore = val),
                      ),
                      const SizedBox(width: 8),
                      const Text("Create more", style: TextStyle(fontSize: 13)),
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
                    onPressed: () {
                      // In a real app, this would submit the form data
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Row Created!")),
                      );
                    },
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
    );
  }
}

// --- Auxiliary Widgets for Clarity ---

class InfoBox extends StatelessWidget {
  const InfoBox({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withAlpha(25),
        border: Border.all(color: theme.colorScheme.secondary.withAlpha(50)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "If you want to assign row permissions, navigate to Table settings and enable row security. Otherwise, only table permissions will be used.",
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
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

  const CustomNullTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.maxLength,
    this.minLines = 1,
    this.isSingleLine = false,
    required this.icon,
  });

  @override
  State<CustomNullTextField> createState() => _CustomNullTextFieldState();
}

class _CustomNullTextFieldState extends State<CustomNullTextField> {
  bool isNull = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                controller: _controller,
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
              ),

              // Footer inside the input box (Counter + Null Checkbox)
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 8, bottom: 4),
                child: Row(
                  children: [
                    // Custom Counter
                    if (widget.maxLength != null)
                      ValueListenableBuilder(
                        valueListenable: _controller,
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
                          if (isNull) _controller.clear();
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
                                if (isNull) _controller.clear();
                              });
                            },
                            side: BorderSide(color: theme.dividerColor, width: 1),
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

class DropdownWidget extends StatefulWidget {
  final String label;
  final List<String> items;
  final IconData icon;

  const DropdownWidget({
    super.key,
    required this.label,
    required this.items,
    required this.icon,
  });

  @override
  DropdownWidgetState createState() => DropdownWidgetState();
}

class DropdownWidgetState extends State<DropdownWidget> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.items.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, size: 14, color: theme.iconTheme.color),
            const SizedBox(width: 6),
            RichText(
              text: TextSpan(
                text: widget.label,
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
            value: _selectedValue,
            isExpanded: true,
            underline: Container(),
            items: widget.items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedValue = newValue;
              });
            },
          ),
        ),
      ],
    );
  }
}
