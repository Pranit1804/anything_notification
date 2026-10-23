import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/l10n_context.dart';
import '../../../../core/time/zoned_clock.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../permissions/presentation/permission_banners.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/category_visuals.dart';
import '../../../quick_add/presentation/quick_add_sheet.dart';
import '../../domain/reminder_grouping.dart';
import '../cubit/reminder_list_cubit.dart';
import '../widgets/reminder_card.dart';

class UpcomingPage extends StatelessWidget {
  const UpcomingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<ReminderListCubit, ReminderListState>(
      listenWhen: (previous, current) =>
          current.deleted != null &&
          previous.deleteSerial != current.deleteSerial,
      listener: _offerUndo,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showQuickAdd(context),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.newReminder),
        ),
        body: BlocBuilder<ReminderListCubit, ReminderListState>(
          builder: (context, state) {
            final clock = context.read<ZonedClock>();
            final reminders = state.reminders;
            final filtered = state.filterCategory;

            return CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: Text(l10n.upcomingTitle(DateTime.now())),
                ),
                if (state.loaded && state.hasReminders)
                  const SliverToBoxAdapter(child: PermissionBanners()),
                if (state.loaded &&
                    state.hasReminders &&
                    state.categories.isNotEmpty)
                  SliverToBoxAdapter(child: _FilterChips(state: state)),
                if (!state.loaded)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: SizedBox.shrink(),
                  )
                else if (reminders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: filtered != null
                        ? EmptyState(
                            icon: Icons.filter_list_off_rounded,
                            title: l10n.upcomingFilteredEmptyTitle(
                              filtered.name,
                            ),
                            body: l10n.upcomingFilteredEmptyBody,
                          )
                        : EmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: l10n.upcomingEmptyTitle,
                            body: l10n.upcomingEmptyBody,
                            footer: const _ExampleChips(),
                          ),
                  )
                else ...[
                  for (final group in reminders.groups)
                    ..._section(
                      context,
                      label: _sectionLabel(l10n, group.section),
                      items: group.items,
                      clock: clock,
                      categories: state.categories,
                      isOverdue: group.section == ReminderSection.overdue,
                    ),
                  if (reminders.paused.isNotEmpty)
                    ..._section(
                      context,
                      label: l10n.sectionPaused,
                      items: reminders.paused,
                      clock: clock,
                      categories: state.categories,
                    ),
                  // Keeps the last card clear of the floating button.
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _section(
    BuildContext context, {
    required String label,
    required List<ReminderItem> items,
    required ZonedClock clock,
    required List<Category> categories,
    bool isOverdue = false,
  }) {
    final cubit = context.read<ReminderListCubit>();
    final scheme = Theme.of(context).colorScheme;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isOverdue ? scheme.error : scheme.primary,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return ReminderCard(
              item: item,
              clock: clock,
              category: categories
                  .where((c) => c.id == item.reminder.categoryId)
                  .firstOrNull,
              onTap: () =>
                  context.push(AppRoutes.editReminder(item.reminder.id)),
              onDone: () => cubit.markDone(item.reminder),
              onDelete: () => cubit.delete(item.reminder),
            );
          },
        ),
      ),
    ];
  }

  String _sectionLabel(AppLocalizations l10n, ReminderSection section) =>
      switch (section) {
        ReminderSection.overdue => l10n.sectionOverdue,
        ReminderSection.today => l10n.sectionToday,
        ReminderSection.tomorrow => l10n.sectionTomorrow,
        ReminderSection.thisWeek => l10n.sectionThisWeek,
        ReminderSection.later => l10n.sectionLater,
      };

  void _offerUndo(BuildContext context, ReminderListState state) {
    final cubit = context.read<ReminderListCubit>();
    final serial = state.deleteSerial;
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger
        .showSnackBar(
          SnackBar(
            content: Text(context.l10n.reminderDeleted),
            action: SnackBarAction(
              label: context.l10n.undo,
              onPressed: cubit.undoDelete,
            ),
          ),
        )
        .closed
        .then((_) {
          // A newer delete may have replaced this one in the meantime.
          if (cubit.state.deleteSerial == serial) cubit.deleteHandled();
        });
  }
}

/// "All" plus one chip per category; picking one narrows the list to it.
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.state});

  final ReminderListState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReminderListCubit>();
    final brightness = Theme.of(context).brightness;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          FilterChip(
            label: Text(context.l10n.filterAll),
            selected: state.filterCategoryId == null,
            onSelected: (_) => cubit.setFilter(null),
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
              selected: state.filterCategoryId == category.id,
              selectedColor: categoryTones(
                category.colorValue,
                brightness,
              ).container,
              onSelected: (_) => cubit.setFilter(category.id),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tapping an example opens quick-add with it typed in, which shows what the
/// feature can do better than any explanation.
class _ExampleChips extends StatelessWidget {
  const _ExampleChips();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          l10n.quickAddExamplesLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final example in [
              l10n.quickAddExample1,
              l10n.quickAddExample2,
              l10n.quickAddExample3,
            ])
              ActionChip(
                label: Text(example),
                onPressed: () => showQuickAdd(context, initialText: example),
              ),
          ],
        ),
      ],
    );
  }
}
