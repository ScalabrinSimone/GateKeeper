// ============================================================
// ObjectCard — card per visualizzare un singolo oggetto RFID
// ============================================================
//
// Usata nella griglia/lista dell'ObjectsScreen.
// Mostra: emoji categoria, nome, stato, tag RFID, last seen.
//
// In Flutter le card sono widget "presentazionali" (stateless):
// ricevono i dati e comunicano le azioni tramite callback.
// Non gestiscono stato interno né chiamate API direttamente.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/models.dart';

/// Card che mostra le informazioni di un [RfidObject].
///
/// Parametri:
/// - [object]: l'oggetto da visualizzare
/// - [onEdit]: callback chiamato quando l'utente tocca "Modifica"
/// - [onDelete]: callback chiamato quando l'utente tocca "Elimina"
/// - [animationIndex]: indice nella lista, usato per lo stagger dell'animazione
///   (ogni card entra con un ritardo crescente per un effetto a cascata)
///
/// Esempio d'uso:
/// ```dart
/// ObjectCard(
///   object: myObject,
///   onEdit: () => _openEditDialog(myObject),
///   onDelete: () => _deleteObject(myObject.rfidTag),
///   animationIndex: 0,
/// )
/// ```
class ObjectCard extends StatelessWidget {
  final RfidObject object;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Indice per stagger animation: la card N entra dopo N*50ms
  final int animationIndex;

  const ObjectCard({
    super.key,
    required this.object,
    this.onEdit,
    this.onDelete,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colore e icona dello stato (dentro/fuori/sconosciuto)
    final (statusColor, statusLabel) = switch (object.status) {
      ObjectStatus.inside => (Colors.green.shade600, 'Dentro'),
      ObjectStatus.outside => (colorScheme.error, 'Fuori'),
      ObjectStatus.unknown => (colorScheme.onSurfaceVariant, 'Sconosciuto'),
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          // Bordo accent se fuori casa, normale altrimenti
          color: object.status == ObjectStatus.outside
              ? colorScheme.error.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
          width: object.status == ObjectStatus.outside ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─ Riga superiore: emoji + menu
              Row(
                children: [
                  // Emoji categoria in un cerchio
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      object.categoryEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const Spacer(),
                  // Badge stato (Dentro/Fuori)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Menu 3 puntini (solo per admin)
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      iconSize: 18,
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
                      onSelected: (value) {
                        if (value == 'edit') onEdit?.call();
                        if (value == 'delete') onDelete?.call();
                      },
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ─ Nome oggetto
              Text(
                object.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // ─ Tag RFID (in piccolo, stile monospace)
              Text(
                object.rfidTag,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // ─ Last seen (se disponibile)
              if (object.lastSeenAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatLastSeen(object.lastSeenAt!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              // ─ Icona campanella se alert attivo
              if (object.alertOnUnattendedExit) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      size: 12,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Notifiche attive',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    )
        // Animazione di entrata con stagger basato sull'indice
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: animationIndex * 50),
          duration: 300.ms,
        )
        .slideY(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: animationIndex * 50),
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }

  /// Formatta il timestamp "last seen" in modo leggibile.
  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inMinutes < 1) return 'Visto ora';
    if (diff.inMinutes < 60) return 'Visto ${diff.inMinutes}m fa';
    if (diff.inHours < 24) return 'Visto ${diff.inHours}h fa';
    return 'Visto ${diff.inDays}g fa';
  }
}
