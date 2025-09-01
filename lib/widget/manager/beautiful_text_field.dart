// lib/widgets/beautiful_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BeautifulTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool required;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final List<String>? autofillHints;
  final int? minLines;
  final int? maxLines;
  final bool alignLabelWithHint;
  final Function(String)? onSubmitted;

  const BeautifulTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.suffixIcon,
    this.required = false,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.autofillHints,
    this.minLines,
    this.maxLines,
    this.alignLabelWithHint = false,
    this.onSubmitted,
  });

  @override
  State<BeautifulTextField> createState() => _BeautifulTextFieldState();
}

class _BeautifulTextFieldState extends State<BeautifulTextField> {
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused 
              ? colorScheme.primary 
              : colorScheme.outline.withOpacity(0.3),
          width: _isFocused ? 2 : 1,
        ),
        color: colorScheme.surfaceContainerLow,
        boxShadow: _isFocused ? [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        autofillHints: widget.autofillHints,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        validator: widget.validator,
        onFieldSubmitted: widget.onSubmitted,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: widget.required ? '${widget.label} *' : widget.label,
          hintText: widget.hint,
          alignLabelWithHint: widget.alignLabelWithHint,
          prefixIcon: widget.icon != null 
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    widget.icon,
                    color: _isFocused ? colorScheme.primary : colorScheme.outline,
                    size: 22,
                  ),
                )
              : null,
          suffixIcon: widget.suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.icon != null ? 60 : 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: _isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
          errorStyle: TextStyle(
            color: colorScheme.error,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
        );
    
      }
    }