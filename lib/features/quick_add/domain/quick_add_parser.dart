import 'package:equatable/equatable.dart';

import '../../../core/time/naive_time.dart';
import '../../reminders/domain/recurrence_engine.dart';
import '../../reminders/domain/recurrence_rule.dart';

/// What a line of text like "Pay rent every 1st at 9am #bills" means.
class QuickAddResult extends Equatable {
  const QuickAddResult({
    required this.title,
    this.start,
    this.recurrence,
    this.categoryTag,
  });

  /// The text left over once the time, repeat and tag are taken out.
  final String title;

  /// First occurrence (naive wall-clock time), or null when the text said
  /// nothing about when.
  final DateTime? start;
  final RecurrenceRule? recurrence;

  /// The word after a `#`, lower-cased and without the `#`.
  final String? categoryTag;

  @override
  List<Object?> get props => [title, start, recurrence, categoryTag];
}

/// Turns one line of English into a reminder: when it is, how often it
/// repeats, and which category. Runs on the device, no network.
///
/// What it understands (see docs/PRD.md section 4.4):
/// * relative: `in 30 minutes`, `in an hour`, `in 2 days`
/// * days: `today`, `tomorrow`, `tonight`, `friday`, `next friday`,
///   `12 nov`, `nov 12th`, `3 december 2027`
/// * clock times: `6pm`, `6:30 pm`, `18:30`, `noon`, `midnight`
/// * repeats: `daily`, `weekdays`, `weekends`, `weekly`, `monthly`,
///   `yearly`, `every day`, `every 2 hours`, `every mon wed fri`,
///   `every 1st`
/// * a category: `#work`
///
/// Anything it does not recognise stays in the title, so a wrong guess is
/// visible and correctable rather than silently dropped.
class QuickAddParser {
  const QuickAddParser({
    this.engine = const RecurrenceEngine(),
    this.defaultHour = 9,
    this.defaultMinute = 0,
  });

  final RecurrenceEngine engine;

  /// Used when a day is given without a time (and for repeats without one).
  final int defaultHour;
  final int defaultMinute;

  static const _mark = '\u0000';

  static const _weekdays = <String, int>{
    'monday': 1,
    'mon': 1,
    'tuesday': 2,
    'tues': 2,
    'tue': 2,
    'wednesday': 3,
    'weds': 3,
    'wed': 3,
    'thursday': 4,
    'thurs': 4,
    'thur': 4,
    'thu': 4,
    'friday': 5,
    'fri': 5,
    'saturday': 6,
    'sat': 6,
    'sunday': 7,
    'sun': 7,
  };

  static const _months = <String, int>{
    'january': 1,
    'jan': 1,
    'february': 2,
    'feb': 2,
    'march': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'june': 6,
    'jun': 6,
    'july': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sept': 9,
    'sep': 9,
    'october': 10,
    'oct': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dec': 12,
  };

  static String _alt(Iterable<String> words) {
    final sorted = words.toList()..sort((a, b) => b.length.compareTo(a.length));
    return sorted.join('|');
  }

  static final _weekdayWords = _alt(_weekdays.keys);
  static final _monthWords = _alt(_months.keys);

  static RegExp _re(String pattern) =>
      RegExp(pattern, caseSensitive: false, unicode: true);

  static const _unit =
      r'(min(?:ute)?s?|hours?|hrs?|days?|weeks?|months?|years?)';

  static final _tagRe = _re(r'(?:^|\s)#([\p{L}\p{N}_-]+)');

  static final _everyN = _re(r'\bevery\s+(\d+)\s*' + _unit + r'(?![a-z])');
  static final _everyUnit = _re(
    r'\bevery\s+(minute|hour|day|week|month|year)(?![a-z])',
  );
  static final _everyWeekdays = _re(
    '\\bevery\\s+((?:$_weekdayWords)(?![a-z])'
    '(?:\\s*(?:,|and|&)?\\s*(?:$_weekdayWords)(?![a-z]))*)',
  );
  static final _everyOrdinal = _re(r'\bevery\s+(\d{1,2})(?:st|nd|rd|th)\b');
  static final _everyWeekdayWord = _re(r'\bevery\s+(weekday|weekend)s?\b');
  static final _freqWord = _re(
    r'\b(daily|weekdays|weekends|weekly|monthly|yearly|annually)\b',
  );

  static final _inN = _re(r'\bin\s+(\d+|an?|one)\s*' + _unit + r'(?![a-z])');

  static final _dayAfterTomorrow = _re(r'\bday\s+after\s+tomorrow\b');
  static final _dayWord = _re(r'\b(today|tomorrow|tonight)\b');

  static final _dayMonth = _re(
    '\\b(\\d{1,2})(?:st|nd|rd|th)?\\s+(?:of\\s+)?($_monthWords)(?![a-z])'
    '(?:,?\\s+(\\d{4}))?',
  );
  static final _monthDay = _re(
    '\\b($_monthWords)\\.?\\s+(\\d{1,2})(?:st|nd|rd|th)?(?!\\d)'
    '(?:,?\\s+(\\d{4}))?',
  );

  static final _weekday = _re('\\b(?:next\\s+)?($_weekdayWords)(?![a-z])');

  static final _meridiem = _re(
    r'(?:\b(?:at|@)\s*)?\b(\d{1,2})(?::(\d{2}))?\s*([ap])\.?m\.?(?![a-z])',
  );
  static final _clock24 = _re(
    r'(?:\b(?:at|@)\s*)?\b([01]?\d|2[0-3]):([0-5]\d)\b',
  );
  static final _noon = _re(r'\b(?:at\s+)?noon\b');
  static final _midnight = _re(r'\b(?:at\s+)?midnight\b');

  static final _connector = _re(
    r'\b(?:at|on|by|from|every|next|this|each|for|in)\s*' + _mark,
  );
  static final _joiner = _re('$_mark\\s*(?:,|and|&)\\s*(?=$_mark)');

  QuickAddResult parse(String input, {required DateTime now}) {
    // The mark is how taken-out spots are remembered; it must not occur in
    // the input itself.
    var text = input.replaceAll(_mark, '');

    RegExpMatch? take(RegExp re) {
      final match = re.firstMatch(text);
      if (match == null) return null;
      text = text.replaceRange(match.start, match.end, _mark);
      return match;
    }

    // --- category tag
    final tag = take(_tagRe)?.group(1)!.toLowerCase();

    // --- repeat
    RecurrenceRule? rule;
    int? monthDay; // "every 15th"
    if (take(_everyN) case final m?) {
      rule = RecurrenceRule(
        unit: _unitOf(m.group(2)!),
        interval: int.parse(m.group(1)!),
      );
    } else if (take(_everyUnit) case final m?) {
      rule = RecurrenceRule(unit: _unitOf(m.group(1)!));
    } else if (take(_everyWeekdays) case final m?) {
      rule = RecurrenceRule(
        unit: RepeatUnit.week,
        weekdays: {
          for (final word in RegExp(
            '(?:$_weekdayWords)',
            caseSensitive: false,
          ).allMatches(m.group(1)!))
            _weekdays[word.group(0)!.toLowerCase()]!,
        },
      );
    } else if (take(_everyOrdinal) case final m?) {
      monthDay = int.parse(m.group(1)!);
      rule = const RecurrenceRule(unit: RepeatUnit.month);
    } else if (take(_everyWeekdayWord) case final m?) {
      rule = _weekdaySet(m.group(1)!.toLowerCase());
    } else if (take(_freqWord) case final m?) {
      rule = switch (m.group(1)!.toLowerCase()) {
        'daily' => const RecurrenceRule(unit: RepeatUnit.day),
        'weekdays' => _weekdaySet('weekday'),
        'weekends' => _weekdaySet('weekend'),
        'weekly' => const RecurrenceRule(unit: RepeatUnit.week),
        'monthly' => const RecurrenceRule(unit: RepeatUnit.month),
        _ => const RecurrenceRule(unit: RepeatUnit.year),
      };
    }

    // --- relative: "in 30 minutes"
    Duration? subDay; // minutes or hours
    int? relativeDays;
    if (take(_inN) case final m?) {
      final n = switch (m.group(1)!.toLowerCase()) {
        'a' || 'an' || 'one' => 1,
        final digits => int.parse(digits),
      };
      switch (_unitOf(m.group(2)!)) {
        case RepeatUnit.minute:
          subDay = Duration(minutes: n);
        case RepeatUnit.hour:
          subDay = Duration(hours: n);
        case RepeatUnit.day:
          relativeDays = n;
        case RepeatUnit.week:
          relativeDays = n * 7;
        case RepeatUnit.month:
          relativeDays = n * 30;
        case RepeatUnit.year:
          relativeDays = n * 365;
      }
    }

    // --- day
    final today = dateOnly(now);
    DateTime? date;
    var tonight = false;
    if (take(_dayAfterTomorrow) != null) {
      date = today.add(const Duration(days: 2));
    } else if (take(_dayWord) case final m?) {
      switch (m.group(1)!.toLowerCase()) {
        case 'tomorrow':
          date = today.add(const Duration(days: 1));
        case 'tonight':
          tonight = true;
          date = today;
        default:
          date = today;
      }
    }
    if (date == null) {
      final dayMonth = take(_dayMonth);
      final monthDayMatch = dayMonth == null ? take(_monthDay) : null;
      if (dayMonth != null) {
        date = _calendarDate(
          now,
          month: _months[dayMonth.group(2)!.toLowerCase()]!,
          day: int.parse(dayMonth.group(1)!),
          year: dayMonth.group(3),
        );
      } else if (monthDayMatch != null) {
        date = _calendarDate(
          now,
          month: _months[monthDayMatch.group(1)!.toLowerCase()]!,
          day: int.parse(monthDayMatch.group(2)!),
          year: monthDayMatch.group(3),
        );
      }
    }
    int? weekday;
    if (date == null && relativeDays == null && rule == null) {
      weekday = _weekdays[take(_weekday)?.group(1)!.toLowerCase()];
    }

    // --- time of day
    int? hour;
    int? minute;
    if (take(_meridiem) case final m?) {
      final h = int.parse(m.group(1)!);
      final mm = int.tryParse(m.group(2) ?? '0') ?? 0;
      if (h >= 1 && h <= 12 && mm < 60) {
        hour = h % 12 + (m.group(3)!.toLowerCase() == 'p' ? 12 : 0);
        minute = mm;
      } else {
        // "13pm": not a time. Put it back as plain text.
        text = text.replaceFirst(_mark, m.group(0)!);
      }
    }
    if (hour == null) {
      if (take(_clock24) case final m?) {
        hour = int.parse(m.group(1)!);
        minute = int.parse(m.group(2)!);
      }
    }
    if (hour == null) {
      if (take(_noon) != null) {
        hour = 12;
        minute = 0;
      }
    }
    if (hour == null) {
      if (take(_midnight) != null) {
        hour = 0;
        minute = 0;
      }
    }
    if (hour == null && tonight) {
      hour = 20;
      minute = 0;
    }

    // --- when
    final nowMinute = naive(now.year, now.month, now.day, now.hour, now.minute);
    DateTime at(DateTime day, int h, int m) =>
        naive(day.year, day.month, day.day, h, m);
    final h = hour ?? defaultHour;
    final m = minute ?? defaultMinute;

    DateTime? start;
    if (subDay != null) {
      start = nowMinute.add(subDay);
    } else if (relativeDays != null) {
      start = at(today.add(Duration(days: relativeDays)), h, m);
    } else if (date != null) {
      start = at(date, h, m);
    } else if (weekday != null) {
      var ahead = (weekday - now.weekday) % 7;
      if (ahead == 0 && !at(today, h, m).isAfter(now)) ahead = 7;
      start = at(today.add(Duration(days: ahead)), h, m);
    } else if (hour != null) {
      final candidate = at(today, h, m);
      start = candidate.isAfter(now)
          ? candidate
          : candidate.add(const Duration(days: 1));
    }

    // "every 15th" picks the day itself, whatever time was also given.
    if (monthDay != null &&
        date == null &&
        relativeDays == null &&
        subDay == null) {
      start = null;
    }

    // --- repeats without a day of their own start at the next fitting time
    if (rule != null && start == null) {
      DateTime anchor;
      if (monthDay != null) {
        anchor = at(
          naive(
            now.year,
            now.month,
            monthDay.clamp(1, daysInMonth(now.year, now.month)),
          ),
          h,
          m,
        );
      } else if (rule.unit == RepeatUnit.minute ||
          rule.unit == RepeatUnit.hour) {
        anchor = nowMinute.add(
          rule.unit == RepeatUnit.minute
              ? Duration(minutes: rule.interval)
              : Duration(hours: rule.interval),
        );
      } else {
        final candidate = at(today, h, m);
        anchor = candidate.isAfter(now)
            ? candidate
            : candidate.add(const Duration(days: 1));
      }
      start = engine.nextAfter(anchor, rule, now) ?? anchor;
    } else if (rule != null && start != null) {
      start = engine.nextAfter(start, rule, now) ?? start;
    }

    return QuickAddResult(
      title: _tidy(text),
      start: start,
      recurrence: rule,
      categoryTag: tag,
    );
  }

  RecurrenceRule _weekdaySet(String word) => RecurrenceRule(
    unit: RepeatUnit.week,
    weekdays: word == 'weekday' ? {1, 2, 3, 4, 5} : {6, 7},
  );

  RepeatUnit _unitOf(String word) {
    final w = word.toLowerCase();
    if (w.startsWith('min')) return RepeatUnit.minute;
    if (w.startsWith('h')) return RepeatUnit.hour;
    if (w.startsWith('d')) return RepeatUnit.day;
    if (w.startsWith('w')) return RepeatUnit.week;
    if (w.startsWith('m')) return RepeatUnit.month;
    return RepeatUnit.year;
  }

  /// The next [day]/[month] on or after today, or the given year.
  DateTime _calendarDate(
    DateTime now, {
    required int month,
    required int day,
    String? year,
  }) {
    final y = year != null ? int.parse(year) : now.year;
    var result = naive(y, month, day.clamp(1, daysInMonth(y, month)));
    if (year == null && result.isBefore(dateOnly(now))) {
      result = naive(y + 1, month, day.clamp(1, daysInMonth(y + 1, month)));
    }
    return result;
  }

  /// Removes the spots where things were taken out, along with the little
  /// words that went with them ("at", "on", "every" ...).
  String _tidy(String text) {
    var t = text;
    for (var i = 0; i < 2; i++) {
      t = t.replaceAll(_connector, _mark).replaceAll(_joiner, _mark);
    }
    return t
        .replaceAll(_mark, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\s,.;:-]+|[\s,.;:-]+$'), '')
        .trim();
  }
}
