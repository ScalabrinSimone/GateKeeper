// ============================================================
// AddEditObjectDialog — dialog per aggiungere o modificare un oggetto RFID
// ============================================================
//
// Questo dialog viene aperto:
// - Dalla FAB (+) nell'ObjectsScreen: modalità "aggiungi"
// - Dal menu contestuale di un oggetto: modalità "modifica"
//
// In Flutter i dialog sono widget normali mostrati tramite showDialog().
// Ricevono dati via costruttore e comunicano il risultato
// tramite Navigator.pop(context, risultato).
//
// TODO: sostituire la chiamata fake con ApiService.createObject() / updateObject()

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/gk_text_field.dart';

/// Dialog per aggiungere un nuovo oggetto RFID o modificarne uno esistente.
///
/// Se [existingObject] è null, si apre in modalità "Aggiungi".
/// Se [existingObject] è fornito, si apre in modalità "Modifica" pre-compilata.
///
/// Restituisce il [RfidObject] creato/modificato tramite Navigator.pop,
/// oppure null se l'utente ha annullato.
///
/// Esempio d'uso:
/// ```dart
/// final result = await showDialog<RfidObject>(
///   context: context,
///   builder: (_) => const AddEditObjectDialog(),
/// );
/// if (result != null) {
///   // aggiorna la lista degli oggetti
/// }
/// ```
class AddEditObjectDialog extends StatefulWidget {
  /// Oggetto da modificare. Se null, il dialog è in modalità creazione.
  final RfidObject? existingObject;

  const AddEditObjectDialog({super.key, this.existingObject});

  @override
  State<AddEditObjectDialog> createState() => _AddEditObjectDialogState();
}

class _AddEditObjectDialogState extends State<AddEditObjectDialog> {
  // Chiave del Form: serve per validare tutti i campi insieme
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();

  // Valori dei dropdown con default sensati
  ObjectCategory _selectedCategory = ObjectCategory.other;
  bool _alertOnUnattendedExit = false;
  bool _isLoading = false;

  /// True se stiamo modificando un oggetto esistente (non creandone uno nuovo).
  bool get _isEditing => widget.existingObject != null;

  @override
  void initState() {
    super.initState();
    // Se stiamo modificando, precompila i campi con i valori attuali
    if (_isEditing) {
      _nameController.text = widget.existingObject!.name;
      // Il tag RFID non è modificabile in edit mode (chiave primaria)
      _tagController.text = widget.existingObject!.rfidTag;
      _selectedCategory = widget.existingObject!.category;
      _alertOnUnattendedExit = widget.existingObject!.alertOnUnattendedExit;
    }
  }

  @override
  void dispose() {
    // IMPORTANTE: fare sempre dispose dei TextEditingController per evitare memory leak
    _nameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // validate() scorre tutti i validator dei campi del Form
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Feedback aptico al tap del bottone di conferma
    HapticFeedback.lightImpact();

    try {
      final object = RfidObject(
        rfidTag: _tagController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        category: _selectedCategory,
        // Un oggetto appena creato è sempre "inside" per default
        status: widget.existingObject?.status ?? ObjectStatus.inside,
        // Assegna automaticamente all'utente loggato come proprietario
        // TODO: aggiungere dropdown per scegliere il proprietario (admin only)
        ownerId: AuthService.instance.currentUser?.id,
        alertOnUnattendedExit: _alertOnUnattendedExit,
      );

      // TODO: sostituire con ApiService.instance.createObject(object) o updateObject(object)
      final result = _isEditing
          ? await ApiService.instance.updateObject(object)
          : await ApiService.instance.createObject(object);

      if (mounted) {
        // pop(context, result) chiude il dialog E restituisce il valore
        // al chiamante (lo showDialog ritornerà questo valore come Future)
        Navigator.pop(context, result);
      }
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
      // Bordi arrotondati moderni
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
              // ─ Titolo dialog
              Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit_rounded : Icons.add_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEditing ? 'Modifica oggetto' : 'Aggiungi oggetto',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 200.ms),

              const SizedBox(height: 24),

              // ─ Campo nome
              GkTextField(
                controller: _nameController,
                label: 'Nome oggetto',
                hint: 'Es. Chiavi di casa, Ombrello nero…',
                prefixIcon: Icons.label_outline_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Il nome è obbligatorio';
                  }
                  if (v.trim().length < 2) {
                    return 'Almeno 2 caratteri';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ─ Campo tag RFID (disabilitato in edit mode)
              GkTextField(
                controller: _tagController,
                label: 'Tag RFID (EPC)',
                hint: 'Es. E200100860B20674',
                prefixIcon: Icons.nfc_rounded,
                // In edit mode il tag è la chiave primaria: non può cambiare
                enabled: !_isEditing,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Il tag RFID è obbligatorio';
                  }
                  // Formato EPC: stringa esadecimale di almeno 8 caratteri
                  if (v.trim().length < 8) {
                    return 'Tag RFID non valido (minimo 8 caratteri)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ─ Dropdown categoria
              Text(
                'Categoria',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ObjectCategory>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: ObjectCategory.values.map((cat) {
                  // TODO: sostituire con etichette localizzate da AppLocalizations
                  final labels = {
                    ObjectCategory.keys: '🔑 Chiavi',
                    ObjectCategory.umbrella: '☂️ Ombrello',
                    ObjectCategory.bag: '🎒 Borsa / Zaino',
                    ObjectCategory.electronics: '💻 Elettronica',
                    ObjectCategory.documents: '📄 Documenti',
                    ObjectCategory.clothing: '👕 Abbigliamento',
                    ObjectCategory.other: '📦 Altro',
                  };
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(labels[cat] ?? cat.name),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),

              const SizedBox(height: 16),

              // ─ Toggle notifica uscita non supervisionata
              SwitchListTile(
                value: _alertOnUnattendedExit,
                onChanged: (v) => setState(() => _alertOnUnattendedExit = v),
                title: const Text('Notifica uscita non supervisionata'),
                subtitle: const Text(
                  'Avvisa se questo oggetto esce senza un adulto',
                ),
                contentPadding: EdgeInsets.zero,
                activeColor: colorScheme.primary,
              ),

              const SizedBox(height: 24),

              // ─ Bottoni azione
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Annulla
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  // Conferma
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
                        : Text(_isEditing ? 'Salva' : 'Aggiungi'),
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
