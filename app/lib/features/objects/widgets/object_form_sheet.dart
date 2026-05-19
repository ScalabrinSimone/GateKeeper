import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/api/api_exception.dart';
import '../../../data/api/dto.dart';
import '../../../data/gatekeeper_api.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/smart_object.dart';
import '../../../shared/widgets/gk_button.dart';
import '../../auth/widgets/gk_text_field.dart';

//Sheet di creazione/modifica di un oggetto smart.
//Supporta:
//- inserimento manuale del tag RFID (utile se non si ha il lettore connesso),
//- scansione automatica tramite polling /rfid/scan/latest,
//- selezione icona personalizzata per il tipo di oggetto.
class ObjectFormSheet extends StatefulWidget {
  const ObjectFormSheet({super.key, this.editing});

  //Se valorizzato, il form è in modalità modifica.
  final SmartObject? editing;

  @override
  State<ObjectFormSheet> createState() => _ObjectFormSheetState();
}

class _ObjectFormSheetState extends State<ObjectFormSheet> {
  final _nameCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  ObjectCategory _category = ObjectCategory.other;
  bool _essential = false;
  bool _busy = false;
  String? _error;

  //Icona personalizzata (solo per categoria "other").
  IconData? _customIcon;

  //Stato della scansione.
  bool _scanning = false;
  Timer? _scanTimer;
  String? _previousTagBeforeScan;
  String? _previousSeenAtBeforeScan;

  //Modalità input tag: scan o manuale.
  bool _manualTagInput = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _tagCtrl.text = e.rfidTag;
      _category = e.category;
      _essential = e.isEssential;
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _nameCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    //Memorizzo l'ultimo tag noto del backend per riconoscere "il prossimo nuovo".
    try {
      final latest = await GateKeeperApi.instance.rfid.latest();
      _previousTagBeforeScan = latest?.tag;
      _previousSeenAtBeforeScan = latest?.seenAt;
    } on ApiException catch (e) {
      setState(() => _error = e.message);
      return;
    } catch (_) {
      _previousTagBeforeScan = null;
      _previousSeenAtBeforeScan = null;
    }
    setState(() {
      _scanning = true;
      _error = null;
    });
    HapticFeedback.lightImpact();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 800), (_) => _pollScan());
  }

  Future<void> _pollScan() async {
    try {
      final latest = await GateKeeperApi.instance.rfid.latest();
      if (latest == null) return;
      final isNewTag = latest.tag != _previousTagBeforeScan;
      final isSameTagRescanned = latest.tag == _previousTagBeforeScan &&
          latest.seenAt != _previousSeenAtBeforeScan;
      if (!isNewTag && !isSameTagRescanned) return;
      _scanTimer?.cancel();
      _scanTimer = null;
      if (!mounted) return;
      setState(() {
        _tagCtrl.text = latest.tag;
        _scanning = false;
      });
      HapticFeedback.selectionClick();
    } catch (_) {
      //In caso di errore durante polling, ignoro questo tick.
    }
  }

  void _stopScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
    setState(() => _scanning = false);
  }

  Future<void> _submit() async {
    if (_busy) return;
    final name = _nameCtrl.text.trim();
    final tag = _tagCtrl.text.trim();
    final l10n = AppL10n.of(context);
    if (name.isEmpty) {
      setState(() => _error = l10n.t('objectNameRequired'));
      return;
    }
    if (tag.isEmpty) {
      setState(() => _error = l10n.t('rfidTagRequired'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      DeviceDto saved;
      final editing = widget.editing;
      if (editing == null) {
        saved = await GateKeeperApi.instance.devices.create(
          name: name,
          rfidTag: tag,
          category: _categoryToString(_category),
          isEssential: _essential,
        );
      } else {
        saved = await GateKeeperApi.instance.devices.update(int.parse(editing.id), {
          'name': name,
          'rfid_tag': tag,
          'category': _categoryToString(_category),
          'is_essential': _essential,
        });
      }
      //Consuma il tag dal buffer scan (solo se era una scansione automatica).
      if (!_manualTagInput && tag.isNotEmpty) {
        try {
          await GateKeeperApi.instance.rfid.consume(tag);
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.of(context).pop<DeviceDto>(saved);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final isEdit = widget.editing != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 18,
          right: 18,
          top: 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(isEdit ? Icons.edit_rounded : Icons.add_circle_rounded,
                      color: AppColors.stormyTeal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEdit ? l10n.t('editObject') : l10n.t('addObject'),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GKTextField(
                controller: _nameCtrl,
                label: l10n.t('objectName'),
                prefixIcon: Icons.label_rounded,
              ),
              const SizedBox(height: 8),
              //Sezione tag RFID con toggle modalità.
              _RfidTagSection(
                controller: _tagCtrl,
                scanning: _scanning,
                manualInput: _manualTagInput,
                onStart: _startScan,
                onStop: _stopScan,
                onToggleManual: () => setState(() {
                  _manualTagInput = !_manualTagInput;
                  if (_manualTagInput) _stopScan();
                }),
              ),
              const SizedBox(height: 6),
              //Categoria con chip.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in ObjectCategory.values)
                      _CategoryChip(
                        category: c,
                        selected: c == _category,
                        onTap: () => setState(() {
                          _category = c;
                          //Reset icona personalizzata se non è "other".
                          if (c != ObjectCategory.other) _customIcon = null;
                        }),
                      ),
                  ],
                ),
              ),
              //Selezione icona personalizzata (solo per "altro").
              if (_category == ObjectCategory.other)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _IconPickerRow(
                    selected: _customIcon,
                    onPick: (icon) => setState(() => _customIcon = icon),
                  ),
                ),
              //Essenziale.
              SwitchListTile.adaptive(
                value: _essential,
                onChanged: (v) => setState(() => _essential = v),
                activeThumbColor: AppColors.stormyTeal,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.t('essential'),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                subtitle: Text(l10n.t('essentialHint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      fontStyle: FontStyle.italic,
                    )),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _tagCtrl,
                builder: (_, __) => GKButton(
                  onPressed: (_busy || _tagCtrl.text.trim().isEmpty) ? null : _submit,
                  label: _busy
                      ? l10n.t('loadingDots')
                      : (isEdit ? l10n.t('save') : l10n.t('create')),
                  icon: Icons.check_rounded,
                  expanded: true,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

//Sezione tag RFID con toggle tra modalità scan e manuale.
class _RfidTagSection extends StatelessWidget {
  const _RfidTagSection({
    required this.controller,
    required this.scanning,
    required this.manualInput,
    required this.onStart,
    required this.onStop,
    required this.onToggleManual,
  });

  final TextEditingController controller;
  final bool scanning;
  final bool manualInput;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onToggleManual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);

    if (manualInput) {
      //Modalità manuale: campo editabile.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.t('rfidTagLabel'),
              prefixIcon: const Icon(Icons.qr_code_2_rounded, color: AppColors.stormyTeal),
              hintText: 'Es. E2000017221101...',
              suffixIcon: ValueListenableBuilder(
                valueListenable: controller,
                builder: (_, v, __) => v.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: controller.clear,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: onToggleManual,
            icon: const Icon(Icons.sensors_rounded, size: 18),
            label: Text(l10n.t('startScan')),
          ),
        ],
      );
    }

    //Modalità scan.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasTagNow = controller.text.trim().isNotEmpty;
        final c = hasTagNow ? AppColors.success : AppColors.orangeGold;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.06),
            border: Border.all(color: c.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    hasTagNow ? Icons.check_circle_rounded : Icons.qr_code_2_rounded,
                    color: c,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasTagNow
                        ? l10n.t('tagScanned').toUpperCase()
                        : l10n.t('rfidTagLabel').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w900,
                      color: c,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (hasTagNow)
                SelectableText(
                  controller.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                )
              else
                Text(
                  scanning ? l10n.t('scanningTag') : l10n.t('rfidTagRequiredHint'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GKButton(
                      onPressed: scanning ? onStop : onStart,
                      label: scanning
                          ? l10n.t('stopScan')
                          : (hasTagNow ? l10n.t('rescanTag') : l10n.t('startScan')),
                      icon: scanning ? Icons.stop_circle_rounded : Icons.sensors_rounded,
                      variant: scanning
                          ? GKButtonVariant.danger
                          : (hasTagNow ? GKButtonVariant.ghost : GKButtonVariant.secondary),
                      expanded: true,
                      dense: true,
                    ),
                  ),
                  if (scanning) ...[
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.stormyTeal),
                    ),
                  ],
                ],
              ),
              //Link per passare all'inserimento manuale.
              const SizedBox(height: 4),
              TextButton(
                onPressed: onToggleManual,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                child: Text(
                  l10n.t('enterTagManually'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });
  final ObjectCategory category;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (category) {
      case ObjectCategory.keys:
        return Icons.vpn_key_rounded;
      case ObjectCategory.wallet:
        return Icons.account_balance_wallet_rounded;
      case ObjectCategory.umbrella:
        return Icons.umbrella_rounded;
      case ObjectCategory.bag:
        return Icons.work_rounded;
      case ObjectCategory.phone:
        return Icons.smartphone_rounded;
      case ObjectCategory.other:
        return Icons.inventory_2_rounded;
    }
  }

  String _label(AppL10n l10n) {
    switch (category) {
      case ObjectCategory.keys:
        return l10n.languageCode == 'it' ? 'Chiavi' : 'Keys';
      case ObjectCategory.wallet:
        return l10n.languageCode == 'it' ? 'Portafoglio' : 'Wallet';
      case ObjectCategory.umbrella:
        return l10n.languageCode == 'it' ? 'Ombrello' : 'Umbrella';
      case ObjectCategory.bag:
        return l10n.languageCode == 'it' ? 'Borsa' : 'Bag';
      case ObjectCategory.phone:
        return l10n.languageCode == 'it' ? 'Telefono' : 'Phone';
      case ObjectCategory.other:
        return l10n.languageCode == 'it' ? 'Altro' : 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (selected ? AppColors.stormyTeal : AppColors.charcoalBlue)
              .withValues(alpha: 0.08),
          border: Border.all(
            color: (selected ? AppColors.stormyTeal : Colors.transparent)
                .withValues(alpha: 0.45),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon,
                size: 16,
                color: selected
                    ? AppColors.stormyTeal
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55)),
            const SizedBox(width: 6),
            Text(_label(l10n),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? AppColors.stormyTeal
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                )),
          ],
        ),
      ),
    );
  }
}

//Lista icone disponibili per gli oggetti personalizzati.
const _kPickableIcons = <(IconData, String)>[
  (Icons.inventory_2_rounded, 'Oggetto'),
  (Icons.star_rounded, 'Stella'),
  (Icons.favorite_rounded, 'Cuore'),
  (Icons.watch_rounded, 'Orologio'),
  (Icons.headphones_rounded, 'Cuffie'),
  (Icons.camera_alt_rounded, 'Fotocamera'),
  (Icons.laptop_rounded, 'Laptop'),
  (Icons.tablet_rounded, 'Tablet'),
  (Icons.book_rounded, 'Libro'),
  (Icons.sports_soccer_rounded, 'Sport'),
  (Icons.medical_services_rounded, 'Medicinali'),
  (Icons.pets_rounded, 'Animale'),
  (Icons.directions_car_rounded, 'Auto'),
  (Icons.music_note_rounded, 'Musica'),
  (Icons.sports_esports_rounded, 'Gaming'),
  (Icons.luggage_rounded, 'Valigia'),
  (Icons.shopping_bag_rounded, 'Shopping'),
  (Icons.emoji_food_beverage_rounded, 'Borraccia'),
  (Icons.child_friendly_rounded, 'Bambino'),
  (Icons.celebration_rounded, 'Evento'),
  (Icons.lock_rounded, 'Lucchetto'),
  (Icons.folder_rounded, 'Cartella'),
  (Icons.build_rounded, 'Attrezzo'),
  (Icons.kitchen_rounded, 'Cucina'),
  (Icons.sports_gymnastics_rounded, 'Palestra'),
];

//Riga di selezione icona + pulsante apertura picker.
class _IconPickerRow extends StatelessWidget {
  const _IconPickerRow({required this.selected, required this.onPick});
  final IconData? selected;
  final ValueChanged<IconData> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () async {
        final picked = await showDialog<IconData>(
          context: context,
          builder: (ctx) => _IconPickerDialog(current: selected),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.stormyTeal.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.stormyTeal.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.stormyTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                selected ?? Icons.inventory_2_rounded,
                color: AppColors.stormyTeal,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Icona personalizzata',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.stormyTeal,
                    ),
                  ),
                  Text(
                    'Tocca per scegliere',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.stormyTeal),
          ],
        ),
      ),
    );
  }
}

//Dialogo griglia icone picker.
class _IconPickerDialog extends StatelessWidget {
  const _IconPickerDialog({this.current});
  final IconData? current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Scegli un\'icona'),
      content: SizedBox(
        width: 360,
        height: 380,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _kPickableIcons.length,
          itemBuilder: (_, i) {
            final (icon, label) = _kPickableIcons[i];
            final isSelected = icon == current;
            return Tooltip(
              message: label,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(icon),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.stormyTeal.withValues(alpha: 0.2)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.stormyTeal
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppColors.stormyTeal
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 28,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
      ],
    );
  }
}

String _categoryToString(ObjectCategory c) {
  switch (c) {
    case ObjectCategory.keys:
      return 'keys';
    case ObjectCategory.wallet:
      return 'wallet';
    case ObjectCategory.umbrella:
      return 'umbrella';
    case ObjectCategory.bag:
      return 'bag';
    case ObjectCategory.phone:
      return 'phone';
    case ObjectCategory.other:
      return 'other';
  }
}
