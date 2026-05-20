import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/api/api_exception.dart';
import '../../../data/api/dto.dart';
import '../../../data/gatekeeper_api.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/gk_button.dart';

//Sheet per editare i permessi granulari di un membro.
//Solo l'admin può aprirla; sull'admin stesso i toggle sono disabilitati.
class PermissionsSheet extends StatefulWidget {
  const PermissionsSheet({super.key, required this.user});

  final AppUser user;

  @override
  State<PermissionsSheet> createState() => _PermissionsSheetState();
}

class _PermissionsSheetState extends State<PermissionsSheet> {
  late Map<String, bool> _values;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _values = {
      for (final k in GKPermissions.all)
        k: widget.user.role == UserRole.admin
            ? true
            : (widget.user.permissions[k] ?? false),
    };
  }

  String _label(AppL10n l10n, String key) {
    switch (key) {
      case GKPermissions.canManageDevices:
        return l10n.t('permCanManageDevices');
      case GKPermissions.canManageUsers:
        return l10n.t('permCanManageUsers');
      case GKPermissions.canViewEvents:
        return l10n.t('permCanViewEvents');
      case GKPermissions.canManageInvites:
        return l10n.t('permCanManageInvites');
      case GKPermissions.canAcknowledgeAlerts:
        return l10n.t('permCanAcknowledgeAlerts');
      case GKPermissions.canConfigureHub:
        return l10n.t('permCanConfigureHub');
    }
    return key;
  }

  IconData _icon(String key) {
    switch (key) {
      case GKPermissions.canManageDevices:
        return Icons.inventory_2_rounded;
      case GKPermissions.canManageUsers:
        return Icons.group_rounded;
      case GKPermissions.canViewEvents:
        return Icons.history_rounded;
      case GKPermissions.canManageInvites:
        return Icons.person_add_alt_rounded;
      case GKPermissions.canAcknowledgeAlerts:
        return Icons.notifications_active_rounded;
      case GKPermissions.canConfigureHub:
        return Icons.router_rounded;
    }
    return Icons.shield_outlined;
  }

  Future<void> _save() async {
    if (widget.user.role == UserRole.admin) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await GateKeeperApi.instance.users
          .updatePermissions(int.parse(widget.user.id), _values);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(true);
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
    final isAdmin = widget.user.role == UserRole.admin;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.stormyTeal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${l10n.t('permissionsTitle')} · ${widget.user.name}',
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
            const SizedBox(height: 4),
            Text(
              isAdmin ? l10n.t('cannotEditAdminPerms') : l10n.t('permissionsHint'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 14),
            for (final key in GKPermissions.all)
              SwitchListTile.adaptive(
                value: _values[key] ?? false,
                onChanged: isAdmin
                    ? null
                    : (v) => setState(() => _values[key] = v),
                activeThumbColor: AppColors.stormyTeal,
                contentPadding: EdgeInsets.zero,
                secondary: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.stormyTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon(key), color: AppColors.stormyTeal),
                ),
                title: Text(_label(l10n, key),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ),
            const SizedBox(height: 8),
            GKButton(
              onPressed: _busy ? null : _save,
              label: _busy ? l10n.t('loadingDots') : l10n.t('savePermissions'),
              icon: Icons.check_rounded,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }
}
