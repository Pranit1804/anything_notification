import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Anything Notification'**
  String get appName;

  /// No description provided for @navUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get navUpcoming;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @upcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String upcomingTitle(DateTime date);

  /// No description provided for @newReminder.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get newReminder;

  /// No description provided for @upcomingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing coming up'**
  String get upcomingEmptyTitle;

  /// No description provided for @upcomingEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap New reminder to add your first one.'**
  String get upcomingEmptyBody;

  /// No description provided for @sectionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get sectionOverdue;

  /// No description provided for @sectionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get sectionToday;

  /// No description provided for @sectionTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get sectionTomorrow;

  /// No description provided for @sectionThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get sectionThisWeek;

  /// No description provided for @sectionLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get sectionLater;

  /// No description provided for @sectionPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get sectionPaused;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get markDone;

  /// No description provided for @reminderDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reminder deleted'**
  String get reminderDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @whenToday.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String whenToday(String time);

  /// No description provided for @whenTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow, {time}'**
  String whenTomorrow(String time);

  /// No description provided for @whenOnDate.
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String whenOnDate(String date, String time);

  /// No description provided for @reminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{when} · {repeat}'**
  String reminderSubtitle(String when, String repeat);

  /// No description provided for @snoozedUntil.
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {time}'**
  String snoozedUntil(String time);

  /// No description provided for @editorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get editorNewTitle;

  /// No description provided for @editorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get editorEditTitle;

  /// No description provided for @editorTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What should I remind you about?'**
  String get editorTitleHint;

  /// No description provided for @editorNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get editorNoteHint;

  /// No description provided for @editorWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get editorWhen;

  /// No description provided for @editorRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get editorRepeat;

  /// No description provided for @editorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editorSave;

  /// No description provided for @editorActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get editorActive;

  /// No description provided for @editorActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paused reminders stay saved but won\'t notify you'**
  String get editorActiveSubtitle;

  /// No description provided for @editorDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder'**
  String get editorDelete;

  /// No description provided for @editorDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this reminder?'**
  String get editorDeleteConfirmTitle;

  /// No description provided for @editorDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You can undo this right after.'**
  String get editorDeleteConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @editorTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Give your reminder a title'**
  String get editorTitleRequired;

  /// No description provided for @editorStartInPast.
  ///
  /// In en, this message translates to:
  /// **'Pick a time in the future'**
  String get editorStartInPast;

  /// No description provided for @editorInvalidRepeat.
  ///
  /// In en, this message translates to:
  /// **'This repeat isn\'t valid'**
  String get editorInvalidRepeat;

  /// No description provided for @editorNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {when}'**
  String editorNext(String when);

  /// No description provided for @editorNextThen.
  ///
  /// In en, this message translates to:
  /// **'Next: {first}, then {second}'**
  String editorNextThen(String first, String second);

  /// No description provided for @editorNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming occurrences'**
  String get editorNoUpcoming;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t repeat'**
  String get repeatNone;

  /// No description provided for @repeatEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeatEveryDay;

  /// No description provided for @repeatEveryWeek.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get repeatEveryWeek;

  /// No description provided for @repeatEveryMonth.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get repeatEveryMonth;

  /// No description provided for @repeatEveryYear.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get repeatEveryYear;

  /// No description provided for @repeatCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get repeatCustom;

  /// No description provided for @repeatSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatSheetTitle;

  /// No description provided for @repeatEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every minute} other{Every {count} minutes}}'**
  String repeatEveryMinutes(int count);

  /// No description provided for @repeatEveryHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every hour} other{Every {count} hours}}'**
  String repeatEveryHours(int count);

  /// No description provided for @repeatEveryDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every day} other{Every {count} days}}'**
  String repeatEveryDays(int count);

  /// No description provided for @repeatEveryWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every week} other{Every {count} weeks}}'**
  String repeatEveryWeeks(int count);

  /// No description provided for @repeatEveryMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every month} other{Every {count} months}}'**
  String repeatEveryMonths(int count);

  /// No description provided for @repeatEveryYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every year} other{Every {count} years}}'**
  String repeatEveryYears(int count);

  /// No description provided for @repeatOnDays.
  ///
  /// In en, this message translates to:
  /// **'{summary} on {days}'**
  String repeatOnDays(String summary, String days);

  /// No description provided for @repeatOnLastDay.
  ///
  /// In en, this message translates to:
  /// **'{summary} on the last day'**
  String repeatOnLastDay(String summary);

  /// No description provided for @repeatUntil.
  ///
  /// In en, this message translates to:
  /// **'{summary}, until {date}'**
  String repeatUntil(String summary, String date);

  /// No description provided for @repeatTimes.
  ///
  /// In en, this message translates to:
  /// **'{summary}, {count, plural, =1{once} other{{count} times}}'**
  String repeatTimes(String summary, int count);

  /// No description provided for @customRepeatTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom repeat'**
  String get customRepeatTitle;

  /// No description provided for @customEvery.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get customEvery;

  /// No description provided for @customUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{minute} other{minutes}}'**
  String customUnitMinutes(int count);

  /// No description provided for @customUnitHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{hour} other{hours}}'**
  String customUnitHours(int count);

  /// No description provided for @customUnitDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String customUnitDays(int count);

  /// No description provided for @customUnitWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{week} other{weeks}}'**
  String customUnitWeeks(int count);

  /// No description provided for @customUnitMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{month} other{months}}'**
  String customUnitMonths(int count);

  /// No description provided for @customUnitYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{year} other{years}}'**
  String customUnitYears(int count);

  /// No description provided for @customOnDays.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get customOnDays;

  /// No description provided for @customMonthOnDay.
  ///
  /// In en, this message translates to:
  /// **'On day {day}'**
  String customMonthOnDay(int day);

  /// No description provided for @customMonthOnLastDay.
  ///
  /// In en, this message translates to:
  /// **'On the last day'**
  String get customMonthOnLastDay;

  /// No description provided for @customEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get customEnds;

  /// No description provided for @customEndsNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get customEndsNever;

  /// No description provided for @customEndsOnDate.
  ///
  /// In en, this message translates to:
  /// **'On date'**
  String get customEndsOnDate;

  /// No description provided for @customEndsAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get customEndsAfter;

  /// No description provided for @customEndsAfterSuffix.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get customEndsAfterSuffix;

  /// No description provided for @customMinimumMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minimum is 15 minutes'**
  String get customMinimumMinutes;

  /// No description provided for @customDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get customDone;

  /// No description provided for @permNotificationsOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get permNotificationsOffTitle;

  /// No description provided for @permNotificationsOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn them on so your reminders can reach you.'**
  String get permNotificationsOffBody;

  /// No description provided for @permTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get permTurnOn;

  /// No description provided for @permExactTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders may arrive a few minutes late'**
  String get permExactTitle;

  /// No description provided for @permExactBody.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms so they arrive right on time.'**
  String get permExactBody;

  /// No description provided for @permAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get permAllow;

  /// No description provided for @exactDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms?'**
  String get exactDialogTitle;

  /// No description provided for @exactDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Without this, Android may delay reminders by several minutes. You can change it any time in system settings.'**
  String get exactDialogBody;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Reminders you complete, snooze or miss will appear here.'**
  String get historyEmptyBody;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @dynamicColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Dynamic color'**
  String get dynamicColorTitle;

  /// No description provided for @dynamicColorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match colors to your wallpaper (Android 12+)'**
  String get dynamicColorSubtitle;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesNew.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoriesNew;

  /// No description provided for @categoriesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get categoriesEmptyTitle;

  /// No description provided for @categoriesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Categories group your reminders, like Work or Health.'**
  String get categoriesEmptyBody;

  /// No description provided for @categoryNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoryNewTitle;

  /// No description provided for @categoryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoryEditTitle;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryNameHint;

  /// No description provided for @categoryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give your category a name'**
  String get categoryNameRequired;

  /// No description provided for @categoryColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoryColorLabel;

  /// No description provided for @categoryIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoryIconLabel;

  /// No description provided for @categoryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get categoryDelete;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String categoryDeleteTitle(String name);

  /// No description provided for @categoryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Reminders in this category will have no category. Your history keeps its name.'**
  String get categoryDeleteBody;

  /// No description provided for @editorCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get editorCategory;

  /// No description provided for @categoryNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get categoryNone;

  /// No description provided for @categoryNewChip.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get categoryNewChip;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @upcomingFilteredEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing in {category}'**
  String upcomingFilteredEmptyTitle(String category);

  /// No description provided for @upcomingFilteredEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick another category or add a reminder.'**
  String get upcomingFilteredEmptyBody;

  /// No description provided for @historyThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing done in the last 7 days} =1{1 done in the last 7 days} other{{count} done in the last 7 days}}'**
  String historyThisWeek(int count);

  /// No description provided for @outcomeDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get outcomeDone;

  /// No description provided for @outcomeSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get outcomeSnoozed;

  /// No description provided for @outcomeMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get outcomeMissed;

  /// No description provided for @historyEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{outcome} · due {time}'**
  String historyEntrySubtitle(String outcome, String time);

  /// No description provided for @historyYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get historyYesterday;

  /// No description provided for @historyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get historyClear;

  /// No description provided for @historyClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all history?'**
  String get historyClearTitle;

  /// No description provided for @historyClearBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the record of done, snoozed and missed reminders. Your reminders are not affected.'**
  String get historyClearBody;

  /// No description provided for @historyCleared.
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get historyCleared;

  /// No description provided for @historyFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches these filters'**
  String get historyFilteredEmpty;

  /// No description provided for @settingsReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsReminders;

  /// No description provided for @settingsSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze for'**
  String get settingsSnooze;

  /// No description provided for @settingsSnoozeValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String settingsSnoozeValue(int minutes);

  /// No description provided for @settingsCategoriesTile.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settingsCategoriesTile;

  /// No description provided for @settingsCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Colors and icons for your reminders'**
  String get settingsCategoriesSubtitle;

  /// No description provided for @settingsHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get settingsHistory;

  /// No description provided for @settingsKeepHistory.
  ///
  /// In en, this message translates to:
  /// **'Keep history for'**
  String get settingsKeepHistory;

  /// No description provided for @settingsReliability.
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get settingsReliability;

  /// No description provided for @reliabilityIntro.
  ///
  /// In en, this message translates to:
  /// **'Check that reminders can reach you.'**
  String get reliabilityIntro;

  /// No description provided for @reliabilityNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get reliabilityNotifications;

  /// No description provided for @reliabilityExact.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms'**
  String get reliabilityExact;

  /// No description provided for @statusOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get statusOn;

  /// No description provided for @statusOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get statusOff;

  /// No description provided for @statusAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get statusAllowed;

  /// No description provided for @statusNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get statusNotAllowed;

  /// No description provided for @reliabilityFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get reliabilityFix;

  /// No description provided for @reliabilityTest.
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get reliabilityTest;

  /// No description provided for @reliabilityTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Arrives in about 10 seconds. Lock your phone to check it still comes through.'**
  String get reliabilityTestSubtitle;

  /// No description provided for @reliabilityTestSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. It should appear in about 10 seconds.'**
  String get reliabilityTestSent;

  /// No description provided for @reliabilityGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder didn\'t show up?'**
  String get reliabilityGuideTitle;

  /// No description provided for @reliabilityGuideBattery.
  ///
  /// In en, this message translates to:
  /// **'Some phones (Xiaomi, Oppo, Samsung and others) stop apps in the background to save battery. Set Anything Notification to \"Unrestricted\" or \"Don\'t optimize\".'**
  String get reliabilityGuideBattery;

  /// No description provided for @reliabilityGuideForceStop.
  ///
  /// In en, this message translates to:
  /// **'Force-stopping the app cancels its reminders until you open it again.'**
  String get reliabilityGuideForceStop;

  /// No description provided for @reliabilityGuideFocus.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb or a Focus mode can silence notifications.'**
  String get reliabilityGuideFocus;

  /// No description provided for @reliabilityGuideChecks.
  ///
  /// In en, this message translates to:
  /// **'Make sure Notifications and Exact alarms above are on.'**
  String get reliabilityGuideChecks;

  /// No description provided for @reliabilityOpenBattery.
  ///
  /// In en, this message translates to:
  /// **'Open battery settings'**
  String get reliabilityOpenBattery;

  /// No description provided for @settingsRetentionForever.
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get settingsRetentionForever;

  /// No description provided for @settingsRetentionYear.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get settingsRetentionYear;

  /// No description provided for @settingsRetentionDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String settingsRetentionDays(int days);

  /// No description provided for @settingsDefaultTime.
  ///
  /// In en, this message translates to:
  /// **'Default reminder time'**
  String get settingsDefaultTime;

  /// No description provided for @settingsDefaultTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used when you give a day but no time'**
  String get settingsDefaultTimeSubtitle;

  /// No description provided for @quickAddHint.
  ///
  /// In en, this message translates to:
  /// **'Try \"Pay rent every 1st at 9am\"'**
  String get quickAddHint;

  /// No description provided for @quickAddMore.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get quickAddMore;

  /// No description provided for @quickAddAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get quickAddAdd;

  /// No description provided for @quickAddPickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get quickAddPickTime;

  /// No description provided for @quickAddNoCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get quickAddNoCategory;

  /// No description provided for @quickAddTitleNeeded.
  ///
  /// In en, this message translates to:
  /// **'Add what to remind you about'**
  String get quickAddTitleNeeded;

  /// No description provided for @quickAddExamplesLabel.
  ///
  /// In en, this message translates to:
  /// **'Try typing'**
  String get quickAddExamplesLabel;

  /// No description provided for @quickAddExample1.
  ///
  /// In en, this message translates to:
  /// **'Drink water every 2 hours'**
  String get quickAddExample1;

  /// No description provided for @quickAddExample2.
  ///
  /// In en, this message translates to:
  /// **'Pay rent every 1st at 9am'**
  String get quickAddExample2;

  /// No description provided for @quickAddExample3.
  ///
  /// In en, this message translates to:
  /// **'Call mom tomorrow at 6pm'**
  String get quickAddExample3;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
