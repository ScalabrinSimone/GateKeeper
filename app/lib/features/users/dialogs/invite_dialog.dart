import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';
import '../../../shared/widgets/gk_dialog.dart';
import '../../../shared/widgets/gk_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../users_screen.dart';

/// Dialog per invitare un nuovo membro nella casa.
///
/// Mostra un form con:
/// - nome utente;
/// - email;
/// - selezione ruolo tramite chip;
/// - bottoni Annulla / Invite.
///
/// TODO: collegare il bottone Invite a POST /api/users/invite
/// e gestire la risposta (successo = pop + refresh lista, errore = messaggio).
///
/// Utilizzo:
/// ```dart
/// await InviteDialog.show(context);
/// ```
class InviteDialog extends StatefulWidget {
  const InviteDialog({super.key});

  /// Apre il dialog con backdrop blur.
  static Future<void> show(BuildContext context) {
    return GkDialog.show(
      context: context,
      title: 'Invite Member',
      // Non usiamo child/actions di GkDialog perché il form
      // ha bisogno di gestire il suo stato interno con FormKey
      child: const _InviteForm(),
    );
  }

  @override
  State<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<InviteDialog> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ---------------------------------------------------------------------------
// Form interno
// ---------------------------------------------------------------------------

class _InviteForm extends StatefulWidget {
  const _InviteForm();

  @override
  State<_InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends State<_InviteForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Ruolo selezionato di default: adult
  UserRole _selectedRole = UserRole.adult;

  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // Mappa ruolo → etichetta mostrata nel chip
  static const _roleLabels = {
    UserRole.admin: 'Administrator',
    UserRole.adult: 'Manager',
    UserRole.child: 'Child / Guest',
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Vibrazione di errore se il form non è valido
      await HapticService.error();
      return;
    }

    setState(() => _loading = true);

    // TODO: chiamata reale → await ApiService.inviteUser(
    //   name: _nameCtrl.text,
    //   email: _emailCtrl.text,
    //   role: _selectedRole,
    // );
    //
    // Per ora simuliamo un ritardo di rete
    await Future<void>.delayed(const Duration(milliseconds: 800));

    await HapticService.success();

    if (mounted) {
      Navigator.of(context).pop(); // chiude il dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitation sent to ${_emailCtrl.text}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GkTextField(
            label: 'Name',
            hint: 'Full name',
            controller: _nameCtrl,
            prefixIcon: Icons.person_outline,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),

          GkTextField(
            label: 'Email',
            hint: 'user@home.local',
            controller: _emailCtrl,
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Selezione ruolo — chips interattivi
          Text('ROLE'.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: UserRole.values.map((role) {
              final selected = _selectedRole == role;
              return ChoiceChip(
                label: Text(_roleLabels[role]!),
                selected: selected,
                onSelected: (_) async {
                  await HapticService.light();
                  setState(() => _selectedRole = role);
                },
                selectedColor: AppColors.stormyTeal,
                backgroundColor: AppColors.panelSoft,
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.white
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                side: BorderSide(
                  color: selected
                      ? AppColors.stormyTeal
                      : AppColors.border,
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Bottoni azione
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Annulla
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 10),

              // Invite (con indicatore loading)
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.stormyTeal,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Send Invite'),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
