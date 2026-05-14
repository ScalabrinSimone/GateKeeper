import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/discovery_service.dart';
import '../../shared/widgets/gk_button.dart';
import '../auth/widgets/auth_scaffold.dart';
import '../auth/widgets/gk_text_field.dart';

//Step 1 dell'onboarding: trova un hub GateKeeper in rete (UDP broadcast)
//e selezionalo, oppure inserisci manualmente l'IP per i casi avanzati.
class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key, required this.auth});
  final AuthController auth;

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  bool _scanning = false;
  final List<DiscoveredHub> _hubs = [];
  final _manualCtrl = TextEditingController(text: 'http://');
  String? _error;

  @override
  void initState() {
    super.initState();
    //Avvio una prima scansione automatica appena entriamo.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _hubs.clear();
      _error = null;
    });
    try {
      final results = await DiscoveryService.discover(
        duration: const Duration(seconds: 4),
        onFound: (hub) {
          if (!mounted) return;
          setState(() => _hubs.add(hub));
        },
      );
      if (mounted) {
        setState(() {
          _hubs
            ..clear()
            ..addAll(results);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _useHub(BuildContext context, DiscoveredHub hub) async {
    HapticFeedback.mediumImpact();
    await widget.auth.useBaseUrl(hub.baseUrl);
    if (!context.mounted) return;
    if (hub.paired) {
      //L'hub è già accoppiato: l'utente passi al login.
      context.go('/login');
    } else {
      context.go('/onboarding/setup');
    }
  }

  Future<void> _useManual(BuildContext context) async {
    final url = _manualCtrl.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      setState(() => _error = 'URL non valido');
      return;
    }
    await widget.auth.useBaseUrl(url);
    if (!context.mounted) return;
    final paired = widget.auth.hubInfo?.paired ?? false;
    context.go(paired ? '/login' : '/onboarding/setup');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);

    return AuthScaffold(
      title: l10n.t('discoverTitle'),
      subtitle: l10n.t('discoverSubtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.t('hubFound')}: ${_hubs.length}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              GKButton(
                onPressed: _scanning ? null : _scan,
                label: _scanning ? l10n.t('scanningDots') : l10n.t('rescan'),
                icon: Icons.radar_rounded,
                variant: GKButtonVariant.ghost,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_scanning)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(child: CircularProgressIndicator(color: AppColors.stormyTeal)),
            ),
          if (_hubs.isEmpty && !_scanning)
            _EmptyState(text: l10n.t('noHubFound')),
          for (final hub in _hubs)
            _HubTile(
              hub: hub,
              onTap: () => _useHub(context, hub),
            ),
          const SizedBox(height: 14),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 10),
          Text(
            l10n.t('manualConnection'),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          GKTextField(
            controller: _manualCtrl,
            label: 'http://192.168.x.y:8000',
            prefixIcon: Icons.link_rounded,
          ),
          GKButton(
            onPressed: () => _useManual(context),
            label: l10n.t('connect'),
            icon: Icons.arrow_forward_rounded,
            expanded: true,
            variant: GKButtonVariant.outline,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => context.go('/welcome'),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(l10n.t('back')),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({required this.hub, required this.onTap});
  final DiscoveredHub hub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hub.paired ? AppColors.stormyTeal : AppColors.orangeGold;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.router_rounded, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hub.houseName ?? 'GateKeeper Hub',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${hub.host}:${hub.apiPort}  •  ${hub.paired ? 'paired' : 'new'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(Icons.travel_explore_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
