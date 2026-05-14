import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

//Campo di testo riusabile con stile GateKeeper.
class GKTextField extends StatelessWidget {
  const GKTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.validator,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final String? Function(String?)? validator;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        autofocus: autofocus,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        maxLength: maxLength,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          counterText: '',
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: AppColors.stormyTeal, size: 20)
              : null,
        ),
      ),
    );
  }
}
