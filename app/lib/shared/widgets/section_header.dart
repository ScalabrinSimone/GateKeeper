import 'package:flutter/material.dart';

//Header standard per le sezioni: titolo grande + sottotitolo + slot azioni opzionali.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null && actions!.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions!,
            ),
        ],
      ),
    );
  }
}
