import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/api_config.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/platform/platform_info.dart';
import '../../core/state/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/api_exception.dart';
import '../../data/api/dto.dart';
import '../../data/api/hub_api.dart';
import '../../data/services/discovery_service.dart';
import '../../shared/widgets/gk_button.dart';
import '../auth/widgets/auth_scaffold.dart';
import '../auth/widgets/gk_text_field.dart';
import 'widgets/qr_scanner_sheet.dart';

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
  bool _verifying = false;
  final List<DiscoveredHub> _hubs = [];
  final _manualCtrl = TextEditingController(text: 'http://');
  List<String> _recent = const [];
  String? _error;
  //Conserviamo l'eventuale factory-code rilevato dall'hub: lo passiamo al
  //setup wizard come "extra" route, così l'utente non deve digitarlo.
  String? _pendingFactoryCode;

  @override
  void initState() {
    super.initState();
    //Carico gli hub recenti e poi avvio la prima scansione (solo se posso).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _recent = await ApiConfig.recentHubs();
      if (mounted) setState(() {});
      if (PlatformInfo.canPairDevice) await _scan();
    });
  }

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  //Valida l'URL fornendo all'utente un feedback chiaro.
  //Solo se il ping ha successo l'URL viene salvato come base URL ufficiale
  //e aggiunto ai "recenti".
  Future<void> _useUrl(BuildContext context, String url, {String? factoryCode}) async {
    if (_verifying) return;
    HapticFeedback.selectionClick();
    setState(() {
      _verifying = true;
      _error = null;
      _pendingFactoryCode = factoryCode ?? _pendingFactoryCode;
    });
    try {
      //1) Ping rapido per verificare che l'URL sia un hub GateKeeper.
      final info = await HubApi.probe(url);
      //2) Successo: aggiorniamo lo stato di auth e navighiamo.
      await widget.auth.useBaseUrl(url);
      if (!context.mounted) return;
      final paired = info.paired;
      if (paired) {
        context.go('/login');
      } else {
        final code = _pendingFactoryCode;
        context.go(
          code != null && code.isNotEmpty
              ? '/onboarding/setup?factory_code=${Uri.encodeQueryComponent(code)}'
              : '/onboarding/setup',
        );
      }
    } on ApiException catch (e) {
      //3) Errore: NON salviamo l'URL e ripuliamo i recenti se ne contengono
      //   una versione che non risponde più.
      await ApiConfig.removeRecent(url);
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _recent = _recent.where((u) => u != url).toList();
      });
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _removeRecent(String url) async {
    HapticFeedback.selectionClick();
    await ApiConfig.removeRecent(url);
    final list = await ApiConfig.recentHubs();
    if (!mounted) return;
    setState(() => _recent = list);
  }

  Future<void> _openScanner() async {
    if (!PlatformInfo.canPairDevice) {
      setState(() => _error = AppL10n.of(context).t('webPairHint'));
      return;
    }
    final result = await showModalBottomSheet<HubQrDto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const QrScannerSheet(),
    );
    if (result == null || !mounted) return;
    final base = result.baseUrl;
    if (base == null || base.isEmpty) return;
    await _useUrl(context, base, factoryCode: result.factoryCode);
  }

  Future<void> _scan() async {
    if (!PlatformInfo.canPairDevice) {
      setState(() => _error = AppL10n.of(context).t('webPairHint'));
      return;
    }
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
    await _useUrl(context, hub.baseUrl);
  }

  Future<void> _useManual(BuildContext context) async {
    final url = _manualCtrl.text.trim();
    final l10n = AppL10n.of(context);
    if (url.isEmpty || !(url.startsWith('http://') || url.startsWith('https://'))) {
      setState(() => _error = l10n.t('invalidUrl'));
      return;
    }
    await _useUrl(context, url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);

    final canPair = PlatformInfo.canPairDevice;

    return AuthScaffold(
      title: l10n.t('discoverTitle'),
      subtitle: canPair ? l10n.t('discoverSubtitle') : l10n.t('webPairHint'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canPair) ...[
            //Banda di azioni rapide: scan LAN + scan QR.
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.t('hubFound')}: ${_hubs.length}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                GKButton(
                  onPressed: _openScanner,
                  label: l10n.t('scanQr'),
                  icon: Icons.qr_code_scanner_rounded,
                  variant: GKButtonVariant.secondary,
                  dense: true,
                ),
                const SizedBox(width: 6),
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
          ],
          //Hub recenti (persistiti dopo l'ultimo uso): scorciatoia per
          //riconnettersi senza ripetere la scansione.
          if (_recent.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.t('recentHubs'),
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final url in _recent)
              _RecentTile(
                url: url,
                onTap: () => _useUrl(context, url),
                onRemove: () => _removeRecent(url),
              ),
            const SizedBox(height: 8),
            Divider(color: theme.dividerColor),
          ],
          const SizedBox(height: 10),
          Text(
            canPair ? l10n.t('manualConnection') : l10n.t('remoteAccessTitle'),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          GKTextField(
            controller: _manualCtrl,
            label: canPair ? 'http://192.168.x.y:8000' : l10n.t('remoteUrlLabel'),
            prefixIcon: Icons.link_rounded,
          ),
          GKButton(
            onPressed: _verifying ? null : () => _useManual(context),
            label: _verifying ? l10n.t('verifyingHub') : l10n.t('connect'),
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

class _RecentTile extends StatelessWidget {
  const _RecentTile({
    required this.url,
    required this.onTap,
    required this.onRemove,
  });
  final String url;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('recent-$url'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: AppColors.danger),
        ),
        onDismissed: (_) => onRemove(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.stormyTeal.withValues(alpha: 0.04),
                border: Border.all(color: AppColors.stormyTeal.withValues(alpha: 0.18)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: AppColors.stormyTeal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      url,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    l10n.t('connectToRecent'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                      color: AppColors.stormyTeal,
                    ),
                  ),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    tooltip: l10n.t('removeRecentHub'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ),
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
