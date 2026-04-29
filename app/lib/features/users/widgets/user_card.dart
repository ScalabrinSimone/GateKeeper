// ============================================================
// UserCard — card per visualizzare un singolo utente
// ============================================================
//
// Usata nella lista dell'UsersScreen.
// Mostra: avatar iniziali, nome, ruolo, stato (dentro/fuori), MAC BLE.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/models.dart';

/// Card che mostra le informazioni di un [GkUser].
///
/// - [user]: l'utente da visualizzare
/// - [onEdit]: callback per aprire il dialog di modifica (null → nascondi)
/// - [onDelete]: callback per eliminare l'utente (null → nascondi)
/// - [animationIndex]: per lo stagger di entrata nella lista
///
/// Esempio:
/// ```dart
/// UserCard(
///   user: gkUser,
///   onEdit: AuthService.instance.isAdmin ? () => _openEdit(gkUser) : null,
///   onDelete: AuthService.instance.isAdmin ? () => _delete(gkUser) : null,
/// )
/// ```
class UserCard extends StatelessWidget {
  final GkUser user;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int animationIndex;

  const UserCard({
    super.key,
    required this.user,
    this.onEdit,
    this.onDelete,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colore del badge ruolo
    final roleColor = switch (user.role) {
      UserRole.admin => colorScheme.primary,
      UserRole.adult => colorScheme.tertiary,
      UserRole.child => colorScheme.secondary,
    };

    // Etichetta ruolo (TODO: localizzare)
    final roleLabel = switch (user.role) {
      UserRole.admin => 'Admin',
      UserRole.adult => 'Adulto',
      UserRole.child => 'Bambino',
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Avatar con le iniziali del nome
        leading: _buildAvatar(colorScheme),
        title: Text(
          user.displayName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            // Email
            Text(
              user.email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            // Riga badge: ruolo + stato presenza
            Row(
              children: [
                // Badge ruolo
                _buildBadge(roleLabel, roleColor, theme),
                const SizedBox(width: 6),
                // Badge stato presenza
                _buildBadge(
                  user.isHome ? 'Dentro' : 'Fuori',
                  user.isHome ? Colors.green.shade600 : colorScheme.error,
                  theme,
                ),
                // Icona BLE se dispositivo associato
                if (user.bleDeviceMac != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.bluetooth_connected_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ],
              ],
            ),
          ],
        ),
        // Menu azioni (solo se l'utente corrente è admin)
        trailing: (onEdit != null || onDelete != null)
            ? PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                itemBuilder: (_) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Modifica'),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_rounded,
                            size: 18,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Elimina',
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEdit?.call();
                  if (v == 'delete') onDelete?.call();
                },
              )
            : null,
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: animationIndex * 60),
          duration: 250.ms,
        )
        .slideX(
          begin: 0.05,
          end: 0,
          delay: Duration(milliseconds: animationIndex * 60),
          duration: 250.ms,
          curve: Curves.easeOutCubic,
        );
  }

  /// Avatar circolare con le iniziali del nome.
  Widget _buildAvatar(ColorScheme colorScheme) {
    // Prende la prima lettera del displayName
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 22,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  /// Badge colorato per ruolo/stato.
  Widget _buildBadge(String label, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
