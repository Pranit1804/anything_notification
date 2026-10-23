import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/router.dart';
import '../../../core/l10n_context.dart';
import '../../categories/presentation/categories_cubit.dart';
import '../../categories/presentation/category_visuals.dart';
import '../../reminders/application/reminder_service.dart';
import '../../reminders/data/reminder_repository.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/presentation/reminder_formatters.dart';
import '../../settings/presentation/cubit/settings_cubit.dart';

/// What an alarm-style reminder shows when it goes off: the whole screen, a
/// big title, and two big buttons. It can appear over the lock screen.
class AlarmPage extends StatefulWidget {
  const AlarmPage({
    super.key,
    required this.reminderId,
    required this.occurrence,
  });

  final int reminderId;

  /// Naive wall-clock time of the occurrence that is ringing.
  final DateTime occurrence;

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  late final Future<Reminder?> _reminder = context
      .read<ReminderRepository>()
      .getById(widget.reminderId);
  bool _busy = false;

  Future<void> _respond(Future<void> Function(ReminderService) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final service = context.read<ReminderService>();
    final system = context.read<AppDependencies>().systemSettings;
    final router = GoRouter.of(context);

    await action(service);
    // Stops showing the app over the lock screen, and goes back to it.
    await system.finishAlarm();
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoutes.upcoming);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final snooze = context.watch<SettingsCubit>().state.snoozeMinutes;
    final categories = context.watch<CategoriesCubit>().state;

    return Scaffold(
      backgroundColor: scheme.primaryContainer,
      body: SafeArea(
        child: FutureBuilder<Reminder?>(
          future: _reminder,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final reminder = snapshot.data;
            if (reminder == null ||
                reminder.status == ReminderStatus.completed) {
              // Already handled somewhere else (for example from the shade).
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final router = GoRouter.of(context);
                router.canPop() ? router.pop() : router.go(AppRoutes.upcoming);
              });
              return const SizedBox.shrink();
            }

            final category = categories.byId(reminder.categoryId);
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Icon(
                    Icons.alarm_rounded,
                    size: 72,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    reminder.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.alarmDue(formatTime(context, widget.occurrence)),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  if (reminder.note != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      reminder.note!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                  if (category != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Chip(
                        avatar: Icon(categoryIcon(category.iconKey), size: 18),
                        label: Text(category.name),
                      ),
                    ),
                  ],
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(72),
                      textStyle: theme.textTheme.titleLarge,
                    ),
                    onPressed: _busy
                        ? null
                        : () => _respond(
                            (s) => s.markDone(
                              widget.reminderId,
                              widget.occurrence,
                            ),
                          ),
                    child: Text(l10n.alarmDone),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(64),
                      textStyle: theme.textTheme.titleMedium,
                    ),
                    onPressed: _busy
                        ? null
                        : () => _respond(
                            (s) => s.snooze(
                              widget.reminderId,
                              widget.occurrence,
                              Duration(minutes: snooze),
                            ),
                          ),
                    child: Text(l10n.alarmSnooze(snooze)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
