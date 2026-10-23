/// The settings that reminder logic and notifications depend on. Kept apart
/// from the UI-facing `AppSettings` so background isolates can read them
/// without any UI code.
abstract interface class ReminderPreferences {
  /// How long the Snooze button silences a reminder, in minutes.
  int get snoozeMinutes;

  /// How many days of history to keep; 0 keeps it forever.
  int get historyRetentionDays;
}
