import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n_context.dart';
import '../../../../core/time/naive_time.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/recurrence_rule.dart';
import '../reminder_formatters.dart';

/// What the user picked. Wrapping the rule distinguishes "does not repeat"
/// (rule == null) from dismissing the sheet (no result at all).
class RepeatChoice {
  const RepeatChoice(this.rule);

  final RecurrenceRule? rule;
}

const _presets = <RecurrenceRule>[
  RecurrenceRule(unit: RepeatUnit.day),
  RecurrenceRule(unit: RepeatUnit.week),
  RecurrenceRule(unit: RepeatUnit.month),
  RecurrenceRule(unit: RepeatUnit.year),
];

Future<RepeatChoice?> showRepeatPicker(
  BuildContext context, {
  required RecurrenceRule? current,
  required DateTime start,
}) {
  return showModalBottomSheet<RepeatChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RepeatPickerSheet(current: current, start: start),
  );
}

class _RepeatPickerSheet extends StatelessWidget {
  const _RepeatPickerSheet({required this.current, required this.start});

  final RecurrenceRule? current;
  final DateTime start;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCustom = current != null && !_presets.contains(current);

    Widget option({
      required String label,
      String? subtitle,
      required bool selected,
      required VoidCallback onTap,
    }) => ListTile(
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: selected ? const Icon(Icons.check_rounded) : null,
      selected: selected,
      onTap: onTap,
    );

    String presetLabel(RecurrenceRule rule) => switch (rule.unit) {
      RepeatUnit.day => l10n.repeatEveryDay,
      RepeatUnit.week => l10n.repeatEveryWeek,
      RepeatUnit.month => l10n.repeatEveryMonth,
      _ => l10n.repeatEveryYear,
    };

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                l10n.repeatSheetTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            option(
              label: l10n.repeatNone,
              selected: current == null,
              onTap: () => Navigator.pop(context, const RepeatChoice(null)),
            ),
            for (final preset in _presets)
              option(
                label: presetLabel(preset),
                selected: current == preset,
                onTap: () => Navigator.pop(context, RepeatChoice(preset)),
              ),
            option(
              label: l10n.repeatCustom,
              subtitle: isCustom
                  ? describeRecurrence(context, current, start)
                  : null,
              selected: isCustom,
              onTap: () async {
                final rule = await showCustomRepeatSheet(
                  context,
                  initial: isCustom ? current : null,
                  start: start,
                );
                if (rule != null && context.mounted) {
                  Navigator.pop(context, RepeatChoice(rule));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<RecurrenceRule?> showCustomRepeatSheet(
  BuildContext context, {
  required RecurrenceRule? initial,
  required DateTime start,
}) {
  return showModalBottomSheet<RecurrenceRule>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CustomRepeatSheet(initial: initial, start: start),
  );
}

enum _Ending { never, onDate, afterCount }

class _CustomRepeatSheet extends StatefulWidget {
  const _CustomRepeatSheet({required this.initial, required this.start});

  final RecurrenceRule? initial;
  final DateTime start;

  @override
  State<_CustomRepeatSheet> createState() => _CustomRepeatSheetState();
}

class _CustomRepeatSheetState extends State<_CustomRepeatSheet> {
  late RepeatUnit _unit;
  late int _interval;
  late Set<int> _weekdays;
  late bool _lastDay;
  late _Ending _ending;
  DateTime? _until;
  late int _count;

  late final TextEditingController _intervalController;
  late final TextEditingController _countController;

  @override
  void initState() {
    super.initState();
    final rule = widget.initial;
    _unit = rule?.unit ?? RepeatUnit.day;
    _interval = rule?.interval ?? 1;
    _weekdays = {...?rule?.weekdays};
    _lastDay = rule?.lastDayOfMonth ?? false;
    _until = rule?.until;
    _count = rule?.count ?? 5;
    _ending = rule?.until != null
        ? _Ending.onDate
        : rule?.count != null
        ? _Ending.afterCount
        : _Ending.never;
    _intervalController = TextEditingController(text: '$_interval');
    _countController = TextEditingController(text: '$_count');
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _countController.dispose();
    super.dispose();
  }

  RecurrenceRule get _rule => RecurrenceRule(
    unit: _unit,
    interval: _interval,
    weekdays: _unit == RepeatUnit.week ? _weekdays : const {},
    lastDayOfMonth: _unit == RepeatUnit.month && _lastDay,
    until: _ending == _Ending.onDate ? _until : null,
    count: _ending == _Ending.afterCount ? _count : null,
  );

  bool get _minuteTooSmall =>
      _unit == RepeatUnit.minute &&
      _interval < RecurrenceRule.minMinuteInterval;

  bool get _valid =>
      _rule.validate() == null && (_ending != _Ending.onDate || _until != null);

  String _unitLabel(AppLocalizations l10n, RepeatUnit unit) => switch (unit) {
    RepeatUnit.minute => l10n.customUnitMinutes(_interval),
    RepeatUnit.hour => l10n.customUnitHours(_interval),
    RepeatUnit.day => l10n.customUnitDays(_interval),
    RepeatUnit.week => l10n.customUnitWeeks(_interval),
    RepeatUnit.month => l10n.customUnitMonths(_interval),
    RepeatUnit.year => l10n.customUnitYears(_interval),
  };

  Future<void> _pickUntil() async {
    final first = dateOnly(widget.start);
    final picked = await showDatePicker(
      context: context,
      initialDate: _until != null && !_until!.isBefore(first)
          ? DateTime(_until!.year, _until!.month, _until!.day)
          : DateTime(first.year, first.month, first.day),
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: DateTime(first.year + 20),
    );
    if (picked != null) {
      setState(() => _until = naive(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.customRepeatTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(l10n.customEvery, style: theme.textTheme.bodyLarge),
                const SizedBox(width: 12),
                SizedBox(
                  width: 84,
                  child: TextField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    onChanged: (value) =>
                        setState(() => _interval = int.tryParse(value) ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownMenu<RepeatUnit>(
                    expandedInsets: EdgeInsets.zero,
                    initialSelection: _unit,
                    requestFocusOnTap: false,
                    onSelected: (unit) {
                      if (unit != null) setState(() => _unit = unit);
                    },
                    dropdownMenuEntries: [
                      for (final unit in RepeatUnit.values)
                        DropdownMenuEntry(
                          value: unit,
                          label: _unitLabel(l10n, unit),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_minuteTooSmall)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.customMinimumMinutes,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            if (_unit == RepeatUnit.week) ...[
              const SizedBox(height: 20),
              Text(l10n.customOnDays, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (var day = 1; day <= 7; day++)
                    FilterChip(
                      label: Text(weekdayName(context, day)),
                      selected: _weekdays.contains(day),
                      onSelected: (on) => setState(
                        () => on ? _weekdays.add(day) : _weekdays.remove(day),
                      ),
                    ),
                ],
              ),
            ],
            if (_unit == RepeatUnit.month) ...[
              const SizedBox(height: 20),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.customMonthOnDay(widget.start.day)),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.customMonthOnLastDay),
                  ),
                ],
                selected: {_lastDay},
                onSelectionChanged: (s) => setState(() => _lastDay = s.first),
              ),
            ],
            const SizedBox(height: 20),
            Text(l10n.customEnds, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<_Ending>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _Ending.never,
                  label: Text(l10n.customEndsNever),
                ),
                ButtonSegment(
                  value: _Ending.onDate,
                  label: Text(l10n.customEndsOnDate),
                ),
                ButtonSegment(
                  value: _Ending.afterCount,
                  label: Text(l10n.customEndsAfter),
                ),
              ],
              selected: {_ending},
              onSelectionChanged: (s) => setState(() => _ending = s.first),
            ),
            if (_ending == _Ending.onDate) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickUntil,
                icon: const Icon(Icons.event_rounded),
                label: Text(
                  _until == null ? '—' : formatDate(context, _until!),
                ),
              ),
            ],
            if (_ending == _Ending.afterCount) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      onChanged: (value) =>
                          setState(() => _count = int.tryParse(value) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.customEndsAfterSuffix),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _valid ? () => Navigator.pop(context, _rule) : null,
                child: Text(l10n.customDone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
