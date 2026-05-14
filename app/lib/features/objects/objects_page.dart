import 'package:flutter/material.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/smart_object.dart';
import '../../shared/widgets/gk_button.dart';
import '../../shared/widgets/gk_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/status_pill.dart';

//Vista oggetti smart con griglia card.
//Carica dal backend con fallback a mock.
class ObjectsPage extends StatefulWidget {
  const ObjectsPage({super.key});

  @override
  State<ObjectsPage> createState() => _ObjectsPageState();
}

class _ObjectsPageState extends State<ObjectsPage> {
  List<SmartObject> _objects = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final remote = await DevicesRepository.list();
      if (!mounted) return;
      setState(() {
        _objects = remote;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _objects = MockData.objects;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.stormyTeal));
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
                GKButton(
                  onPressed: () {},
                  label: l10n.t('addTag'),
                  icon: Icons.add_rounded,
                  variant: GKButtonVariant.secondary,
                ),
              ],
            ),
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
                    mainAxisExtent: 220,
                  ),
                  itemCount: _objects.length,
                  itemBuilder: (context, i) => _ObjectCard(object: _objects[i]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectCard extends StatelessWidget {
  const _ObjectCard({required this.object});
  final SmartObject object;

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
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit_rounded, size: 18),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete_rounded, size: 18),
                color: AppColors.danger.withValues(alpha: 0.7),
              ),
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
                onPressed: () {},
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
}
