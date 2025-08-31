// lib/widgets/tag_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'beautiful_text_field.dart';

class TagEditor extends StatefulWidget {
  final Set<String> tags;
  final ValueChanged<Set<String>> onTagsChanged;

  const TagEditor({
    super.key,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  late final TextEditingController _controller;

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

  void _addTag(String tag) {
    if (tag.trim().isEmpty) return;
    
    HapticFeedback.lightImpact();
    final newTags = Set<String>.from(widget.tags)..add(tag.trim());
    widget.onTagsChanged(newTags);
    _controller.clear();
  }

  void _removeTag(String tag) {
    HapticFeedback.lightImpact();
    final newTags = Set<String>.from(widget.tags)..remove(tag);
    widget.onTagsChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty) ...[
          _buildTagsDisplay(),
          const SizedBox(height: 12),
        ],
        _buildTagInput(),
      ],
    );
  }

  Widget _buildTagsDisplay() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.tags.map((tag) => _TagChip(
        tag: tag,
        onRemove: () => _removeTag(tag),
        color: colorScheme.primaryContainer,
        textColor: colorScheme.onPrimaryContainer,
      )).toList(),
    );
  }

  Widget _buildTagInput() {
    return BeautifulTextField(
      controller: _controller,
      label: 'Add Tags',
      hint: 'e.g., wholesale, priority, local',
      icon: Icons.sell_outlined,
      onSubmitted: _addTag,
      suffixIcon: IconButton(
        onPressed: () => _addTag(_controller.text),
        icon: const Icon(Icons.add_rounded),
        tooltip: 'Add tag',
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final VoidCallback onRemove;
  final Color color;
  final Color textColor;

  const _TagChip({
    required this.tag,
    required this.onRemove,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}