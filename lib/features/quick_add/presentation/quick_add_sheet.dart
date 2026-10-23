import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n_context.dart';
import '../../../core/time/zoned_clock.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_cubit.dart';
import '../../categories/presentation/category_visuals.dart';
import '../../permissions/presentation/post_save_prompts.dart';
import '../../reminders/application/reminder_service.dart';
import '../../reminders/domain/recurrence_rule.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/presentation/cubit/reminder_editor_cubit.dart';
import '../../reminders/presentation/reminder_formatters.dart';
import '../../reminders/presentation/widgets/repeat_picker.dart';
import '../../settings/presentation/cubit/settings_cubit.dart';
import '../domain/quick_add_parser.dart';

/// Type a reminder in one line; the time, repeat and category are worked out
/// as you type and shown as chips you can tap to correct.
Future<void> showQuickAdd(BuildContext context, {String initialText = ''}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _QuickAddSheet(initialText: initialText),
  );
}

class _QuickAddSheet extends StatefulWidget {
  const _QuickAddSheet({required this.initialText});

  final String initialText;

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  late final TextEditingController _controller;
  late final QuickAddParser _parser;
  late QuickAddResult _parsed;

  // Things the user fixed by hand win over what the text says.
  DateTime? _start;
  var _startFixed = false;
  RecurrenceRule? _rule;
  var _ruleFixed = false;
  int? _categoryId;
  var _categoryFixed = false;

  bool _busy = false;
  String? _error;

  ZonedClock get _clock => context.read<ZonedClock>();

  @override
  void initState() {
    super.initState();
    final minutes = context.read<SettingsCubit>().state.defaultReminderMinutes;
    _parser = QuickAddParser(
      defaultHour: minutes ~/ 60,
      defaultMinute: minutes % 60,
    );
    _controller = TextEditingController(text: widget.initialText);
    _parsed = _parse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  QuickAddResult _parse() =>
      _parser.parse(_controller.text, now: _clock.nowNaive);

  DateTime? get _effectiveStart => _startFixed ? _start : _parsed.start;
  RecurrenceRule? get _effectiveRule => _ruleFixed ? _rule : _parsed.recurrence;

  int? _effectiveCategoryId(List<Category> categories) {
    if (_categoryFixed) return _categoryId;
    final tag = _parsed.categoryTag;
    if (tag == null) return null;
    return _matchCategory(tag, categories)?.id;
  }

  /// "#work", "#health": by name, ignoring case and spaces, or by a prefix of
  /// at least two letters.
  static Category? _matchCategory(String tag, List<Category> categories) {
    String squash(String s) => s.toLowerCase().replaceAll(' ', '');
    final t = squash(tag);
    for (final c in categories) {
      if (squash(c.name) == t) return c;
    }
    if (t.length >= 2) {
      for (final c in categories) {
        if (squash(c.name).startsWith(t)) return c;
      }
    }
    return null;
  }

  void _onChanged(String _) => setState(() {
    _parsed = _parse();
    _error = null;
  });

  Future<bool> _pickWhen() async {
    final now = _clock.nowNaive;
    // Without a time of its own, offer the next full hour, as the editor does.
    final current =
        _effectiveStart ??
        DateTime.utc(now.year, now.month, now.day, now.hour + 1);

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return false;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (time == null || !mounted) return false;

    setState(() {
      _start = DateTime.utc(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _startFixed = true;
      _error = null;
    });
    return true;
  }

  Future<void> _pickRepeat() async {
    final choice = await showRepeatPicker(
      context,
      current: _effectiveRule,
      start: _effectiveStart ?? _clock.nowNaive,
    );
    if (choice == null) return;
    setState(() {
      _rule = choice.rule;
      _ruleFixed = true;
      _error = null;
    });
  }

  Future<void> _pickCategory(List<Category> categories) async {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;

    // A sentinel distinguishes "none" from dismissing the sheet.
    const none = -1;
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.quickAddNoCategory),
                onTap: () => Navigator.pop(context, none),
              ),
              for (final category in categories)
                ListTile(
                  leading: CategoryAvatar(
                    colorValue: category.colorValue,
                    iconKey: category.iconKey,
                    size: 36,
                  ),
                  title: Text(category.name),
                  iconColor: categoryTones(
                    category.colorValue,
                    brightness,
                  ).onContainer,
                  onTap: () => Navigator.pop(context, category.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _categoryId = picked == none ? null : picked;
      _categoryFixed = true;
    });
  }

  Future<void> _add() async {
    if (_busy) return;
    final l10n = context.l10n;
    final categories = context.read<CategoriesCubit>().state.categories;
    final service = context.read<ReminderService>();
    final title = _parsed.title.trim();

    if (title.isEmpty) {
      setState(() => _error = l10n.quickAddTitleNeeded);
      return;
    }
    // Nothing in the text said when: ask, instead of guessing.
    if (_effectiveStart == null && !await _pickWhen()) return;

    final start = _effectiveStart!;
    final rule = _effectiveRule;
    if (rule?.validate() != null) {
      setState(() => _error = l10n.editorInvalidRepeat);
      return;
    }
    if (!start.isAfter(_clock.nowNaive)) {
      setState(() => _error = l10n.editorStartInPast);
      return;
    }

    setState(() => _busy = true);
    await service.create(
      ReminderDraft(
        title: title,
        start: start,
        recurrence: rule,
        categoryId: _effectiveCategoryId(categories),
      ),
    );
    if (!mounted) return;
    await askPermissionsAfterSave(context);
    if (mounted) Navigator.pop(context);
  }

  void _moreOptions() {
    final categories = context.read<CategoriesCubit>().state.categories;
    final router = GoRouter.of(context);
    final prefill = ReminderPrefill(
      title: _parsed.title,
      start: _effectiveStart,
      recurrence: _effectiveRule,
      categoryId: _effectiveCategoryId(categories),
    );
    Navigator.pop(context);
    router.push(AppRoutes.newReminder, extra: prefill);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final categories = context.watch<CategoriesCubit>().state.categories;

    final start = _effectiveStart;
    final rule = _effectiveRule;
    final category = categories
        .where((c) => c.id == _effectiveCategoryId(categories))
        .firstOrNull;
    final tones = category == null
        ? null
        : categoryTones(category.colorValue, theme.brightness);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(hintText: l10n.quickAddHint),
              onChanged: _onChanged,
              onSubmitted: (_) => _add(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(
                    start == null
                        ? l10n.quickAddPickTime
                        : formatWhen(context, start, nowNaive: _clock.nowNaive),
                  ),
                  backgroundColor: start == null
                      ? scheme.tertiaryContainer
                      : scheme.secondaryContainer,
                  onPressed: _pickWhen,
                ),
                ActionChip(
                  avatar: const Icon(Icons.repeat_rounded, size: 18),
                  label: Text(
                    describeRecurrence(context, rule, start ?? _clock.nowNaive),
                  ),
                  backgroundColor: rule == null
                      ? null
                      : scheme.secondaryContainer,
                  onPressed: _pickRepeat,
                ),
                ActionChip(
                  avatar: Icon(
                    category == null
                        ? Icons.label_outline_rounded
                        : categoryIcon(category.iconKey),
                    size: 18,
                    color: tones?.onContainer,
                  ),
                  label: Text(category?.name ?? l10n.quickAddNoCategory),
                  backgroundColor: tones?.container,
                  onPressed: () => _pickCategory(categories),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: _moreOptions,
                  child: Text(l10n.quickAddMore),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _add,
                  child: Text(l10n.quickAddAdd),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
