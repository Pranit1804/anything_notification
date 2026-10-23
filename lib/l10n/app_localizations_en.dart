// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Anything Notification';

  @override
  String get navUpcoming => 'Upcoming';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String upcomingTitle(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat(
      'EEE d MMM',
      localeName,
    );
    final String dateString = dateDateFormat.format(date);

    return 'Today, $dateString';
  }

  @override
  String get newReminder => 'New reminder';

  @override
  String get upcomingEmptyTitle => 'Nothing coming up';

  @override
  String get upcomingEmptyBody => 'Tap New reminder to add your first one.';

  @override
  String get sectionOverdue => 'Overdue';

  @override
  String get sectionToday => 'Today';

  @override
  String get sectionTomorrow => 'Tomorrow';

  @override
  String get sectionThisWeek => 'This week';

  @override
  String get sectionLater => 'Later';

  @override
  String get sectionPaused => 'Paused';

  @override
  String get markDone => 'Mark done';

  @override
  String get reminderDeleted => 'Reminder deleted';

  @override
  String get undo => 'Undo';

  @override
  String whenToday(String time) {
    return 'Today, $time';
  }

  @override
  String whenTomorrow(String time) {
    return 'Tomorrow, $time';
  }

  @override
  String whenOnDate(String date, String time) {
    return '$date, $time';
  }

  @override
  String reminderSubtitle(String when, String repeat) {
    return '$when · $repeat';
  }

  @override
  String snoozedUntil(String time) {
    return 'Snoozed until $time';
  }

  @override
  String get editorNewTitle => 'New reminder';

  @override
  String get editorEditTitle => 'Edit reminder';

  @override
  String get editorTitleHint => 'What should I remind you about?';

  @override
  String get editorNoteHint => 'Add a note (optional)';

  @override
  String get editorWhen => 'When';

  @override
  String get editorRepeat => 'Repeat';

  @override
  String get editorSave => 'Save';

  @override
  String get editorActive => 'Active';

  @override
  String get editorActiveSubtitle =>
      'Paused reminders stay saved but won\'t notify you';

  @override
  String get editorDelete => 'Delete reminder';

  @override
  String get editorDeleteConfirmTitle => 'Delete this reminder?';

  @override
  String get editorDeleteConfirmBody => 'You can undo this right after.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get editorTitleRequired => 'Give your reminder a title';

  @override
  String get editorStartInPast => 'Pick a time in the future';

  @override
  String get editorInvalidRepeat => 'This repeat isn\'t valid';

  @override
  String editorNext(String when) {
    return 'Next: $when';
  }

  @override
  String editorNextThen(String first, String second) {
    return 'Next: $first, then $second';
  }

  @override
  String get editorNoUpcoming => 'No upcoming occurrences';

  @override
  String get repeatNone => 'Doesn\'t repeat';

  @override
  String get repeatEveryDay => 'Every day';

  @override
  String get repeatEveryWeek => 'Every week';

  @override
  String get repeatEveryMonth => 'Every month';

  @override
  String get repeatEveryYear => 'Every year';

  @override
  String get repeatCustom => 'Custom…';

  @override
  String get repeatSheetTitle => 'Repeat';

  @override
  String repeatEveryMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count minutes',
      one: 'Every minute',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count hours',
      one: 'Every hour',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count months',
      one: 'Every month',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count years',
      one: 'Every year',
    );
    return '$_temp0';
  }

  @override
  String repeatOnDays(String summary, String days) {
    return '$summary on $days';
  }

  @override
  String repeatOnLastDay(String summary) {
    return '$summary on the last day';
  }

  @override
  String repeatUntil(String summary, String date) {
    return '$summary, until $date';
  }

  @override
  String repeatTimes(String summary, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: 'once',
    );
    return '$summary, $_temp0';
  }

  @override
  String get customRepeatTitle => 'Custom repeat';

  @override
  String get customEvery => 'Every';

  @override
  String customUnitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return '$_temp0';
  }

  @override
  String customUnitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hours',
      one: 'hour',
    );
    return '$_temp0';
  }

  @override
  String customUnitDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String customUnitWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'weeks',
      one: 'week',
    );
    return '$_temp0';
  }

  @override
  String customUnitMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'months',
      one: 'month',
    );
    return '$_temp0';
  }

  @override
  String customUnitYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'years',
      one: 'year',
    );
    return '$_temp0';
  }

  @override
  String get customOnDays => 'On';

  @override
  String customMonthOnDay(int day) {
    return 'On day $day';
  }

  @override
  String get customMonthOnLastDay => 'On the last day';

  @override
  String get customEnds => 'Ends';

  @override
  String get customEndsNever => 'Never';

  @override
  String get customEndsOnDate => 'On date';

  @override
  String get customEndsAfter => 'After';

  @override
  String get customEndsAfterSuffix => 'times';

  @override
  String get customMinimumMinutes => 'Minimum is 15 minutes';

  @override
  String get customDone => 'Done';

  @override
  String get permNotificationsOffTitle => 'Notifications are off';

  @override
  String get permNotificationsOffBody =>
      'Turn them on so your reminders can reach you.';

  @override
  String get permTurnOn => 'Turn on';

  @override
  String get permExactTitle => 'Reminders may arrive a few minutes late';

  @override
  String get permExactBody =>
      'Allow exact alarms so they arrive right on time.';

  @override
  String get permAllow => 'Allow';

  @override
  String get exactDialogTitle => 'Allow exact alarms?';

  @override
  String get exactDialogBody =>
      'Without this, Android may delay reminders by several minutes. You can change it any time in system settings.';

  @override
  String get notNow => 'Not now';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmptyTitle => 'No history yet';

  @override
  String get historyEmptyBody =>
      'Reminders you complete, snooze or miss will appear here.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get dynamicColorTitle => 'Dynamic color';

  @override
  String get dynamicColorSubtitle =>
      'Match colors to your wallpaper (Android 12+)';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesNew => 'New category';

  @override
  String get categoriesEmptyTitle => 'No categories yet';

  @override
  String get categoriesEmptyBody =>
      'Categories group your reminders, like Work or Health.';

  @override
  String get categoryNewTitle => 'New category';

  @override
  String get categoryEditTitle => 'Edit category';

  @override
  String get categoryNameHint => 'Category name';

  @override
  String get categoryNameRequired => 'Give your category a name';

  @override
  String get categoryColorLabel => 'Color';

  @override
  String get categoryIconLabel => 'Icon';

  @override
  String get categoryDelete => 'Delete category';

  @override
  String categoryDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get categoryDeleteBody =>
      'Reminders in this category will have no category. Your history keeps its name.';

  @override
  String get editorCategory => 'Category';

  @override
  String get categoryNone => 'None';

  @override
  String get categoryNewChip => 'New';

  @override
  String get filterAll => 'All';

  @override
  String upcomingFilteredEmptyTitle(String category) {
    return 'Nothing in $category';
  }

  @override
  String get upcomingFilteredEmptyBody =>
      'Pick another category or add a reminder.';

  @override
  String historyThisWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count done in the last 7 days',
      one: '1 done in the last 7 days',
      zero: 'Nothing done in the last 7 days',
    );
    return '$_temp0';
  }

  @override
  String get outcomeDone => 'Done';

  @override
  String get outcomeSnoozed => 'Snoozed';

  @override
  String get outcomeMissed => 'Missed';

  @override
  String historyEntrySubtitle(String outcome, String time) {
    return '$outcome · due $time';
  }

  @override
  String get historyYesterday => 'Yesterday';

  @override
  String get historyClear => 'Clear history';

  @override
  String get historyClearTitle => 'Clear all history?';

  @override
  String get historyClearBody =>
      'This removes the record of done, snoozed and missed reminders. Your reminders are not affected.';

  @override
  String get historyCleared => 'History cleared';

  @override
  String get historyFilteredEmpty => 'Nothing matches these filters';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get settingsSnooze => 'Snooze for';

  @override
  String settingsSnoozeValue(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get settingsCategoriesTile => 'Categories';

  @override
  String get settingsCategoriesSubtitle =>
      'Colors and icons for your reminders';

  @override
  String get settingsHistory => 'History';

  @override
  String get settingsKeepHistory => 'Keep history for';

  @override
  String get settingsReliability => 'Reliability';

  @override
  String get reliabilityIntro => 'Check that reminders can reach you.';

  @override
  String get reliabilityNotifications => 'Notifications';

  @override
  String get reliabilityExact => 'Exact alarms';

  @override
  String get statusOn => 'On';

  @override
  String get statusOff => 'Off';

  @override
  String get statusAllowed => 'Allowed';

  @override
  String get statusNotAllowed => 'Not allowed';

  @override
  String get reliabilityFix => 'Fix';

  @override
  String get reliabilityTest => 'Send test notification';

  @override
  String get reliabilityTestSubtitle =>
      'Arrives in about 10 seconds. Lock your phone to check it still comes through.';

  @override
  String get reliabilityTestSent =>
      'Sent. It should appear in about 10 seconds.';

  @override
  String get reliabilityGuideTitle => 'Reminder didn\'t show up?';

  @override
  String get reliabilityGuideBattery =>
      'Some phones (Xiaomi, Oppo, Samsung and others) stop apps in the background to save battery. Set Anything Notification to \"Unrestricted\" or \"Don\'t optimize\".';

  @override
  String get reliabilityGuideForceStop =>
      'Force-stopping the app cancels its reminders until you open it again.';

  @override
  String get reliabilityGuideFocus =>
      'Do Not Disturb or a Focus mode can silence notifications.';

  @override
  String get reliabilityGuideChecks =>
      'Make sure Notifications and Exact alarms above are on.';

  @override
  String get reliabilityOpenBattery => 'Open battery settings';

  @override
  String get settingsRetentionForever => 'Forever';

  @override
  String get settingsRetentionYear => '1 year';

  @override
  String settingsRetentionDays(int days) {
    return '$days days';
  }

  @override
  String get settingsDefaultTime => 'Default reminder time';

  @override
  String get settingsDefaultTimeSubtitle =>
      'Used when you give a day but no time';

  @override
  String get quickAddHint => 'Try \"Pay rent every 1st at 9am\"';

  @override
  String get quickAddMore => 'More options';

  @override
  String get quickAddAdd => 'Add';

  @override
  String get quickAddPickTime => 'Pick a time';

  @override
  String get quickAddNoCategory => 'No category';

  @override
  String get quickAddTitleNeeded => 'Add what to remind you about';

  @override
  String get quickAddExamplesLabel => 'Try typing';

  @override
  String get quickAddExample1 => 'Drink water every 2 hours';

  @override
  String get quickAddExample2 => 'Pay rent every 1st at 9am';

  @override
  String get quickAddExample3 => 'Call mom tomorrow at 6pm';
}
