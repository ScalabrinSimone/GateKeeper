import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/haptic_service.dart';
import '../../shared/widgets/gk_text_field.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Schermata primo avvio — Setup della casa.
///
/// Mostrata solo al primo accesso, quando non esiste ancora
/// una "home" configurata sul Raspberry Pi.
///
/// Step del wizard:
/// 1. [_StepHomeName] — nome della casa (es. "Casa Scalabrin")
/// 2. [_StepAdminAccount] — crea account Admin
/// 3. [_StepGatewayConnect] — inserisci IP/hostname del Raspberry Pi
///
/// Al completamento → POST /api/setup/init con tutti i dati
/// → redirect a '/dashboard'.
///
/// TODO: implementare POST /api/setup/init
/// TODO: aggiungere indicatore progress tra gli step (Stepper widget?)
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  // Step corrente del wizard (0-indexed)
  int _currentStep = 0;

  // Controller condivisi tra i vari step
  final _homeNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPassCtrl = TextEditingController();
  final _gatewayCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _homeNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPassCtrl.dispose();
    _gatewayCtrl.dispose();
    super.dispose();
  }

  void _nextStep() async {
    await HapticService.light();
    setState(() => _currentStep++);
  }

  void _prevStep() async {
    await HapticService.light();
    setState(() => _currentStep--);
  }

  Future<void> _finish() async {
    setState(() => _loading = true);

    // TODO: POST /api/setup/init con body:
    // {
    //   "home_name": _homeNameCtrl.text,
    //   "admin_email": _adminEmailCtrl.text,
    //   "admin_password": _adminPassCtrl.text,
    //   "gateway_host": _gatewayCtrl.text,
    // }
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    await HapticService.success();

    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkBlack,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                // Header
                const SizedBox(height: 40),
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.stormyTealBright,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Set Up GateKeeper',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step ${_currentStep + 1} of 3',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),

                // Progress bar
                _StepProgressBar(current: _currentStep, total: 3),
                const SizedBox(height: 32),

                // Contenuto step corrente
                AnimatedSwitcher(
                  // AnimatedSwitcher fa un crossfade fluido quando
                  // _currentStep cambia
                  duration: const Duration(milliseconds: 300),
                  child: _buildStep(),
                ),

                const SizedBox(height: 24),

                // Navigazione tra step
                Row(
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: _prevStep,
                        child: const Text(
                          '← Back',
                          style:
                              TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    const Spacer(),
                    if (_currentStep < 2)
                      ElevatedButton(
                        onPressed: _nextStep,
                        style: _primaryBtnStyle,
                        child: const Text('Continue →'),
                      )
                    else
                      ElevatedButton(
                        onPressed: _loading ? null : _finish,
                        style: _primaryBtnStyle,
                        child: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text('Finish Setup'),
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Already have an account? Sign in',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Restituisce il widget dello step corrente
  Widget _buildStep() {
    return switch (_currentStep) {
      0 => _StepHomeName(
          key: const ValueKey(0),
          controller: _homeNameCtrl,
        ),
      1 => _StepAdminAccount(
          key: const ValueKey(1),
          emailCtrl: _adminEmailCtrl,
          passCtrl: _adminPassCtrl,
        ),
      2 => _StepGatewayConnect(
          key: const ValueKey(2),
          controller: _gatewayCtrl,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  static final _primaryBtnStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.stormyTeal,
    foregroundColor: AppColors.white,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
  );
}

// ---------------------------------------------------------------------------
// Barra progresso step
// ---------------------------------------------------------------------------

/// Barra visuale con N segmenti, quello corrente è illuminato.
class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            decoration: BoxDecoration(
              // I segmenti completati o correnti si illuminano
              color: i <= current
                  ? AppColors.stormyTeal
                  : AppColors.panelSoft,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Nome casa
// ---------------------------------------------------------------------------

class _StepHomeName extends StatelessWidget {
  const _StepHomeName({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      icon: Icons.home_outlined,
      title: 'Name your home',
      subtitle: 'This will appear in the app and notifications.',
      child: GkTextField(
        label: 'Home Name',
        hint: 'e.g. Casa Scalabrin',
        controller: controller,
        prefixIcon: Icons.home_outlined,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Account Admin
// ---------------------------------------------------------------------------

class _StepAdminAccount extends StatelessWidget {
  const _StepAdminAccount({
    super.key,
    required this.emailCtrl,
    required this.passCtrl,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      icon: Icons.admin_panel_settings_outlined,
      title: 'Create admin account',
      subtitle: 'This will be the main account with full access.',
      child: Column(
        children: [
          GkTextField(
            label: 'Email',
            hint: 'admin@home.local',
            controller: emailCtrl,
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          GkTextField(
            label: 'Password',
            hint: '••••••••',
            controller: passCtrl,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Gateway connection
// ---------------------------------------------------------------------------

class _StepGatewayConnect extends StatelessWidget {
  const _StepGatewayConnect({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      icon: Icons.router_outlined,
      title: 'Connect to gateway',
      subtitle:
          'Enter the IP or hostname of your Raspberry Pi on the local network.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GkTextField(
            label: 'Gateway Address',
            hint: 'e.g. 192.168.1.100 or gatekeeper.local',
            controller: controller,
            prefixIcon: Icons.router_outlined,
          ),
          const SizedBox(height: 10),
          // Info aggiuntiva
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'The Raspberry Pi must be on the same network,\nor reachable via Cloudflare Tunnel.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wrapper card comune per ogni step
// ---------------------------------------------------------------------------

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.stormyTealBright, size: 28),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.body),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
