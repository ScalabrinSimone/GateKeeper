import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/api_config.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/api_exception.dart';
import '../../data/api/dto.dart';
import '../../data/gatekeeper_api.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/realtime_service.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/enums.dart';
import '../../core/state/avatar_controller.dart';
import '../../shared/widgets/gk_button.dart';
import '../../shared/widgets/gk_card.dart';
import '../../shared/widgets/notif_prefs_sheet.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/status_pill.dart';
import 'widgets/invite_share_dialog.dart';
import 'widgets/permissions_sheet.dart';

//Vista membri del nucleo familiare.
//Carica utenti e inviti pendenti dal backend. Le azioni (invita, modifica
//permessi, rimuovi) sono mostrate solo a chi ne ha il permesso.
class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  List<AppUser> _users = const [];
  List<InviteDto> _invites = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    //Ascolta RealtimeService per aggiornamenti in tempo reale.
    RealtimeService.instance.addListener(_onRealtimeUpdate);
    _refresh();
    _syncFromRealtime();
  }

  @override
  void dispose() {
    RealtimeService.instance.removeListener(_onRealtimeUpdate);
    super.dispose();
  }

  void _onRealtimeUpdate() {
    if (!mounted) return;
    _syncFromRealtime();
  }

  void _syncFromRealtime() {
    final rt = RealtimeService.instance;
    if (rt.users.isNotEmpty) {
      setState(() {
        _users = rt.users;
        _loading = false;
      });
    }
  }

  bool get _canManageUsers {
    final user = AuthController.instance.user;
    if (user == null) return false;
    if (user.role == 'admin') return true;
    return user.permissions[GKPermissions.canManageUsers] == true;
  }

  bool get _canManageInvites {
    final user = AuthController.instance.user;
    if (user == null) return false;
    if (user.role == 'admin') return true;
    return user.permissions[GKPermissions.canManageInvites] == true;
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await UsersRepository.list();
      List<InviteDto> invites = const [];
      if (_canManageInvites) {
        try {
          invites = await GateKeeperApi.instance.invites.list();
        } catch (_) {
          //Solo l'admin riesce a leggere gli inviti; se non riesce, lista vuota.
        }
      }
      if (!mounted) return;
      setState(() {
        _users = users;
        _invites = invites;
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

  Future<void> _editPermissions(AppUser user) async {
    if (!_canManageUsers) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PermissionsSheet(user: user),
    );
    if (ok == true) _refresh();
  }

  Future<void> _removeMember(AppUser user) async {
    if (!_canManageUsers) return;
    final l10n = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('removeMember')),
        content: Text('${l10n.t('removeMemberConfirm')}\n\n${user.name}'),
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
      await GateKeeperApi.instance.users.delete(int.parse(user.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('memberRemoved'))),
      );
      _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  //Ritorna true se l'accesso è remoto (tunnel) — in quel caso la creazione
  //di nuovi account/inviti è bloccata per sicurezza.
  //Legge da SharedPreferences la URL del tunnel salvata e la confronta con
  //il base URL corrente.
  Future<bool> _isRemoteAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tunnelUrl = prefs.getString('gk.remote.tunnel_url') ?? '';
      if (tunnelUrl.isEmpty) return false;
      final base = ApiConfig.baseUrl ?? '';
      return base.isNotEmpty && base == tunnelUrl;
    } catch (_) {
      return false;
    }
  }

  Future<void> _generateInvite() async {
    if (!_canManageInvites) return;
    final l10n = AppL10n.of(context);
    //Blocca la creazione di inviti se si è connessi da remoto.
    if (await _isRemoteAccess()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('inviteBlockedRemote')),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    //Salva il context prima dell'await per evitare l'uso asincrono.
    final ctx = context;
    final role = await showModalBottomSheet<String>(
      context: ctx,
      backgroundColor: Theme.of(ctx).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.t('generateInvite'),
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              for (final r in const ['admin', 'adult', 'child'])
                ListTile(
                  leading: Icon(_roleIcon(r), color: AppColors.stormyTeal),
                  title: Text(r.toUpperCase()),
                  onTap: () => Navigator.of(ctx).pop(r),
                ),
            ],
          ),
        ),
      ),
    );
    if (role == null) return;
    try {
      final inv = await GateKeeperApi.instance.invites.create(role: role);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => InviteShareDialog(invite: inv),
      );
      _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _revokeInvite(InviteDto invite) async {
    if (!_canManageInvites) return;
    try {
      await GateKeeperApi.instance.invites.revoke(invite.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).t('revokedInvite'))),
      );
      _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.shield_rounded;
      case 'child':
        return Icons.child_care_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.stormyTeal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: l10n.t('members'),
              subtitle: l10n.t('manageFamily'),
              actions: [
                if (_canManageInvites)
                  GKButton(
                    onPressed: _generateInvite,
                    label: l10n.t('inviteMember'),
                    icon: Icons.person_add_alt_rounded,
                    variant: GKButtonVariant.secondary,
                  ),
              ],
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator(color: AppColors.stormyTeal)),
              )
            else if (_error != null)
              GKCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(20),
                borderColor: AppColors.danger.withValues(alpha: 0.3),
                background: AppColors.danger.withValues(alpha: 0.04),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_error!)),
                    GKButton(
                      onPressed: _refresh,
                      label: l10n.t('tryAgain'),
                      icon: Icons.refresh_rounded,
                      variant: GKButtonVariant.ghost,
                      dense: true,
                    ),
                  ],
                ),
              )
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 1100
                      ? 3
                      : (constraints.maxWidth >= 700 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 260,
                    ),
                    itemCount: _users.length + (_canManageInvites ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _users.length) {
                        return _InviteCard(
                          label: l10n.t('inviteMember'),
                          onTap: _generateInvite,
                        );
                      }
                      final u = _users[i];
                      return _MemberCard(
                        user: u,
                        canManage: _canManageUsers && u.role != UserRole.admin,
                        onPermissions: () => _editPermissions(u),
                        onRemove: () => _removeMember(u),
                      );
                    },
                  );
                },
              ),
              if (_canManageInvites && _invites.isNotEmpty) ...[
                const SizedBox(height: 22),
                _PendingInvites(
                  invites: _invites,
                  onRevoke: _revokeInvite,
                  onShowQr: (inv) => showDialog<void>(
                    context: context,
                    builder: (_) => InviteShareDialog(invite: inv),
                  ),
                  //La copia è silenziosa: nessuna snackbar.
                  onCopy: (inv) => Clipboard.setData(ClipboardData(text: inv.token)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

//StatefulWidget per gestire il feedback visivo "copia → tick" per ogni invito.
class _PendingInvites extends StatefulWidget {
  const _PendingInvites({
    required this.invites,
    required this.onRevoke,
    required this.onCopy,
    required this.onShowQr,
  });

  final List<InviteDto> invites;
  final Future<void> Function(InviteDto) onRevoke;
  final Future<void> Function(InviteDto) onCopy;
  final void Function(InviteDto) onShowQr;

  @override
  State<_PendingInvites> createState() => _PendingInvitesState();
}

class _PendingInvitesState extends State<_PendingInvites> {
  //Token dell'invito attualmente in stato "copiato" (mostra tick).
  final Set<String> _copied = {};

  Future<void> _handleCopy(InviteDto inv) async {
    await widget.onCopy(inv);
    if (!mounted) return;
    setState(() => _copied.add(inv.token));
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied.remove(inv.token));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    return GKCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('pendingInvites').toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
              color: AppColors.stormyTeal,
            ),
          ),
          const SizedBox(height: 12),
          for (final inv in widget.invites)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.stormyTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_rounded,
                        color: AppColors.stormyTeal, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.role.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w900,
                            color: AppColors.stormyTeal,
                          ),
                        ),
                        SelectableText(
                          inv.token,
                          maxLines: 1,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onShowQr(inv),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    tooltip: l10n.t('showInviteQr'),
                    color: AppColors.stormyTeal,
                  ),
                  //Icona copia con feedback tick per 2s (silenzioso).
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: IconButton(
                      key: ValueKey(_copied.contains(inv.token)),
                      onPressed: () => _handleCopy(inv),
                      icon: Icon(
                        _copied.contains(inv.token)
                            ? Icons.check_circle_rounded
                            : Icons.copy_rounded,
                        color: _copied.contains(inv.token)
                            ? AppColors.success
                            : null,
                      ),
                      tooltip: l10n.t('copyCode'),
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onRevoke(inv),
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: l10n.t('revoke'),
                    color: AppColors.danger.withValues(alpha: 0.85),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.user,
    required this.canManage,
    required this.onPermissions,
    required this.onRemove,
  });
  final AppUser user;
  final bool canManage;
  final VoidCallback onPermissions;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    final df = DateFormat.Hm();

    final IconData roleIcon;
    switch (user.role) {
      case UserRole.admin:
        roleIcon = Icons.shield_rounded;
        break;
      case UserRole.adult:
        roleIcon = Icons.person_rounded;
        break;
      case UserRole.child:
        roleIcon = Icons.child_care_rounded;
        break;
    }

    return GKCard(
      borderRadius: 32,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _UserAvatar(user: user, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        //Il bollino verde indica che l'utente è fisicamente in casa,
                        //non che l'account è attivo (isActive = account abilitato).
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: user.isInside ? AppColors.success : AppColors.charcoalBlue.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            user.name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(roleIcon, size: 14, color: user.role == UserRole.admin ? AppColors.orangeGold : AppColors.stormyTeal),
                        const SizedBox(width: 6),
                        Text(
                          l10n.t(_roleKey(user.role)).toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              //Tre puntini sempre visibili: permessi (solo admin), notifiche (tutti).
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                onSelected: (v) async {
                  if (v == 'perm') onPermissions();
                  if (v == 'remove') onRemove();
                  if (v == 'notif') {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Theme.of(context).cardColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => NotifPrefsSheet(
                        entityId: user.id,
                        entityName: user.name,
                        entityIcon: Icons.person_rounded,
                      ),
                    );
                  }
                },
                itemBuilder: (_) => [
                  if (canManage)
                    PopupMenuItem(
                      value: 'perm',
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 18),
                          const SizedBox(width: 10),
                          Text(l10n.t('permissionsTitle')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.danger),
                          const SizedBox(width: 10),
                          Text(l10n.t('removeMember'),
                              style: const TextStyle(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  //Preferenze notifiche: visibile a tutti (non solo admin).
                  PopupMenuItem(
                    value: 'notif',
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_rounded, size: 18),
                        const SizedBox(width: 10),
                        Text(l10n.t('notifPrefsTitle')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          _row(
            theme,
            label: l10n.t('currentStatus'),
            value: user.isInside ? l10n.t('inside') : l10n.t('outside'),
            valueColor: user.isInside ? AppColors.success : AppColors.orangeGold,
            asPill: true,
          ),
          const SizedBox(height: 12),
          _row(
            theme,
            label: l10n.t('lastSeen'),
            //Usa sempre l'orario locale del dispositivo.
            value: user.lastSeenAt != null ? df.format(user.lastSeenAt!.toLocal()) : '—',
          ),
          const SizedBox(height: 16),
          if (canManage)
            Row(
              children: [
                Expanded(
                  child: GKButton(
                    onPressed: onPermissions,
                    icon: Icons.shield_outlined,
                    label: l10n.t('permissionsShort'),
                    variant: GKButtonVariant.ghost,
                    dense: true,
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GKButton(
                    onPressed: onRemove,
                    icon: Icons.person_remove_alt_1_rounded,
                    label: l10n.t('removeMember'),
                    variant: GKButtonVariant.danger,
                    dense: true,
                    expanded: true,
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.stormyTeal.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      user.email ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, {required String label, required String value, Color? valueColor, bool asPill = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        if (asPill)
          StatusPill(label: value, color: valueColor ?? AppColors.stormyTeal, dense: true)
        else
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
      ],
    );
  }

  String _roleKey(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.adult:
        return 'adult';
      case UserRole.child:
        return 'child';
    }
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GKCard(
      borderRadius: 32,
      padding: const EdgeInsets.all(22),
      borderColor: AppColors.stormyTeal.withValues(alpha: 0.2),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.stormyTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.person_add_alt_rounded, size: 32, color: AppColors.stormyTeal),
          ),
          const SizedBox(height: 14),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

//Widget avatar utente: mostra la foto profilo se l'utente è quello correntemente
//loggato (avatar salvato localmente), altrimenti mostra le iniziali.
class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user, required this.size});
  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthController.instance.user?.id.toString();
    final isCurrentUser = currentUserId != null && user.id == currentUserId;
    final avatarPath = isCurrentUser ? AvatarController.instance.avatarPath : null;
    final radius = size * 0.36;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.stormyTeal, AppColors.charcoalBlue]),
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      child: avatarPath != null
          ? Image.file(
              File(avatarPath),
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, __, ___) => _initials(),
            )
          : _initials(),
    );
  }

  Widget _initials() => Text(
        user.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.32,
        ),
      );
}
