import 'package:flutter/material.dart';

import '../../../../core/l10n_context.dart';
import '../../../../core/time/zoned_clock.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/category_visuals.dart';
import '../../domain/reminder.dart';
import '../../domain/reminder_grouping.dart';
import '../reminder_formatters.dart';

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.item,
    required this.clock,
    this.category,
    required this.onTap,
    required this.onDone,
    required this.onDelete,
  });

  final ReminderItem item;
  final ZonedClock clock;

  /// Shown as the card's icon; without one the card uses a plain alarm icon.
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback onDone;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reminder = item.reminder;
    final due = item.due!;
    final paused = reminder.status == ReminderStatus.paused;
    final overdue = due.isOverdue && !paused;

    final when = formatWhen(context, due.occurrence, nowNaive: clock.nowNaive);
    final subtitle = reminder.recurrence == null
        ? when
        : l10n.reminderSubtitle(
            when,
            describeRecurrence(context, reminder.recurrence, reminder.start),
          );
    final accent = overdue ? scheme.error : scheme.primary;
    final snoozedUntil = item.snoozedUntil;

    return Dismissible(
      key: ValueKey('reminder-${reminder.id}'),
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: scheme.primaryContainer,
        iconColor: scheme.onPrimaryContainer,
        icon: Icons.check_rounded,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: scheme.errorContainer,
        iconColor: scheme.onErrorContainer,
        icon: Icons.delete_outline_rounded,
      ),
      // Done snaps back: the list updates itself once the change is saved.
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (!paused) onDone();
          return false;
        }
        onDelete();
        return true;
      },
      child: Opacity(
        opacity: paused ? 0.6 : 1,
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  if (category case final category?)
                    CategoryAvatar(
                      colorValue: category.colorValue,
                      iconKey: category.iconKey,
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: overdue
                            ? scheme.errorContainer
                            : scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: 48,
                        child: Icon(
                          reminder.isRecurring
                              ? Icons.repeat_rounded
                              : Icons.alarm_rounded,
                          color: overdue
                              ? scheme.onErrorContainer
                              : scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                reminder.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (reminder.delivery != DeliveryMode.standard) ...[
                              const SizedBox(width: 6),
                              Icon(
                                reminder.delivery == DeliveryMode.alarm
                                    ? Icons.alarm_on_rounded
                                    : Icons.push_pin_rounded,
                                size: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: overdue
                                ? scheme.error
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        if (snoozedUntil != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            l10n.snoozedUntil(
                              formatTime(context, clock.toNaive(snoozedUntil)),
                            ),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!paused)
                    IconButton.filledTonal(
                      tooltip: l10n.markDone,
                      onPressed: onDone,
                      icon: const Icon(Icons.check_rounded),
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

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.iconColor,
    required this.icon,
  });

  final Alignment alignment;
  final Color color;
  final Color iconColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}
