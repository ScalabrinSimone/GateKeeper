import 'package:flutter/material.dart';

import '../../shared/widgets/gatekeeper_logo.dart';
import '../../theme/app_colors.dart';

/// Layout di base della login screen.
///
/// Qui aggiungiamo il logo GateKeeper sopra al form per rendere il brand
/// immediatamente riconoscibile.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: GateKeeperLogo(height: 72),
                ),
                const SizedBox(height: 32),
                // TODO: qui sotto rimane il contenuto esistente del form
                // (campi URL, email, password, ecc.).
              ],
            ),
          ),
        ),
      ),
    );
  }
}
