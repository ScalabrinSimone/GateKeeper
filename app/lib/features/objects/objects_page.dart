import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/api_exception.dart';
import '../../data/api/dto.dart';
import '../../data/gatekeeper_api.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/models/smart_object.dart';
import '../../shared/widgets/gk_button.dart';
import '../../shared/widgets/gk_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/status_pill.dart';
import 'widgets/object_form_sheet.dart';

//Vista oggetti smart con griglia card.
//Mostra esclusivamente i dati dal backend: in caso di errore l'utente
//vede un messaggio chiaro con pulsante "Riprova". Le azioni di
//creazione/modifica/eliminazione sono soggette ai permessi del ruolo.
class ObjectsPage extends StatefulWidget {
  const ObjectsPage({super.key});

  @override
  State<ObjectsPage> createState() => _ObjectsPageState();
}

class _ObjectsPageState extends State<ObjectsPage> {
  List<SmartObject> _objects = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final remote = await DevicesRepository.list();
      if (!mounted) return;
      setState(() {
        _objects = remote;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool get _canManage {
    final user = AuthController.instance.user;
    if (user == null) return false;
    if (user.role == 'admin') return true;
    return user.permissions[GKPermissions.canManageDevices] == true;
  }

  Future<void> _openCreate() async {
    final res = await showModalBottomSheet<DeviceDto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ObjectFormSheet(),
    );
    if (res != null) {
      if (!mounted) return;
      final l10n = AppL10n.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('objectCreated'))),
      );
      await _load();
    }
  }

  Future<void> _openEdit(SmartObject obj) async {
    final res = await showModalBottomSheet<DeviceDto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ObjectFormSheet(editing: obj),
    );
    if (res != null) {
      if (!mounted) return;
      final l10n = AppL10n.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('objectUpdated'))),
      );
      await _load();
    }
  }

  Future<void> _delete(SmartObject obj) async {
    final l10n = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('deleteConfirmTitle')),
        content: Text('${l10n.t('deleteConfirmBody')}\n\n${obj.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await GateKeeperApi.instance.devices.delete(int.parse(obj.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('objectDeleted'))),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.stormyTeal));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.stormyTeal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: l10n.t('objects'),
              subtitle: l10n.t('monitorObjects'),
              actions: [
                if (_canManage)
                  GKButton(
                    onPressed: _openCreate,
                    label: l10n.t('addObject'),
                    icon: Icons.add_rounded,
                    variant: GKButtonVariant.secondary,
                  ),
              ],
            ),
            if (_error != null)
              _ErrorBanner(message: _error!, onRetry: _load)
            else if (_objects.isEmpty)
              _EmptyState(
                  message: l10n.t('objectsEmpty'),
                  canCreate: _canManage,
                  onCreate: _openCreate)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final cols = w >= 1100 ? 3 : (w >= 700 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 240,
                    ),
                    itemCount: _objects.length,
                    itemBuilder: (context, i) => _ObjectCard(
                      object: _objects[i],
                      canManage: _canManage,
                      onEdit: () => _openEdit(_objects[i]),
                      onDelete: () => _delete(_objects[i]),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return GKCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.danger.withValues(alpha: 0.3),
      background: AppColors.danger.withValues(alpha: 0.04),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          const SizedBox(width: 10),
          GKButton(
            onPressed: onRetry,
            label: l10n.t('tryAgain'),
            icon: Icons.refresh_rounded,
            variant: GKButtonVariant.ghost,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.canCreate,
    required this.onCreate,
  });
  final String message;
  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return GKCard(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.inventory_2_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          if (canCreate) ...[
            const SizedBox(height: 14),
            GKButton(
              onPressed: onCreate,
              label: l10n.t('addObject'),
              icon: Icons.add_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _ObjectCard extends StatelessWidget {
  const _ObjectCard({
    required this.object,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });
  final SmartObject object;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    final color = object.isInside ? AppColors.stormyTeal : AppColors.orangeGold;

    return GKCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  object.icon,
                  color: object.isInside ? Colors.white : AppColors.inkBlack,
                  size: 24,
                ),
              ),
              const Spacer(),
              if (canManage) ...[
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  tooltip: l10n.t('edit'),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  color: AppColors.danger.withValues(alpha: 0.85),
                  tooltip: l10n.t('delete'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            object.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.wifi_tethering_rounded, size: 12),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'TAG: ${object.rfidTag}',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (object.isEssential)
                const StatusPill(label: '★', color: AppColors.orangeGold, dense: true),
            ],
          ),
          const Spacer(),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.t('location').toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      object.isInside ? l10n.t('inside') : l10n.t('outside'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              GKButton(
                onPressed: () => _showLogs(context, object),
                label: l10n.t('logShort'),
                variant: GKButtonVariant.ghost,
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showLogs(BuildContext context, SmartObject obj) async {
    final l10n = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    //Carica i log dell'oggetto in modo asincrono e li mostra in un dialog.
    try {
      final logs = await GateKeeperApi.instance.logs.list(deviceId: int.parse(obj.id));
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          final fmt = DateFormat.yMd().add_Hm();
          return AlertDialog(
            title: Text('${l10n.t('logShort')} · ${obj.name}'),
            content: SizedBox(
              width: 360,
              child: logs.isEmpty
                  ? Text(l10n.t('noLogsForObject'),
                      style: const TextStyle(fontStyle: FontStyle.italic))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final log = logs[i];
                        final entry = log.action == 'ENTRATO';
                        final at = DateTime.tryParse(log.createdAt);
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            entry ? Icons.login_rounded : Icons.logout_rounded,
                            color: entry ? AppColors.success : AppColors.orangeGold,
                          ),
                          title: Text(log.action),
                          subtitle: Text(at != null ? fmt.format(at.toLocal()) : log.createdAt),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.t('close')),
              ),
            ],
          );
        },
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
