import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n_context.dart';
import '../../../../core/time/zoned_clock.dart';
import '../../../categories/presentation/categories_cubit.dart';
import '../../../categories/presentation/category_editor_sheet.dart';
import '../../../categories/presentation/category_visuals.dart';
import '../../../permissions/presentation/post_save_prompts.dart';
import '../../application/reminder_service.dart';
import '../../data/reminder_repository.dart';
import '../../domain/reminder.dart';
import '../cubit/reminder_editor_cubit.dart';
import '../cubit/reminder_list_cubit.dart';
import '../reminder_formatters.dart';
import '../widgets/repeat_picker.dart';

/// Create ([reminderId] == null) or edit a reminder.
class ReminderEditorPage extends StatefulWidget {
  const ReminderEditorPage({super.key, this.reminderId, this.prefill});

  final int? reminderId;

  /// Starting values for a new reminder; ignored when editing.
  final ReminderPrefill? prefill;

  @override
  State<ReminderEditorPage> createState() => _ReminderEditorPageState();
}

class _ReminderEditorPageState extends State<ReminderEditorPage> {
  Future<Reminder?>? _loading;

  @override
  void initState() {
    super.initState();
    final id = widget.reminderId;
    if (id != null) {
      _loading = context.read<ReminderRepository>().getById(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = _loading;
    if (loading == null) {
      return _EditorScaffold(existing: null, prefill: widget.prefill);
    }

    return FutureBuilder<Reminder?>(
      future: loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final reminder = snapshot.data;
        if (reminder == null) {
          // Deleted in the meantime (for example from its notification).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.pop();
          });
          return const Scaffold();
        }
        return _EditorScaffold(existing: reminder);
      },
    );
  }
}

class _EditorScaffold extends StatelessWidget {
  const _EditorScaffold({required this.existing, this.prefill});

  final Reminder? existing;
  final ReminderPrefill? prefill;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReminderEditorCubit(
        service: context.read<ReminderService>(),
        clock: context.read<ZonedClock>(),
        existing: existing,
        prefill: prefill,
      ),
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView();

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  late final TextEditingController _title;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final state = context.read<ReminderEditorCubit>().state;
    _title = TextEditingController(text: state.title);
    _note = TextEditingController(text: state.note);
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cubit = context.read<ReminderEditorCubit>();
    final active = !cubit.state.paused;

    if (!await cubit.save() || !mounted) return;

    if (active) await askPermissionsAfterSave(context);
    if (mounted) context.pop();
  }

  Future<void> _pickDate() async {
    final cubit = context.read<ReminderEditorCubit>();
    final start = cubit.state.start;
    final now = context.read<ZonedClock>().nowNaive;
    final earliest = start.isBefore(now) ? start : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(start.year, start.month, start.day),
      firstDate: DateTime(earliest.year, earliest.month, earliest.day),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) cubit.dateChanged(picked);
  }

  Future<void> _pickTime() async {
    final cubit = context.read<ReminderEditorCubit>();
    final start = cubit.state.start;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start.hour, minute: start.minute),
    );
    if (picked != null) cubit.timeChanged(picked.hour, picked.minute);
  }

  Future<void> _pickRepeat() async {
    final cubit = context.read<ReminderEditorCubit>();
    final choice = await showRepeatPicker(
      context,
      current: cubit.state.recurrence,
      start: cubit.state.start,
    );
    if (choice != null) cubit.recurrenceChanged(choice.rule);
  }

  Future<void> _confirmDelete(Reminder reminder) async {
    final l10n = context.l10n;
    final list = context.read<ReminderListCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editorDeleteConfirmTitle),
        content: Text(l10n.editorDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // The list screen offers Undo once we are back on it.
    unawaited(list.delete(reminder));
    context.pop();
  }

  String? _errorText(EditorError? error) {
    final l10n = context.l10n;
    return switch (error) {
      EditorError.titleMissing => l10n.editorTitleRequired,
      EditorError.startInPast => l10n.editorStartInPast,
      EditorError.invalidRepeat => l10n.editorInvalidRepeat,
      null => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<ReminderEditorCubit>();

    return BlocBuilder<ReminderEditorCubit, ReminderEditorState>(
      builder: (context, state) {
        final error = state.error;
        final titleError = error == EditorError.titleMissing
            ? _errorText(error)
            : null;
        final otherError = error == EditorError.titleMissing
            ? null
            : _errorText(error);

        return Scaffold(
          appBar: AppBar(
            leading: const CloseButton(),
            title: Text(
              state.isNew ? l10n.editorNewTitle : l10n.editorEditTitle,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton(
                  onPressed: state.saving ? null : _save,
                  child: Text(l10n.editorSave),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              TextField(
                controller: _title,
                autofocus: state.isNew,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: l10n.editorTitleHint,
                  errorText: titleError,
                ),
                onChanged: cubit.titleChanged,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(hintText: l10n.editorNoteHint),
                onChanged: cubit.noteChanged,
              ),
              _SectionLabel(l10n.editorWhen),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.calendar_today_rounded,
                      label: formatDate(context, state.start),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.schedule_rounded,
                      label: formatTime(context, state.start),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              if (otherError != null && error != EditorError.invalidRepeat)
                _ErrorText(otherError),
              _SectionLabel(l10n.editorRepeat),
              _PickerTile(
                icon: Icons.repeat_rounded,
                label: describeRecurrence(
                  context,
                  state.recurrence,
                  state.start,
                ),
                onTap: _pickRepeat,
              ),
              if (error == EditorError.invalidRepeat) _ErrorText(otherError!),
              _SectionLabel(l10n.editorCategory),
              _CategoryPicker(
                selectedId: state.categoryId,
                onSelected: cubit.categoryChanged,
              ),
              const SizedBox(height: 16),
              _NextPreview(state: state),
              if (state.existing != null) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Text(l10n.editorActive),
                  subtitle: Text(l10n.editorActiveSubtitle),
                  value: !state.paused,
                  onChanged: (active) => cubit.pausedChanged(!active),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(state.existing!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(l10n.editorDelete),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
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

/// "Next: Fri 24 Oct, 6:00 PM, then Sat 25 Oct, 6:00 PM": the schedule as
/// the app understands it, so mistakes show up before saving.
class _NextPreview extends StatelessWidget {
  const _NextPreview({required this.state});

  final ReminderEditorState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final clock = context.read<ZonedClock>();
    final now = clock.nowNaive;

    final upcoming = context.read<ReminderEditorCubit>().preview();
    final text = switch (upcoming.length) {
      0 => l10n.editorNoUpcoming,
      1 => l10n.editorNext(formatWhen(context, upcoming[0], nowNaive: now)),
      _ => l10n.editorNextThen(
        formatWhen(context, upcoming[0], nowNaive: now),
        formatWhen(context, upcoming[1], nowNaive: now),
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.event_available_rounded,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chips to pick the reminder's category (or none), plus "New" to create one
/// on the spot and use it.
class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selectedId, required this.onSelected});

  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;

    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.categoryNone),
              selected: selectedId == null,
              onSelected: (_) => onSelected(null),
            ),
            for (final category in state.categories)
              ChoiceChip(
                avatar: Icon(
                  categoryIcon(category.iconKey),
                  size: 18,
                  color: categoryTones(
                    category.colorValue,
                    brightness,
                  ).onContainer,
                ),
                label: Text(category.name),
                selected: selectedId == category.id,
                selectedColor: categoryTones(
                  category.colorValue,
                  brightness,
                ).container,
                onSelected: (_) => onSelected(category.id),
              ),
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.categoryNewChip),
              onPressed: () async {
                final created = await showCategoryEditor(context);
                if (created != null) onSelected(created.id);
              },
            ),
          ],
        );
      },
    );
  }
}
