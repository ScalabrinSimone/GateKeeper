// ============================================================
// AddEditUserDialog — dialog per aggiungere o modificare un utente
// ============================================================
//
// Aperto:
// - Dal FAB (+) nell'UsersScreen: modalità "Aggiungi"
// - Dal menu contestuale di un utente: modalità "Modifica"
//
// Solo gli utenti con ruolo admin possono aprire questo dialog.
// Viene controllato nel chiamante (UsersScreen).
//
// TODO: sostituire la chiamata fake con ApiService.createUser() / updateUser()

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/gk_text_field.dart';

/// Dialog per creare un nuovo utente o modificarne uno esistente.
///
/// - [existingUser]: utente da modificare. Se null → modalità creazione.
///
/// Restituisce il [GkUser] creato/modificato via Navigator.pop,
/// oppure null se l'utente ha annullato.
///
/// Esempio d'uso:
/// ```dart
/// final result = await showDialog<GkUser>(
///   context: context,
///   builder: (_) => AddEditUserDialog(existingUser: user),
/// );
/// if (result != null) { /* aggiorna la lista */ }
/// ```
class AddEditUserDialog extends StatefulWidget {
  final GkUser? existingUser;

  const AddEditUserDialog({super.key, this.existingUser});

  @override
  State<AddEditUserDialog> createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends State<AddEditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bleController = TextEditingController();

  UserRole _selectedRole = UserRole.adult;
  bool _isLoading = false;

  bool get _isEditing => widget.existingUser != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.existingUser!.displayName;
      _emailController.text = widget.existingUser!.email;
      _bleController.text = widget.existingUser!.bleDeviceMac ?? '';
      _selectedRole = widget.existingUser!.role;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final user = GkUser(
        // In creazione genera un ID temporaneo; il backend lo sovrascriverà
        id: widget.existingUser?.id ??
            'temp-${DateTime.now().millisecondsSinceEpoch}',
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        role: _selectedRole,
        bleDeviceMac: _bleController.text.trim().isEmpty
            ? null
            : _bleController.text.trim().toUpperCase(),
        isHome: widget.existingUser?.isHome ?? false,
        createdAt: widget.existingUser?.createdAt ?? DateTime.now(),
      );

      // TODO: sostituire con ApiService.instance.createUser(user) o updateUser(user)
      final result = _isEditing
          ? await ApiService.instance.updateUser(user)
          : await ApiService.instance.createUser(user);

      if (mounted) Navigator.pop(context, result);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─ Titolo
              Row(
                children: [
                  Icon(
                    _isEditing
                        ? Icons.person_rounded
                        : Icons.person_add_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEditing ? 'Modifica utente' : 'Nuovo utente',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 200.ms),

              const SizedBox(height: 24),

              // ─ Nome
              GkTextField(
                controller: _nameController,
                label: 'Nome',
                hint: 'Es. Mario, Mamma, Fratello…',
                prefixIcon: Icons.badge_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Il nome è obbligatorio';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ─ Email
              GkTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'nome@gatekeeper.local',
                prefixIcon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email obbligatoria';
                  // Validazione semplice: deve contenere @ e .
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Email non valida';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ─ Indirizzo MAC BLE (opzionale)
              GkTextField(
                controller: _bleController,
                label: 'MAC Address BLE (opzionale)',
                hint: 'Es. AA:BB:CC:DD:EE:FF',
                prefixIcon: Icons.bluetooth_rounded,
                // TODO: aggiungere scanner BLE per rilevare il MAC automaticamente
              ),

              const SizedBox(height: 16),

              // ─ Dropdown ruolo
              Text(
                'Ruolo',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: UserRole.values.map((role) {
                  // TODO: localizzare le etichette
                  final labels = {
                    UserRole.admin: '👑 Admin',
                    UserRole.adult: '👤 Adulto',
                    UserRole.child: '👶 Bambino',
                  };
                  final descriptions = {
                    UserRole.admin: 'Accesso completo',
                    UserRole.adult: 'Dashboard e notifiche',
                    UserRole.child: 'Solo visualizzazione',
                  };
                  return DropdownMenuItem(
                    value: role,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(labels[role] ?? role.name),
                        Text(
                          descriptions[role] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedRole = v);
                },
              ),

              const SizedBox(height: 24),

              // ─ Bottoni azione
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditing ? 'Salva' : 'Crea utente'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
