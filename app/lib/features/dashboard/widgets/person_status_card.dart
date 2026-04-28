import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';

/// Modello di una persona nella card presenza.
///
/// Parametri:
/// - [name]: nome visualizzato
/// - [role]: ruolo (Admin, Manager, Child)
/// - [subtitle]: info aggiuntiva opzionale (es. 'Left at 07:45 AM')
/// - [isOnline]: true = pallino verde in home, false = pallino grigio (away)
class PersonEntry {
  const PersonEntry({
    required this.name,
    required this.role,
    this.subtitle,
    required this.isOnline,
  });

  final String name;
  final String role;
  final String? subtitle;
  final bool isOnline;
}

/// Card che mostra un gruppo di persone (chi è a casa / chi è fuori).
///
/// Parametri:
/// - [title]: titolo della sezione (es. 'Who is at Home')
/// - [people]: lista di [PersonEntry]
class PersonStatusCard extends StatelessWidget {
  const PersonStatusCard({
    super.key,
    required this.title,
    required this.people,
  });

  final String title;
  final List<PersonEntry> people;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...people.map(
            (person) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  // Avatar con pallino stato sovrapposto
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.panelSoft,
                        child: const Icon(Icons.person,
                            color: AppColors.textSecondary, size: 18),
                      ),
                      // Pallino verde (online) o grigio (offline)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: person.isOnline
                                ? AppColors.success
                                : AppColors.textMuted,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.panel, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          person.subtitle ?? person.role,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
