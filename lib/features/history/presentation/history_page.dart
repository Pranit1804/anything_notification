import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n_context.dart';
import '../../../core/time/naive_time.dart';
import '../../../core/time/zoned_clock.dart';
import '../../../core/widgets/empty_state.dart';
import '../../categories/presentation/category_visuals.dart';
import '../../reminders/domain/occurrence_outcome.dart';
import '../../reminders/presentation/reminder_formatters.dart';
import '../domain/history_entry.dart';
import 'history_cubit.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          final cubit = context.read<HistoryCubit>();
          final visible = state.visible;

          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: Text(l10n.historyTitle),
                actions: [
                  if (state.entries.isNotEmpty)
                    PopupMenuButton<void>(
                      itemBuilder: (context) => [
                        PopupMenuItem<void>(
                          onTap: () => _confirmClear(context),
                          child: Text(l10n.historyClear),
                        ),
                      ],
                    ),
                ],
              ),
              if (!state.loaded)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox.shrink(),
                )
              else if (state.entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.history_rounded,
                    title: l10n.historyEmptyTitle,
                    body: l10n.historyEmptyBody,
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: _Summary(count: state.doneLast7Days)),
                SliverToBoxAdapter(child: _OutcomeChips(state: state)),
                if (state.categories.isNotEmpty)
                  SliverToBoxAdapter(child: _CategoryChips(state: state)),
                if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.filter_list_off_rounded,
                      title: l10n.historyFilteredEmpty,
                      body: '',
                    ),
                  )
                else
                  ..._days(context, cubit.byDay(visible)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _days(
    BuildContext context,
    List<(DateTime, List<HistoryEntry>)> days,
  ) {
    final clock = context.read<ZonedClock>();
    final today = dateOnly(clock.nowNaive);
    final theme = Theme.of(context);

    String label(DateTime day) {
      final difference = today.difference(day).inDays;
      return switch (difference) {
        0 => context.l10n.sectionToday,
        1 => context.l10n.historyYesterday,
        _ => formatDate(context, day),
      };
    }

    return [
      for (final (day, entries) in days) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              label(day),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _EntryCard(entry: entries[index]),
          ),
        ),
      ],
    ];
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<HistoryCubit>();
    final messenger = ScaffoldMessenger.of(context);

    // The menu item's tap fires as the menu closes; wait for that to finish.
    await Future<void>.delayed(Duration.zero);
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.historyClearTitle),
        content: Text(l10n.historyClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.historyClear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await cubit.clear();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.historyCleared)));
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.historyThisWeek(count),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutcomeChips extends StatelessWidget {
  const _OutcomeChips({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<HistoryCubit>();

    String label(OccurrenceOutcome outcome) => switch (outcome) {
      OccurrenceOutcome.done => l10n.outcomeDone,
      OccurrenceOutcome.snoozed => l10n.outcomeSnoozed,
      OccurrenceOutcome.missed => l10n.outcomeMissed,
    };

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          FilterChip(
            label: Text(l10n.filterAll),
            selected: state.outcomeFilter == null,
            onSelected: (_) => cubit.setOutcomeFilter(null),
          ),
          for (final outcome in OccurrenceOutcome.values) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(label(outcome)),
              selected: state.outcomeFilter == outcome,
              onSelected: (_) => cubit.setOutcomeFilter(outcome),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HistoryCubit>();
    final brightness = Theme.of(context).brightness;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          FilterChip(
            label: Text(context.l10n.filterAll),
            selected: state.categoryFilter == null,
            onSelected: (_) => cubit.setCategoryFilter(null),
          ),
          for (final category in state.categories) ...[
            const SizedBox(width: 8),
            FilterChip(
              avatar: Icon(
                categoryIcon(category.iconKey),
                size: 18,
                color: categoryTones(
                  category.colorValue,
                  brightness,
                ).onContainer,
              ),
              label: Text(category.name),
              selected: state.categoryFilter == category.id,
              selectedColor: categoryTones(
                category.colorValue,
                brightness,
              ).container,
              onSelected: (_) => cubit.setCategoryFilter(category.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (icon, container, onContainer, label) = switch (entry.outcome) {
      OccurrenceOutcome.done => (
        Icons.check_rounded,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        l10n.outcomeDone,
      ),
      OccurrenceOutcome.snoozed => (
        Icons.snooze_rounded,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        l10n.outcomeSnoozed,
      ),
      OccurrenceOutcome.missed => (
        Icons.event_busy_rounded,
        scheme.errorContainer,
        scheme.onErrorContainer,
        l10n.outcomeMissed,
      ),
    };

    final categoryColor = entry.categoryColor;
    final tones = categoryColor == null
        ? null
        : categoryTones(categoryColor, theme.brightness);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: container,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 40,
                child: Icon(icon, size: 20, color: onContainer),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.historyEntrySubtitle(
                      label,
                      formatTime(context, entry.scheduledLocal),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (tones != null && entry.categoryName != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: tones.container,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(
                    entry.categoryName!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tones.onContainer,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
