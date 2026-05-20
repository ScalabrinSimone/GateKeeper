import 'package:flutter/material.dart';

import '../../../core/i18n/app_l10n.dart';
import '../../../core/state/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/notification_prefs_service.dart';
import '../../../shared/widgets/gk_button.dart';

//Bottom sheet per configurare le preferenze di notifica per una singola entità
//(membro o oggetto). Le preferenze sono salvate per l'utente loggato corrente,
//quindi ogni utente ha impostazioni indipendenti.
class NotifPrefsSheet extends StatefulWidget {
  const NotifPrefsSheet({
    super.key,
    required this.entityId,
    required this.entityName,
    required this.entityIcon,
  });

  final String entityId;
  final String entityName;
  final IconData entityIcon;

  @override
  State<NotifPrefsSheet> createState() => _NotifPrefsSheetState();
}

class _NotifPrefsSheetState extends State<NotifPrefsSheet> {
  EntityNotifPrefs _prefs = const EntityNotifPrefs();
  bool _loading = true;
  bool _saving = false;
  //Stato finestra oraria.
  bool _useTimeWindow = false;
  TimeOfDay _timeFrom = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _timeTo = const TimeOfDay(hour: 22, minute: 0);

  String get _viewerUserId =>
      AuthController.instance.user?.id.toString() ?? 'guest';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await NotificationPrefsService.instance
        .load(_viewerUserId, widget.entityId);
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _useTimeWindow = prefs.hasTimeWindow;
      if (prefs.timeFrom != null) {
        final parts = prefs.timeFrom!.split(':');
        _timeFrom = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 7,
            minute: int.tryParse(parts[1]) ?? 0);
      }
      if (prefs.timeTo != null) {
        final parts = prefs.timeTo!.split(':');
        _timeTo = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 22,
            minute: int.tryParse(parts[1]) ?? 0);
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = _prefs.copyWith(
      timeFrom: _useTimeWindow
          ? '${_timeFrom.hour.toString().padLeft(2, '0')}:${_timeFrom.minute.toString().padLeft(2, '0')}'
          : null,
      timeTo: _useTimeWindow
          ? '${_timeTo.hour.toString().padLeft(2, '0')}:${_timeTo.minute.toString().padLeft(2, '0')}'
          : null,
      clearTime: !_useTimeWindow,
    );
    await NotificationPrefsService.instance
        .save(_viewerUserId, widget.entityId, updated);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(updated);
  }

  Future<void> _pickTime(bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _timeFrom : _timeTo,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _timeFrom = picked;
        } else {
          _timeTo = picked;
        }
      });
    }
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.stormyTeal),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //Header.
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.stormyTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.entityIcon,
                            color: AppColors.stormyTeal, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('notifPrefsTitle'),
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              widget.entityName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  //Toggle entrata.
                  _PrefTile(
                    icon: Icons.login_rounded,
                    title: l10n.t('notifOnEntry'),
                    subtitle: l10n.t('notifOnEntryHint'),
                    value: _prefs.onEntry,
                    onChanged: (v) =>
                        setState(() => _prefs = _prefs.copyWith(onEntry: v)),
                  ),
                  const SizedBox(height: 10),
                  //Toggle uscita.
                  _PrefTile(
                    icon: Icons.logout_rounded,
                    title: l10n.t('notifOnExit'),
                    subtitle: l10n.t('notifOnExitHint'),
                    value: _prefs.onExit,
                    onChanged: (v) =>
                        setState(() => _prefs = _prefs.copyWith(onExit: v)),
                  ),
                  const SizedBox(height: 10),
                  //Finestra oraria.
                  _PrefTile(
                    icon: Icons.schedule_rounded,
                    title: l10n.t('notifTimeWindow'),
                    subtitle: _useTimeWindow
                        ? '${_fmtTime(_timeFrom)} – ${_fmtTime(_timeTo)}'
                        : l10n.t('notifTimeWindowHint'),
                    value: _useTimeWindow,
                    onChanged: (v) => setState(() => _useTimeWindow = v),
                  ),
                  if (_useTimeWindow) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TimePicker(
                            label: l10n.t('notifFrom'),
                            time: _timeFrom,
                            onTap: () => _pickTime(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimePicker(
                            label: l10n.t('notifTo'),
                            time: _timeTo,
                            onTap: () => _pickTime(false),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  GKButton(
                    onPressed: _saving ? null : _save,
                    label: _saving ? l10n.t('loadingDots') : l10n.t('save'),
                    icon: Icons.check_rounded,
                    expanded: true,
                  ),
                ],
              ),
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  const _PrefTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? AppColors.stormyTeal.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: value ? AppColors.stormyTeal : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    )),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.stormyTeal,
            activeTrackColor: AppColors.stormyTeal.withValues(alpha: 0.4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({required this.label, required this.time, required this.onTap});
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.stormyTeal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.stormyTeal.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.stormyTeal,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
