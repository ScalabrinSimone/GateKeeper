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

//Colori predefiniti per i tag personalizzati.
const _kTagColors = <Color>[
  AppColors.stormyTeal,
  AppColors.orangeGold,
  Color(0xFF7C4DFF),
  Color(0xFFE91E63),
  Color(0xFF00BCD4),
  Color(0xFF4CAF50),
  Color(0xFFFF5722),
  Color(0xFF607D8B),
];

//Sheet di creazione/modifica di un oggetto smart.
//Supporta:
//- inserimento manuale del tag RFID,
//- scansione automatica tramite polling /rfid/scan/latest,
//- categoria "personalizzato" con nome, colore e icona custom.
class ObjectFormSheet extends StatefulWidget {
  const ObjectFormSheet({super.key, this.editing});

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

  //Stato tag personalizzato (solo quando _category == ObjectCategory.other).
  IconData? _customIcon;
  Color _customColor = AppColors.stormyTeal;
  String _customTagLabel = '';

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
    } catch (_) {}
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

  Future<void> _openCustomTagPicker() async {
    final result = await showModalBottomSheet<_CustomTagResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CustomTagPickerSheet(
        initialLabel: _customTagLabel,
        initialColor: _customColor,
        initialIcon: _customIcon,
      ),
    );
    if (result != null) {
      setState(() {
        _customTagLabel = result.label;
        _customColor = result.color;
        _customIcon = result.icon;
        //Aggiorna il nome oggetto con il nome del tag se il nome è vuoto.
        if (_nameCtrl.text.isEmpty && result.label.isNotEmpty) {
          _nameCtrl.text = result.label;
        }
      });
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
              //Griglia categorie con chip animati.
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
                        customColor: c == ObjectCategory.other ? _customColor : null,
                        customIcon: c == ObjectCategory.other ? _customIcon : null,
                        customLabel: c == ObjectCategory.other && _customTagLabel.isNotEmpty
                            ? _customTagLabel
                            : null,
                        onTap: () async {
                          setState(() => _category = c);
                          if (c == ObjectCategory.other) {
                            await _openCustomTagPicker();
                          }
                        },
                      ),
                  ],
                ),
              ),
              //Mostra il riepilogo del tag personalizzato se selezionato.
              if (_category == ObjectCategory.other)
                _CustomTagSummary(
                  label: _customTagLabel,
                  color: _customColor,
                  icon: _customIcon,
                  onEdit: _openCustomTagPicker,
                ),
              //Toggle essenziale.
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
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.danger)),
                ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _tagCtrl,
                builder: (_, __) => GKButton(
                  onPressed:
                      (_busy || _tagCtrl.text.trim().isEmpty) ? null : _submit,
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

//Riepilogo tag personalizzato selezionato.
class _CustomTagSummary extends StatelessWidget {
  const _CustomTagSummary({
    required this.label,
    required this.color,
    required this.icon,
    required this.onEdit,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon ?? Icons.inventory_2_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.isNotEmpty ? label : l10n.t('customTagTitle'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      l10n.t('customTagHint'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_rounded, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

//Risultato del picker tag personalizzato.
class _CustomTagResult {
  _CustomTagResult({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData? icon;
}

//Bottom sheet per scegliere nome, colore e icona di un tag personalizzato.
class _CustomTagPickerSheet extends StatefulWidget {
  const _CustomTagPickerSheet({
    required this.initialLabel,
    required this.initialColor,
    required this.initialIcon,
  });

  final String initialLabel;
  final Color initialColor;
  final IconData? initialIcon;

  @override
  State<_CustomTagPickerSheet> createState() => _CustomTagPickerSheetState();
}

class _CustomTagPickerSheetState extends State<_CustomTagPickerSheet> {
  late final TextEditingController _labelCtrl;
  late Color _color;
  IconData? _icon;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.initialLabel);
    _color = widget.initialColor;
    _icon = widget.initialIcon;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon ?? Icons.inventory_2_rounded,
                        color: _color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.t('customTagTitle'),
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
              const SizedBox(height: 16),
              //Nome tag.
              GKTextField(
                controller: _labelCtrl,
                label: l10n.t('customTagName'),
                prefixIcon: Icons.badge_rounded,
              ),
              const SizedBox(height: 14),
              //Selezione colore.
              Text(
                l10n.t('customTagColor').toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _kTagColors.map((c) {
                  final selected = c == _color;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              //Selezione icona.
              Text(
                l10n.t('customTagIcon').toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _kPickableIcons.length,
                  itemBuilder: (_, i) {
                    final (icon, label) = _kPickableIcons[i];
                    final selected = icon == _icon;
                    return Tooltip(
                      message: label,
                      child: GestureDetector(
                        onTap: () => setState(() => _icon = icon),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: selected
                                ? _color.withValues(alpha: 0.2)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? _color : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: selected
                                ? _color
                                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(context).pop(_CustomTagResult(
                    label: _labelCtrl.text.trim(),
                    color: _color,
                    icon: _icon,
                  ));
                },
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  l10n.t('save'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
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

//Sezione tag RFID.
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
                  scanning
                      ? l10n.t('scanningTag')
                      : l10n.t('rfidTagRequiredHint'),
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
                      icon: scanning
                          ? Icons.stop_circle_rounded
                          : Icons.sensors_rounded,
                      variant: scanning
                          ? GKButtonVariant.danger
                          : (hasTagNow
                              ? GKButtonVariant.ghost
                              : GKButtonVariant.secondary),
                      expanded: true,
                      dense: true,
                    ),
                  ),
                  if (scanning) ...[
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.stormyTeal),
                    ),
                  ],
                ],
              ),
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
    this.customColor,
    this.customIcon,
    this.customLabel,
  });
  final ObjectCategory category;
  final bool selected;
  final VoidCallback onTap;
  final Color? customColor;
  final IconData? customIcon;
  final String? customLabel;

  IconData get _icon {
    if (category == ObjectCategory.other && customIcon != null) return customIcon!;
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
        return Icons.tune_rounded;
    }
  }

  String _label(AppL10n l10n) {
    if (category == ObjectCategory.other) {
      //Mostra il nome del tag personalizzato se impostato.
      if (customLabel != null && customLabel!.isNotEmpty) return customLabel!;
      return l10n.languageCode == 'it' ? 'Personalizzato' : 'Custom';
    }
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
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    //Per tag personalizzato usa il colore scelto dall'utente se selezionato.
    final accent = (category == ObjectCategory.other && customColor != null && selected)
        ? customColor!
        : AppColors.stormyTeal;

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
          color: (selected ? accent : AppColors.charcoalBlue).withValues(alpha: 0.08),
          border: Border.all(
            color: (selected ? accent : Colors.transparent).withValues(alpha: 0.45),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: 16,
              color: selected
                  ? accent
                  : theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 6),
            Text(
              _label(l10n),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected
                    ? accent
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Lista icone disponibili per i tag personalizzati.
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
  (Icons.tune_rounded, 'Personalizzato'),
  (Icons.diamond_rounded, 'Prezioso'),
  (Icons.local_florist_rounded, 'Pianta'),
  (Icons.attach_money_rounded, 'Denaro'),
  (Icons.electric_bolt_rounded, 'Energia'),
];

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
