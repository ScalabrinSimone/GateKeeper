import 'package:flutter/material.dart';

import '../../../core/models/models.dart'; // ObjectCategory — definita in rfid_object.dart
import '../../../core/services/haptic_service.dart';
import '../../../shared/widgets/gk_dialog.dart';
import '../../../shared/widgets/gk_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

// NOTA: ObjectCategory è definita in core/models/rfid_object.dart ed esportata
// via core/models/models.dart. NON ridefinirla qui — causerebbe ambiguous_import
// in qualsiasi file che importa sia questo dialog che core/models.

/// Dialog per aggiungere un nuovo oggetto RFID al sistema.
///
/// L'utente inserisce:
/// - nome oggetto (es. "Chiavi auto");
/// - categoria (chip selector, valori da [ObjectCategory]);
/// - UID tag RFID (inserito manualmente — in futuro via lettore RFID);
/// - note opzionali.
///
/// TODO: collegare a POST /api/objects con body:
/// ```json
/// { "name": "...", "category": "...", "rfid_uid": "...", "notes": "..." }
/// ```
///
/// TODO (futuro): bottone "Scan Tag" che attiva il lettore RFID
/// via WebSocket e inserisce automaticamente l'UID nel campo.
///
/// Utilizzo:
/// ```dart
/// await AddObjectDialog.show(context);
/// ```
class AddObjectDialog {
  /// Apre il dialog con backdrop blur.
  static Future<void> show(BuildContext context) {
    return GkDialog.show(
      context: context,
      title: 'Add RFID Object',
      child: const _AddObjectForm(),
      width: 500,
    );
  }
}

// ---------------------------------------------------------------------------
// Form interno
// ---------------------------------------------------------------------------

class _AddObjectForm extends StatefulWidget {
  const _AddObjectForm();

  @override
  State<_AddObjectForm> createState() => _AddObjectFormState();
}

class _AddObjectFormState extends State<_AddObjectForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _uidCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Categoria di default
  ObjectCategory _selectedCategory = ObjectCategory.other;
  bool _loading = false;

  // Mappa categoria → (icona, etichetta) per il chip selector.
  // Usa i valori di ObjectCategory dal core model:
  //   keys, umbrella, bag, electronics, documents, clothing, other
  static const _categories = <ObjectCategory, (IconData, String)>{
    ObjectCategory.keys:        (Icons.vpn_key_outlined,                'Keys'),
    ObjectCategory.bag:         (Icons.backpack_outlined,               'Bag'),
    ObjectCategory.umbrella:    (Icons.umbrella_outlined,               'Umbrella'),
    ObjectCategory.electronics: (Icons.devices_outlined,                'Electronics'),
    ObjectCategory.documents:   (Icons.description_outlined,            'Documents'),
    ObjectCategory.clothing:    (Icons.checkroom_outlined,              'Clothing'),
    ObjectCategory.other:       (Icons.category_outlined,               'Other'),
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _uidCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      await HapticService.error();
      return;
    }

    setState(() => _loading = true);

    // TODO: await ApiService.addObject(
    //   name: _nameCtrl.text,
    //   category: _selectedCategory.name,
    //   rfidUid: _uidCtrl.text,
    //   notes: _notesCtrl.text,
    // );
    await Future<void>.delayed(const Duration(milliseconds: 700));

    await HapticService.success();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${_nameCtrl.text}" added successfully'),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GkTextField(
            label: 'Object Name',
            hint: 'e.g. House Keys',
            controller: _nameCtrl,
            prefixIcon: Icons.label_outline,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),

          // Chip selector per la categoria
          Text('CATEGORY', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ObjectCategory.values.map((cat) {
              final (icon, label) = _categories[cat]!;
              final selected = _selectedCategory == cat;
              return ChoiceChip(
                avatar: Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? AppColors.white
                      : AppColors.textSecondary,
                ),
                label: Text(label),
                selected: selected,
                onSelected: (_) async {
                  await HapticService.light();
                  setState(() => _selectedCategory = cat);
                },
                selectedColor: AppColors.stormyTeal,
                backgroundColor: AppColors.panelSoft,
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.white
                      : AppColors.textSecondary,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: selected ? AppColors.stormyTeal : AppColors.border,
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // UID RFID — in futuro compilato automaticamente dal lettore
          GkTextField(
            label: 'RFID Tag UID',
            hint: 'e.g. E2 00 34 12 01 75 9A BC',
            controller: _uidCtrl,
            prefixIcon: Icons.nfc_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'UID is required' : null,
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Icon(Icons.info_outline, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 6),
              const Text(
                'Scan Tag (futuro): lettore RFID via WebSocket',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          GkTextField(
            label: 'Notes (optional)',
            hint: 'Any extra info...',
            controller: _notesCtrl,
          ),
          const SizedBox(height: 24),

          // Azioni
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 10),
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
                    : const Text('Add Object'),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
