import 'package:flutter/material.dart';
import 'dart:ui';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Dialog base di GateKeeper con backdrop blur.
///
/// Wrappa [showDialog] con:
/// - [BackdropFilter] blur 12px sullo sfondo;
/// - bordo sottile [AppColors.border];
/// - border radius 20px;
/// - scroll interno se il contenuto è lungo.
///
/// Parametri:
/// - [title]: titolo visualizzato nell'header del dialog
/// - [child]: contenuto del dialog
/// - [actions]: bottoni in fondo (tipicamente Annulla + Conferma)
/// - [width]: larghezza massima (default 480)
///
/// Utilizzo:
/// ```dart
/// await GkDialog.show(
///   context: context,
///   title: 'Invite Member',
///   child: InviteForm(),
///   actions: [cancelBtn, confirmBtn],
/// );
/// ```
class GkDialog extends StatelessWidget {
  const GkDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.width = 480,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final double width;

  /// Helper statico per aprire il dialog con blur backdrop.
  ///
  /// [barrierDismissible] è true di default: tap fuori = chiude.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget> actions = const [],
    double width = 480,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      // Sfondo nero semitrasparente per il blur
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => GkDialog(
        title: title,
        child: child,
        actions: actions,
        width: width,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      // Effetto blur Glassmorphism sullo sfondo
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        // Rimuove l'elevation di default di Material
        elevation: 0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title, style: AppTextStyles.cardTitle),
                      ),
                      // Bottone X per chiudere
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),
                Divider(height: 1, color: AppColors.border),

                // ── Body (scrollabile se lungo) ──────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: child,
                  ),
                ),

                // ── Actions ─────────────────────────────────────────
                if (actions.isNotEmpty) ...
                  [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          for (int i = 0; i < actions.length; i++) ...
                            [
                              if (i > 0) const SizedBox(width: 10),
                              actions[i],
                            ],
                        ],
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
