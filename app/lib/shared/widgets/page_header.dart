import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

/// Header di pagina con titolo a sinistra e widget opzionale a destra.
///
/// Parametri:
/// - [title]: testo grande del titolo (es. 'Gateway Monitor')
/// - [trailing]: widget opzionale a destra (es. TopActionBar)
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: AppTextStyles.pageTitle),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
