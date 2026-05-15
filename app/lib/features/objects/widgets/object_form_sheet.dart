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
//- inserimento manuale del tag RFID,
//- scansione automatica: si abilita una "modalità scan" che fa polling
//  sull'endpoint /rfid/scan/latest finché non arriva un nuovo tag o si annulla.
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

  //Stato della scansione.
  bool _scanning = false;
  Timer? _scanTimer;
  String? _previousTagBeforeScan;

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
    } on ApiException catch (e) {
      setState(() => _error = e.message);
      return;
    } catch (_) {
      _previousTagBeforeScan = null;
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
      if (latest.tag == _previousTagBeforeScan) return;
      //Nuovo tag: lo uso e fermo lo scan.
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
    if (name.isEmpty) {
      setState(() => _error = 'Nome obbligatorio');
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
          rfidTag: tag.isEmpty ? null : tag,
          category: _categoryToString(_category),
          isEssential: _essential,
        );
      } else {
        saved = await GateKeeperApi.instance.devices.update(int.parse(editing.id), {
          'name': name,
          if (tag.isNotEmpty) 'rfid_tag': tag,
          'category': _categoryToString(_category),
          'is_essential': _essential,
        });
      }
      //Consuma il tag dal buffer scan (se proveniva da scansione).
      if (tag.isNotEmpty) {
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
              //Riga tag + scan.
              Row(
                children: [
                  Expanded(
                    child: GKTextField(
                      controller: _tagCtrl,
                      label: l10n.t('rfidTagLabel'),
                      prefixIcon: Icons.wifi_tethering_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GKButton(
                    onPressed: _scanning ? _stopScan : _startScan,
                    label: _scanning ? l10n.t('stopScan') : l10n.t('startScan'),
                    icon: _scanning ? Icons.stop_circle_rounded : Icons.qr_code_scanner_rounded,
                    variant: _scanning ? GKButtonVariant.danger : GKButtonVariant.secondary,
                    dense: true,
                  ),
                ],
              ),
              if (_scanning)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.stormyTeal,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.t('scanningTag'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              //Categoria.
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
                        onTap: () => setState(() => _category = c),
                      ),
                  ],
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
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      fontStyle: FontStyle.italic,
                    )),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child:
                      Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ),
              const SizedBox(height: 10),
              GKButton(
                onPressed: _busy ? null : _submit,
                label: _busy
                    ? l10n.t('loadingDots')
                    : (isEdit ? l10n.t('save') : l10n.t('create')),
                icon: Icons.check_rounded,
                expanded: true,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
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
        return 'Keys';
      case ObjectCategory.wallet:
        return 'Wallet';
      case ObjectCategory.umbrella:
        return 'Umbrella';
      case ObjectCategory.bag:
        return 'Bag';
      case ObjectCategory.phone:
        return 'Phone';
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
