import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Campo di testo stilizzato con la palette GateKeeper.
///
/// Parametri:
/// - [label]: etichetta sopra il campo
/// - [hint]: placeholder dentro il campo
/// - [controller]: [TextEditingController] da passare dall'esterno
/// - [validator]: funzione di validazione per Form widget
/// - [keyboardType]: tipo di tastiera (default text)
/// - [obscureText]: true per password
/// - [prefixIcon]: icona a sinistra dentro il campo
/// - [enabled]: false = campo disabilitato (read-only visivamente)
///
/// Utilizzo:
/// ```dart
/// GkTextField(
///   label: 'Email',
///   hint: 'user@home.local',
///   controller: _emailCtrl,
///   validator: (v) => v!.isEmpty ? 'Required' : null,
/// )
/// ```
class GkTextField extends StatelessWidget {
  const GkTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.enabled = true,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label sopra il campo
        Text(
          label.toUpperCase(),
          style: AppTextStyles.label,
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textMuted, size: 18)
                : null,
            filled: true,
            fillColor: AppColors.panelSoft,
            // Bordo normale
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            // Bordo quando il campo ha il focus
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              // NOTA: qui non possiamo usare `const` perché
              // AppColors.stormyTealBright è un getter non-const.
              borderSide: BorderSide(
                color: AppColors.stormyTealBright,
                width: 1.5,
              ),
            ),
            // Bordo in stato di errore
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            // Bordo disabilitato
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.4),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
