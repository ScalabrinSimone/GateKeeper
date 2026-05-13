import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/i18n/app_l10n.dart';
import 'core/state/settings_controller.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

//Widget root: ascolta SettingsController per ricostruire il MaterialApp quando
//cambiano tema o lingua.
class GateKeeperApp extends StatefulWidget {
  const GateKeeperApp({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<GateKeeperApp> createState() => _GateKeeperAppState();
}

class _GateKeeperAppState extends State<GateKeeperApp> {
  late final _router = AppRouter.build(settings: widget.settings);

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'GateKeeper',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: widget.settings.themeMode,
      routerConfig: _router,
      locale: widget.settings.locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: const [
        AppL10nDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
