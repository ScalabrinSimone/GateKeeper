import 'package:flutter/material.dart';

import '../../../core/models/models.dart'; // GkUser — modello core
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'user_card.dart';

/// Colonna per un gruppo di utenti con lo stesso ruolo.
///
/// Struttura (fedele al mockup Figma):
/// ```
/// ┌── Titolo ruolo ─────────────────── [N] ─┐
/// │   Descrizione ruolo                     │
/// │  ┌─ UserCard ─┐                         │
/// │  │ avatar ... │                         │
/// │  └────────────┘                         │
/// └─────────────────────────────────────────┘
/// ```
///
/// Parametri:
/// - [roleTitle]: es. 'Administrators'
/// - [roleDescription]: testo esplicativo sotto il titolo
/// - [users]: lista [GkUser] del ruolo (filtrata in UsersScreen)
class UserRoleColumn extends StatelessWidget {
  const UserRoleColumn({
    super.key,
    required this.roleTitle,
    required this.roleDescription,
    required this.users,
  });

  final String roleTitle;
  final String roleDescription;

  // Usa GkUser (core model) — non più HouseUser (era definita localmente
  // in users_screen.dart e causava type mismatch con UserCard che si
  // aspetta GkUser).
  final List<GkUser> users;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header colonna: titolo + badge count utenti
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                roleTitle,
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
            ),
            // Badge numerico con count utenti del ruolo
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.panelSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${users.length}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Descrizione del ruolo
        Text(
          roleDescription,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 16),

        // Lista card utenti — o stato vuoto se nessuno
        if (users.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.panelSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No members',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          // Passa il GkUser direttamente a UserCard (stesso tipo)
          ...users.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              // animationIndex per stagger di entrata nella lista
              child: UserCard(
                user: entry.value,
                animationIndex: entry.key,
              ),
            ),
          ),
      ],
    );
  }
}
