/// Lifecycle notifications: trial reminders and seasonal offers.
///
/// Separate from [Reminders] (daily care), which cancels and re-schedules its
/// own ids on every repository change. Lifecycle ids live in their own range
/// so that never wipes them.
library;

class Lifecycle {
  /// A yearly trial just started on [startedOn]. Schedules the value nudges
  /// and the honest "you'll be charged on day 7" reminder two days before.
  static Future<void> scheduleTrialReminders(DateTime startedOn, {String lang = 'en'}) async {}

  /// The person bought or the trial ended: drop any pending trial reminders.
  static Future<void> cancelTrialReminders() async {}
}
