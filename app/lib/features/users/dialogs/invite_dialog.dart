import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/haptic_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../users_screen.dart';

// ---------------------------------------------------------------------------
// InviteDialog — fedele al mockup Figma
// ---------------------------------------------------------------------------
//
// Struttura del dialog (come da mockup):
//
//   ┌─ Invite New Member ─────────────────── ✕ ─┐
//   │ Generate an invite link to add a new       │
//   │ person. As Admin you can choose the role.  │
//   │                                            │
//   │  Select Role                               │
//   │  ┌─────────────────────────────────────┐  │
//   │  │ Manager                          ▼  │  │
//   │  └─────────────────────────────────────┘  │
//   │                                            │
//   │  Permissions Preview                       │
//   │  ── View History                           │
//   │  ── Edit Object Tags                       │
//   │  ── Dismiss Alerts                         │
//   │  ✕ Cannot Manage Users                     │
//   │                                            │
//   │  Invite Link                               │
//   │  ┌──────────────────────────── [Copy] ┐   │
//   │  │ https://gatekeeper.local/m/...     │   │
//   │  └────────────────────────────────────┘   │
//   │                         [Generate Link]    │
//   └────────────────────────────────────────────┘

/// Dialog per invitare un nuovo membro nella casa.
///
/// Segue esattamente il design Figma:
/// 1. Dropdown per selezionare il ruolo
/// 2. Preview dei permessi associati al ruolo scelto
/// 3. Link di invito generabile e copiabile
///
/// TODO: collegare [_generateLink] a POST /api/users/invite
/// che dovrà restituire un token one-time e costruire il link.
///
/// Utilizzo:
/// ```dart
/// await InviteDialog.show(context);
/// ```
class InviteDialog {
  /// Apre il dialog centrato con sfondo scuro semi-trasparente.
  ///
  /// Usa [showDialog] con [barrierDismissible] = true (tap fuori chiude).
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: true,
      builder: (_) => const _InviteDialogWidget(),
    );
  }
}

class _InviteDialogWidget extends StatefulWidget {
  const _InviteDialogWidget();

  @override
  State<_InviteDialogWidget> createState() => _InviteDialogWidgetState();
}

class _InviteDialogWidgetState extends State<_InviteDialogWidget> {
  // Ruolo selezionato di default
  UserRole _selectedRole = UserRole.adult;

  // Link generato (null = non ancora generato)
  String? _generatedLink;

  // Stato loading del bottone Generate
  bool _generating = false;

  // true quando il link è stato copiato (mostra feedback temporaneo)
  bool _copied = false;

  // ── Mappa ruolo → label mostrata nel dropdown ──
  static const _roleLabels = {
    UserRole.admin: 'Administrator',
    UserRole.adult: 'Manager',
    UserRole.child: 'Child / Guest',
  };

  // ── Mappa ruolo → permessi mostrati nella preview ──
  // Ogni permesso ha: testo + granted (true = check verde, false = x rosso)
  static const _rolePermissions = <UserRole, List<({String label, bool granted})>>{
    UserRole.admin: [
      (label: 'Full Control', granted: true),
      (label: 'Manage Users', granted: true),
      (label: 'Alert Configuration', granted: true),
      (label: 'Cannot Manage Users', granted: false), // non applicabile
    ],
    UserRole.adult: [
      (label: 'View History', granted: true),
      (label: 'Edit Object Tags', granted: true),
      (label: 'Dismiss Alerts', granted: true),
      (label: 'Cannot Manage Users', granted: false),
    ],
    UserRole.child: [
      (label: 'BLE Tracking Only', granted: true),
      (label: 'View Own History', granted: true),
      (label: 'Cannot Change Settings', granted: false),
      (label: 'Cannot View Sensitive Alerts', granted: false),
    ],
  };

  /// Simula la generazione del link di invito.
  ///
  /// TODO: sostituire con chiamata reale:
  /// ```dart
  /// final response = await ApiService.generateInviteLink(role: _selectedRole);
  /// setState(() => _generatedLink = response.inviteUrl);
  /// ```
  Future<void> _generateLink() async {
    setState(() => _generating = true);
    await HapticService.light();

    // Stub: simula latenza di rete
    await Future<void>.delayed(const Duration(milliseconds: 700));

    // Genera un "token" fake per il mockup
    final roleSlug = _selectedRole.name;
    setState(() {
      _generatedLink =
          'https://gatekeeper.local/m/${roleSlug.substring(0, 2)}6b3-2d9f';
      _generating = false;
    });

    await HapticService.success();
  }

  /// Copia il link negli appunti e mostra feedback temporaneo.
  Future<void> _copyLink() async {
    if (_generatedLink == null) return;
    await Clipboard.setData(ClipboardData(text: _generatedLink!));
    await HapticService.success();
    setState(() => _copied = true);
    // Reset del feedback dopo 2 secondi
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final permissions = _rolePermissions[_selectedRole]!;

    return Dialog(
      // Larghezza massima come nel mockup (~420px)
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      backgroundColor: AppColors.panel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Invite New Member',
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                  // Bottone chiudi
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Generate an invite link to add a new person to the house. '
                'As an Admin, you can choose their role below.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // ── Select Role ───────────────────────────────────────────
              Text('Select Role', style: AppTextStyles.label),
              const SizedBox(height: 8),
              // DropdownButtonFormField: più fedele al mockup rispetto ai chips
              Container(
                decoration: BoxDecoration(
                  color: AppColors.panelSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole>(
                    value: _selectedRole,
                    isExpanded: true,
                    dropdownColor: AppColors.panel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                    // Al cambio ruolo: resetta il link generato (non è più valido)
                    onChanged: (role) async {
                      if (role == null) return;
                      await HapticService.light();
                      setState(() {
                        _selectedRole = role;
                        _generatedLink = null; // link invalidato
                        _copied = false;
                      });
                    },
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(_roleLabels[role]!),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Permissions Preview ───────────────────────────────────
              Text('Permissions Preview', style: AppTextStyles.label),
              const SizedBox(height: 10),
              // Lista animata: si aggiorna quando cambia il ruolo
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Column(
                  // La key cambia con il ruolo → AnimatedSwitcher fa fade
                  key: ValueKey(_selectedRole),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: permissions.map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            p.granted ? Icons.check : Icons.close,
                            size: 14,
                            color: p.granted
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: p.granted
                                  ? AppColors.textSecondary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // ── Invite Link ───────────────────────────────────────────
              Text('Invite Link', style: AppTextStyles.label),
              const SizedBox(height: 8),
              // Campo link: visibile solo se il link è stato generato
              if (_generatedLink != null) ...
                [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.panelSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Text(
                              _generatedLink!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Bottone Copy con feedback visivo
                        GestureDetector(
                          onTap: _copyLink,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _copied
                                  ? AppColors.success
                                  : AppColors.stormyTeal,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _copied ? 'Copied!' : 'Copy',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

              // ── Bottone Generate Link ─────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _generating ? null : _generateLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.stormyTeal,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      // Testo cambia dopo la prima generazione
                      : Text(
                          _generatedLink == null
                              ? 'Generate Link'
                              : 'Regenerate',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
