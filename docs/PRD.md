# PRD: Anything Notification (working title)

**Status:** Draft v1 · **Date:** 2026-10-23 · **Platform:** Android only · **Stack:** Flutter 3.44 / Dart ^3.12 · **App ID:** `com.bytecode.anything_notification`
**Repo state:** empty scaffold (default `lib/main.dart`, no dependencies, one commit).

---

## 1. Context

**Problem.** Phone reminder tools are either bloated (task managers with accounts, projects and collaboration) or too thin (alarms and calendar events that don't nag, can't be snoozed from the shade, and have clumsy recurrence).

**Product.** A local-only, no-account reminder app in which every reminder is a notification. It can fire once or on a schedule, and you can mark it Done or Snooze it right from the notification. Reminders can optionally be sticky or alarm-style. Capture is one line of text ("Pay rent every 1st at 9am"). The design is Material 3 with dynamic color: simple, quick, modern.

**Decisions already made with you**

| Area | Decision |
|---|---|
| Creation | In-app only (no share-sheet intake, no calendar import in v1) |
| Recurrence | Presets + custom interval |
| Notification | Snooze + Done actions, Sticky option, Alarm-style full-screen option |
| Data | Local-only, no account, no server |
| Design | Material 3 + dynamic color (Material You), light/dark/system |
| v1 extras | Categories (color/icon), natural-language quick-add, home-screen widget, history log |
| Distribution | Google Play Store (so Play policy shapes permissions) |
| State management | Bloc (`flutter_bloc`) |

---

## 2. Goals and non-goals

**Goals**
- **G1 Reliable.** The notification arrives on the right minute across Doze, reboot, force-close, timezone change and DST.
- **G2 Fast capture.** From launch to saved reminder in 5 seconds or less and 3 interactions or fewer, using quick-add.
- **G3 Actionable.** Complete or snooze from the notification without opening the app.
- **G4 Simple and modern.** One primary screen, no sign-up, no setup wall, Material 3 polish.
- **G5 Private and Store-ready.** No `INTERNET` permission, no analytics, "no data collected" on the Data Safety form.

**Non-goals for v1:** iOS; accounts, cloud sync or sharing; calendar import; Android share-sheet intake; location or geofence reminders; subtasks, attachments or images; per-reminder custom sound; quiet hours or DND scheduling; Wear OS; localization beyond English (but use ARB/`intl` so it can be added); full RRULE rules ("2nd Tuesday of each month").

---

## 3. Users and key scenarios

Primary user: a busy everyday phone user (student, professional, parent) who wants reminders with no project-management overhead.

1. **Quick one-off.** "Call dentist tomorrow 5pm" typed into quick-add, saved in about 5 seconds.
2. **Habit.** "Drink water every 2 hours" runs all day. Each notification has Done and Snooze.
3. **Bills.** "Rent every 1st at 9am". The notification stays pinned until it is marked done.
4. **Must-not-miss.** A flight or medication reminder set to alarm-style: the screen wakes and it sounds until acted on.
5. **Glance.** The home-screen widget shows the next 3 reminders and has a "+" button.

---

## 4. Functional requirements

Priority: **P0** = ships in v1 · **P1** = in v1 if time allows · **P2** = after v1.

### 4.1 Reminders (CRUD)
- P0 Create, edit, delete, pause/resume. Fields: title (required), note, date and time, repeat, category, delivery mode (Standard / Sticky / Alarm).
- P0 Delete shows an Undo snackbar (soft delete for about 10 s, then purge).
- P0 The editor shows a live **"Next: Fri 24 Oct 6:00 PM, then Fri 31 Oct"** preview computed by the recurrence engine.
- P1 Duplicate reminder. P2 Multi-select actions.

### 4.2 Scheduling and recurrence
- P0 One-time, Daily, Weekly (pick weekdays), Monthly (day-of-month), Yearly.
- P0 Custom: every N minutes/hours/days/weeks/months/years. **Minimum interval 15 minutes.**
- P0 Ends: Never / On date / After N times.
- P0 Rules in §5 apply: wall-clock times, month-end clamping, DST, overdue handling.

### 4.3 Notification behaviour
- P0 Content: title, note as body, category name as sub-text, category color as accent, monochrome small icon.
- P0 Actions: **Done** and **Snooze Xm** (X is the default from Settings; the snooze picker offers 5m / 10m / 30m / 1h / custom / "Tomorrow morning"). Actions run in the background without opening the app.
- P0 Tapping the notification opens the reminder detail.
- P0 **Done on a recurring reminder** completes that occurrence only; the series continues.
- P0 **Sticky:** `ongoing` and not auto-cancelled. Caveat: Android 14+ lets users swipe ongoing notifications away, so this is best effort. A swiped occurrence stays in Overdue until handled.
- P0 **Alarm-style:** high-priority alarm channel, alarm audio usage, repeating sound until acted on, and a full-screen intent that wakes the screen to a Flutter "Alarm screen" (big title, Done, Snooze). If the full-screen permission is missing, fall back to a heads-up notification and show a warning in the editor.
- P0 Channels: `reminders` (high), `alarms` (alarm usage), `missed` (default).

### 4.4 Quick-add (natural-language, on-device, English)
- P0 A single text field in a bottom sheet. Live preview chips show the parsed **When**, **Repeat** and **Category**, each tappable to correct.
- P0 Grammar covers: relative (`in 30 minutes`, `tomorrow`, `tonight`), clock times (`6pm`, `18:30`), weekdays (`on friday`), dates (`12 Nov`, `Dec 3`), recurrence (`every day`, `weekdays`, `every mon wed fri`, `every 2 days`, `every 1st`, `monthly`, `yearly`), and `#tag` for a category.
- P0 Defaults: a date without a time uses the default time from Settings (9:00 AM). A time without a date means the next occurrence of that time (today if still ahead, else tomorrow).
- P0 If nothing parses, the whole text becomes the title and the time picker opens. A "More options" link opens the full editor pre-filled.
- Non-goal: any network or LLM call.
- Examples: see Appendix A (these become the unit-test table).

### 4.5 Categories
- P0 Name + color + icon (curated icon set). Seeded defaults: Personal, Work, Health, Bills (editable and deletable).
- P0 Filter chips on Upcoming. Deleting a category moves its reminders to "No category" after confirmation.

### 4.6 Upcoming (home)
- P0 Grouped list: **Overdue**, Today, Tomorrow, This week, Later. A paused section is collapsed at the bottom.
- P0 Card: category icon in a tonal circle, title, "6:00 PM · Repeats weekly", trailing Done button. Swipe right = Done, swipe left = Delete with Undo.
- P0 Empty state with tappable example chips ("Try: Drink water every 2 hours") that prefill quick-add.
- P0 Single primary action: extended FAB "New reminder" opens quick-add.

### 4.7 History
- P0 Per-occurrence log: Done, Snoozed, Missed (see §5.4), grouped by day, filterable by outcome and category.
- P0 Header summary: "N done this week". Retention 90 days (setting), plus Clear history.
- P2 Streaks and charts.

### 4.8 Home-screen widget (P1)
- Next 3 upcoming reminders (category dot, title, time) and a "+" that deep-links to quick-add. Tapping an item opens its detail.
- Uses Material You colors on Android 12+. Updates on every data change, after notification actions, on boot and on time or timezone change.

### 4.9 Settings and permission health
- P0 Theme (System / Light / Dark), dynamic color on/off, default reminder time, default snooze duration, 12/24h (follow system), category manager.
- P0 **Reliability panel:** live status for Notifications, Exact alarms, Full-screen alerts, each with a one-tap fix that deep-links to the right system screen. A "Send test notification (10 s)" button, and a short "Why did my reminder not fire?" guide covering OEM battery savers and force-stop.
- P1 Pure-black dark theme. P2 JSON export/import backup.

### 4.10 Onboarding and permissions
- P0 No sign-in. A lightweight 1-screen value primer is shown once.
- P0 The notification permission is requested **in context**, when the first reminder is saved, with a short rationale. If denied, show an inline banner with "Open settings".
- P0 The exact-alarm permission is checked on first save of a timed reminder, with a guided prompt. If it is declined, fall back to inexact delivery and show a "may be delayed" notice.

---

## 5. Domain rules (the tricky parts)

1. **Wall-clock semantics.** "9:00 AM daily" stays 9:00 AM local, even after you travel. Store local date-time plus recurrence rule, and compute instants with `timezone` at schedule time. On `TIMEZONE_CHANGED` and `TIME_SET`, reschedule everything.
2. **DST.** A nonexistent local time (spring forward) is shifted forward by the length of the gap (02:30 becomes 03:30 when clocks jump 02:00 to 03:00). An ambiguous time (fall back) fires once, on the first occurrence.
3. **Month-end and leap day.** "Monthly on the 31st" clamps to the last day of shorter months. "Yearly on 29 Feb" fires on 28 Feb in non-leap years.
4. **Occurrence states.** `pending → done | snoozed | missed`.
   - A one-time reminder whose time has passed with no action is **Overdue**. It stays visible with Done / Snooze / Delete until resolved.
   - A recurring occurrence becomes **Missed** (logged in History) once the next occurrence fires. Only the latest overdue occurrence shows in Upcoming.
   - Snooze creates a one-off alarm for the same occurrence. It does not change the series.
5. **Reconciliation (single source of truth = DB).** A `reconcile()` routine computes the desired alarm set, diffs it against the plugin's pending list, then cancels and adds. It runs on app start, on resume, after any edit, on boot, on timezone or time change, after Android Auto Backup restore, and from a periodic WorkManager "top-up".
6. **Alarm budget.** Android caps an app at roughly 500 concurrent alarms. Schedule a rolling window per reminder (next 12 occurrences or 14 days, whichever is fewer; up to 24 for sub-hour intervals), with a global cap of about 400. The scheduler picks the earliest occurrences first.

---

## 6. UX and visual design

**Navigation.** M3 `NavigationBar` with three destinations: **Upcoming · History · Settings**. Categories live under Settings. The primary action is the extended FAB. Predictive back is enabled.

**Key screens**
1. **Upcoming:** large collapsing title ("Today, Thu 23 Oct"), category filter chips, grouped cards, sticky group headers.
2. **Quick-add sheet:** the text field is autofocused, with parse chips beneath and a "More options" link.
3. **Editor:** list-tile sections (When · Repeat · Category · Delivery · Note) plus the "Next:" preview. The custom-repeat sheet has Every [N] [unit], weekday toggles, month day or "last day", and an Ends row.
4. **Alarm screen:** full-bleed, giant title, Done and Snooze buttons. It shows over the lock screen.
5. **History**, **Settings** (with the Reliability panel), **Category manager**, and a one-screen **Primer**.

**Design system**
- Material 3 with `ColorScheme.fromSeed` and `dynamic_color` (Material You). Fallback seed is an indigo-violet (about `#5B5BD6`).
- Surfaces use tonal `surfaceContainer*` roles, with no heavy shadows. Cards radius 24dp, sheets 28dp, pill chips.
- Typography: one bundled variable font (OFL licensed, e.g. Inter or Plus Jakarta Sans). **Bundle it as an asset. Do not fetch it at runtime** (offline, no `INTERNET`).
- Motion: container-transform from FAB to sheet, animated list insert/remove, 200–400 ms emphasized easing, haptic tick on Done.
- Accessibility: 48dp touch targets, correct at 200% font scale, TalkBack labels on cards and notification actions, AA contrast in light and dark. Edge-to-edge with correct insets.
- Adaptive + themed (monochrome) launcher icon, splash screen, and a monochrome notification small icon.

---

## 7. Technical design

**Recommended stack** (confirm exact versions with `flutter pub add` at implementation time)

| Concern | Choice |
|---|---|
| State | `flutter_bloc` (Cubits for list, editor, settings and permissions), `equatable` |
| Storage | `drift` + `drift_flutter` (SQLite); `shared_preferences` for settings |
| Notifications | `flutter_local_notifications` + `timezone` + `flutter_timezone` |
| Background | A native Kotlin `ReconcileWorker` (AndroidX WorkManager) that runs a headless Flutter engine to re-arm everything: after reboot, app update, time or time zone change, exact-alarm permission change, and every 6 hours as a safety net. Notification buttons use the plugin's `@pragma('vm:entry-point')` background handler. (The `workmanager` plugin is not used.) |
| Navigation | `go_router` |
| Theming | `dynamic_color` **1.x** (2.x switched to the separate `material_ui` package, whose `ColorScheme` does not match `package:flutter/material.dart`), bundled Plus Jakarta Sans |
| Widget | `home_widget` (native `AppWidgetProvider` + XML RemoteViews, Kotlin) |
| Permissions | `flutter_local_notifications`' own Android helpers (notification permission, exact alarms, open settings); no `permission_handler` |
| Misc | `uuid`, `intl` |
| Test | `flutter_test`, `mocktail`, `integration_test` (`bloc_test` dropped: its `test` dependency conflicts with `drift_dev`) |

**Folder structure** (feature-first)
```
lib/
  main.dart                  bootstrap, DI, notification init
  app/                       app.dart, router.dart, theme/
  core/                      db/, notifications/, time/, permissions/, widgets/
  features/
    reminders/   {data, domain, presentation(bloc, pages, widgets)}
    quick_add/   parser (pure Dart) + sheet
    categories/  history/  settings/  onboarding/  alarm/
```

**Pure-Dart, heavily tested core:** `RecurrenceEngine` (`nextOccurrence`, `occurrencesBetween`), `QuickAddParser`, and `AlarmPlanner` (desired alarm set from reminders and a clock). They take an injected clock and have no Flutter or plugin dependencies.

**Data model (Drift)**
- `reminders`: id, title, note, categoryId?, startLocal, recurrence (type, interval, unit, weekdayMask, dayOfMonth, end condition), delivery (standard|sticky|alarm), status (active|paused|done|deleted), createdAt, updatedAt
- `categories`: id, name, colorValue, iconKey, sortOrder
- `occurrences` (history): id, reminderId, scheduledLocal, outcome (done|snoozed|missed), at
- No `alarms` table. Armed notifications are identified by a **deterministic id** (a hash of reminder id, kind and occurrence time), so re-arming replaces rather than duplicates. This makes concurrent re-arming from several isolates safe.
- Snapshot title and category on history rows so history survives deletes.

**Notification actions in the background isolate.** The handler opens the same SQLite file (WAL; `drift_flutter` `shareAcrossIsolates`), writes Done or Snooze, then runs `reconcile()` and refreshes the widget. The UI also re-queries on `AppLifecycleState.resumed`. Payload is JSON `{reminderId, occurrenceAt, kind}`.

**Scheduling.** `AlarmPlanner` (pure Dart) decides what should be armed; `reconcile()` diffs that against the plugin's pending notifications (each carries a JSON payload with its fire time, reminder revision and exact flag) and applies the difference. `rearmAll` re-arms everything and is used for cold start, boot, time and time zone changes, and the periodic worker, because a force stop silently clears alarms while the plugin's own bookkeeping still lists them. Uses `AndroidScheduleMode.exactAllowWhileIdle` when exact alarms are granted, else `inexactAllowWhileIdle`. Decision from the M1 spike: every rule uses the rolling window (no plugin `matchDateTimeComponents` repeats), keeping one code path.

**Android configuration**
- `minSdk 26` (guaranteed notification channels; covers the large majority of devices). `targetSdk` = whatever Play currently requires (expected API 36 by now; confirm before release).
- Enable core-library desugaring (the notification plugin requires it) and add the plugin's R8/ProGuard keep rules. **Test the release build.**
- Manifest: plugin receivers (scheduled, boot, action); `enableOnBackInvokedCallback`; lock-screen display (`setShowWhenLocked` / `setTurnScreenOn`) applied **only when launched from the alarm full-screen intent**, never as static `MainActivity` attributes, which would show the whole app over the lock screen on every launch (M4); widget provider receiver; `allowBackup` with backup/data-extraction rules.
- After an Auto Backup restore, the DB comes back but alarms do not, so the first launch must `reconcile()`.

**Permissions**

| Permission | Why | Handling |
|---|---|---|
| `POST_NOTIFICATIONS` (API 33+) | show notifications | contextual runtime ask, denied-state banner |
| `SCHEDULE_EXACT_ALARM` (or `USE_EXACT_ALARM`) | on-time delivery | guided grant; fallback to inexact; see Play note below |
| `RECEIVE_BOOT_COMPLETED` | re-arm after reboot | normal permission |
| `VIBRATE`, `WAKE_LOCK` | alarm behaviour | normal permission |
| `USE_FULL_SCREEN_INTENT` | alarm-style screen | opt-in per reminder; fallback to heads-up |
| **Not used** | `INTERNET`, `READ_CALENDAR`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (Play-restricted) | the reliability guide deep-links to battery settings instead |

---

## 8. Play Store readiness

- **Exact alarms and full-screen intent** need Play Console permission declarations. Only alarm, timer and calendar-style core functions qualify for the auto-granted exact-alarm permission. Plan: declare `SCHEDULE_EXACT_ALARM` (user-grantable), argue the core function in the declaration, keep the inexact fallback, and re-read the current policy text before submission. This is the main policy risk (§10).
- **Data Safety form:** no data collected or shared (no `INTERNET`). Still publish a short privacy policy page.
- **Personal developer accounts** may need a closed-testing period (about 12 testers for 14 days at the time of writing; verify) before production access.
- Assets: adaptive icon, feature graphic, screenshots (light/dark, widget), short and full description, content rating, signed AAB (upload key + Play App Signing), pre-launch report.

---

## 9. Quality, testing and success metrics

**Targets**
- **Reliability:** at least 99% of scheduled notifications arrive within 60 s on the device matrix (Pixel, Samsung, plus one aggressive-battery OEM such as Xiaomi or Oppo).
- **Capture speed:** quick-add to saved in 5 s or less (manual stopwatch test).
- **Performance:** cold start under 1.5 s on a mid-range device; 60 fps list scroll with 500 reminders.
- **Stability:** crash-free sessions above 99.5% and ANR rate under Play bad-behaviour thresholds (Android vitals).
- **Size:** release AAB under 25 MB (target).

**Test plan**
- **Unit:** `RecurrenceEngine` table tests (DST gaps and overlaps, month-end, leap day, end-after-N, custom intervals), `QuickAddParser` table tests from Appendix A, `AlarmPlanner` window and cap logic.
- **Cubits:** plain stream/state assertions for list, editor, settings and permission cubits.
- **Widget and golden:** Upcoming, editor and alarm screens, in light and dark at 200% font scale.
- **Integration:** create → pending alarm exists; Done and Snooze from a simulated action; reconcile after "reboot".
- **Manual or adb on real devices**
  - `adb shell dumpsys alarm | grep anything_notification` (alarms are armed)
  - `adb shell dumpsys notification --noredact` (channels and posted notifications)
  - `adb shell cmd deviceidle force-idle` (Doze delivery)
  - reboot, then change timezone and time (re-arm)
  - revoke the exact-alarm permission (fallback and banner)
  - deny notifications (banner)
  - force-stop (documented limitation)
  - release-build smoke test

---

## 10. Milestones

| # | Milestone | Exit criteria |
|---|---|---|
| M0 | Foundations | App ID, `minSdk`, desugaring, manifest, lints, theme (M3 + dynamic color), router shell, DI, folder structure |
| M1 | Core reminders **+ scheduling spike** | DB schema, `RecurrenceEngine` + tests, scheduler + `reconcile()`, create/edit/list, one-time and recurring, permissions flow, Done/Snooze actions, boot + timezone handling. **Gate:** reliable delivery under Doze and reboot on a Pixel and one aggressive OEM |
| M2 | Categories, Overdue, History, Settings | Reliability panel, test-notification button, 90-day retention. **Status: built.** Deferred on purpose: the "default reminder time" setting (nothing uses it until quick-add, M3) and the "Full-screen alerts" row of the Reliability panel (until the permission exists, M4). Added: a snooze-length setting, history retention choices (30 / 90 / 365 days / forever), and Missed entries filed under when the next occurrence fired |
| M3 | Quick-add | Parser passes the Appendix A table; preview chips; fallbacks. **Status: built.** Adds the default-reminder-time setting. Known limits: English only; a bare "at 5" (no am/pm or colon) is not read as a time; "in N months/years" and end conditions ("until", "N times") are not parsed, only set in the editor |
| M4 | Sticky + Alarm-style | Alarm channel, full-screen Alarm screen, permission fallbacks |
| M5 | Home-screen widget (P1) | Upcoming list, quick-add deep link, live updates |
| M6 | Polish and Play release | Icons, splash, a11y pass, R8 release test, Play declarations, privacy policy, closed test |

---

## 11. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Play rejects exact-alarm or full-screen declarations | Delivery or alarm-style degraded | Inexact fallback, heads-up fallback, clear in-app warning, re-check policy before submission |
| Rolling-window alarms starve if the app is never opened | Missed recurring reminders | Periodic WorkManager top-up, plugin-native repeats for simple rules, M1 gate; fallback is a native Kotlin AlarmManager receiver |
| OEM battery killers or force-stop clear alarms | Silent failures | Reliability panel + guide; reconcile on every app open |
| Android 14+ lets users swipe away ongoing notifications | "Sticky" is not absolute | Document it; keep occurrence Overdue and visible |
| Background-isolate DB access and UI staleness | Wrong or stale lists | `shareAcrossIsolates`, re-query on resume, integration test |
| Natural-language parsing edge cases | Wrong time saved silently | Always show the editable preview; test table; never auto-save without the preview |
| Local-only data lost on device change | Data loss | P2 JSON export/import; Auto Backup restore + `reconcile()` |

---

## 12. Assumptions and open questions

**Assumptions I made (tell me to change any):**
- `minSdk 26`; English only; default reminder time 9:00 AM; snooze default 10 minutes; history retention 90 days.
- Working product name "Anything Notification" until you choose a final store name.
- One reminder is one notification stream. There are no per-category channels or per-reminder sounds.

**Open questions for later**
- Final app name, icon direction and tagline.
- Play account type (personal or organization), which affects the closed-testing requirement.
- Where the privacy policy will be hosted.
- Do you want the widget in the first release, or after launch?

---

## Appendix A: Quick-add examples (become parser tests)

| Input | Title | When | Repeat | Category |
|---|---|---|---|---|
| `Call mom tomorrow at 6pm` | Call mom | tomorrow 18:00 | none | none |
| `Pay rent every 1st at 9am` | Pay rent | next 1st 09:00 | monthly, day 1 | none |
| `Water plants every 2 days` | Water plants | default time, next occurrence | every 2 days | none |
| `Gym every mon wed fri 7am #health` | Gym | next Mon/Wed/Fri 07:00 | weekly Mon,Wed,Fri | Health |
| `Take pills in 30 minutes` | Take pills | now + 30 min | none | none |
| `Standup weekdays 9:30` | Standup | next weekday 09:30 | weekly Mon–Fri | none |
| `Dentist on 12 Nov at 4pm` | Dentist | 12 Nov 16:00 | none | none |
| `Mom's birthday Dec 3 yearly` | Mom's birthday | Dec 3 default time | yearly | none |
| `Buy milk` | Buy milk | (none parsed) opens time picker | none | none |
