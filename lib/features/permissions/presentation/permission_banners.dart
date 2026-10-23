import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n_context.dart';
import '../../../core/notifications/notification_permissions.dart';
import 'permissions_cubit.dart';

/// Gentle prompts shown on Upcoming while something stops reminders from
/// working as intended.
class PermissionBanners extends StatelessWidget {
  const PermissionBanners({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<PermissionsCubit>();

    return BlocBuilder<PermissionsCubit, PermissionSnapshot?>(
      builder: (context, snapshot) {
        if (snapshot == null) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;

        return Column(
          children: [
            if (!snapshot.notificationsEnabled)
              _Banner(
                icon: Icons.notifications_off_outlined,
                title: l10n.permNotificationsOffTitle,
                body: l10n.permNotificationsOffBody,
                actionLabel: l10n.permTurnOn,
                background: scheme.errorContainer,
                foreground: scheme.onErrorContainer,
                onAction: cubit.turnOnNotifications,
              ),
            if (snapshot.notificationsEnabled && !snapshot.exactAlarmsAllowed)
              _Banner(
                icon: Icons.alarm_off_outlined,
                title: l10n.permExactTitle,
                body: l10n.permExactBody,
                actionLabel: l10n.permAllow,
                background: scheme.tertiaryContainer,
                foreground: scheme.onTertiaryContainer,
                onAction: cubit.requestExactAlarms,
              ),
          ],
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.background,
    required this.foreground,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final Color background;
  final Color foreground;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: onAction,
                      child: Text(actionLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
