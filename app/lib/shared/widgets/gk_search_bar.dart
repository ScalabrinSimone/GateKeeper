import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Barra di ricerca con icona e campo testuale.
///
/// Parametri:
/// - [hint]: placeholder mostrato quando vuoto
/// - [onChanged]: callback invocata ad ogni carattere digitato
class GkSearchBar extends StatelessWidget {
  const GkSearchBar({
    super.key,
    this.hint = 'Search…',
    this.onChanged,
  });

  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
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
                // Rimuove tutto il padding/border di default del TextField
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
