# Manager App — Work Log

This file did not exist before 2026-09-03, even though substantial work had
already happened in this app. Starting it now, matching the convention
already established in `goal_master/CODEX_WORK_LOG.md` and
`goal-master-web/CODEX_WORK_LOG.md` — same repo family, same log format, not
a new/competing system.

For architecture and cross-repo decisions, `goal_master/PROJECT_CONTEXT.md`
remains the authoritative source where it overlaps (e.g. `BookingSource`
attribution rules, which live in the backend and are shared by both apps).
This file is for what changed in *this* app and why.

---

## 2026-09-03 — Retroactive summary of recent monthly/attendance/venue work

Logged after the fact; entries below summarize sessions that predate this
file.

- Fixed the «الحجز الشهري» crash (`int` is not a subtype of `String`,
  `FormatException` on the DATETIME time field) and rebuilt the screen as a
  grouped monthly-series list (`MonthlySeriesGroup`, one card per series
  instead of one per session).
- Added per-occurrence attendance actions inside the series card — reuses
  the existing `AttendanceActionsSheet`/`mark-attendance` authority; no
  second attendance implementation. Verified live on simulator with an
  isolated fixture series (created and fully cleaned up afterward — no real
  data touched).
- Reschedule flow for one occurrence (`update-booking`) was audited and
  found to leave `start_at`/`end_at` stale on the legacy update path; fixed
  to write through the same `Occurrence` authority the model's own
  `saving()` hook uses, since a query-builder mass update bypasses model
  events. Backend fix, additive, covered by
  `ManagerOccurrenceRescheduleTest`.
- Booking-time-window screen rebuilt as "متى يفتح ملعبك؟" — one opening/
  closing time input that the client splits into the existing evening/
  after-midnight band records on save (`OpeningHours` domain class). Zero
  backend or database change: the underlying `sch_employees`-as-bands model,
  `operational_date` derivation, and `sch_employee_services` links are
  untouched — this is a presentation-layer translation only.
- Service editor ("الملاعب والخدمات") had its مسائي/بعد منتصف الليل chips
  removed. A new service now inherits whichever bands are currently enabled
  on the venue's hours; an existing service keeps exactly the bands it had.
  Derivation rule lives in `add_first_venue_body.dart`, tested in
  `service_band_ownership_test.dart`.
- «بيانات الملعب» redesigned to a read-first profile screen with edit-on-
  demand sections, navigation rows (not duplicate editors) to «فترات الحجز»
  and «الملاعب والخدمات».

**Known gaps carried forward:**
- Manager-side complaint/dispute (`BookingCaseSheet`) is not reachable from
  the series details screen on the Customer App side (pre-existing gap
  outside this app, noted for whoever picks it up).
- The global app bar (`AppBarContent`, Customer App) and this app's own
  narrow-screen fragility in a few older cards are known, pre-existing,
  out-of-scope issues discovered while testing — not fixed under this app's
  own tasks, documented in the relevant task's own report instead of here.

**Status:** all of the above already covered by widget/unit tests and
`flutter analyze` (0 errors) at the time each change landed. Not committed.
Not deployed.

## 2026-09-04 — Booking-details redesign, WhatsApp, and no-show dispute (Phase 1)

- Single booking's details screen (`booking_items_details.dart.dart`)
  redesigned: removed directions/address row, replaced the compressed
  facility-row list with three cards — موعد الحجز (date/time, inline
  "تعديل الموعد" beside the time instead of a bottom-width button reusing
  `RescheduleBookingSheet`/real `listNightSlots` availability, no picker),
  العميل, الدفع. New file `booking_summary_cards.dart` holds all three;
  `build_location_row.dart` / `build_facility_row copy.dart` deleted (fully
  superseded, not left as dead code).
- "واتساب العميل" action added to the customer card — WhatsApp opened with
  a prefilled message only, never auto-sent. Libyan number normalized to
  `wa.me` international format locally (existing `launch_whats_app.dart`
  helper is Saudi-coded and message-less for one unrelated caller — left
  untouched, not reused). Hidden once `BookingDetails.hasElapsed` (existing
  authority, already backing reschedule eligibility) — "ننتظرك في الموعد"
  makes no sense for a booking that already happened.
- Payment card: platform-prepaid bookings (Paypal/Stripe/Wallet —
  `payment_type_id != LocalPayment`) always display "مدفوع عبر Goal
  Master", never the raw (sometimes stale) `payment_status` text, and never
  the debt-reminder action — same `payment_type_id` authority the backend
  itself already uses for `pay_on_arrival`.
- "تذكير بالمبلغ المتبقي" reminder action: eligible only for
  venue-collected (`LocalPayment`) bookings with `remaining > 0`, not
  cancelled. Backend-authoritative, not string-inferred.
- **No-show dispute (Phase 1 — backend + Manager App only; Customer App
  confirmation UI and Admin dispute center are separate, later phases):**
  - Backend: `booking_disputes` gained `manager_proposed_result` /
    `manager_proposed_by` / `manager_proposed_at` (nullable, additive
    migration) — the live proposal on an open dispute, denormalized from
    `booking_case_events` for a cheap read. `BookingDispute::
    openNoShowDisputeFor()` is the one authoritative "is there an open
    no-show dispute" check; `has_open_no_show_dispute` (booking-details
    endpoint) and everything else key off it — never off the historical
    `attendance_status`/`customer_confirmation` pair, which stay frozen at
    their reported values even after a dispute resolves.
  - New `DisputeService::proposeNoShowResolution()` +
    `POST manager/cases/propose-no-show-resolution` (reuses
    `CancellationCaseController`, `AttendanceService::canReport` for
    branch-scoped authorization — no new auth path). A manager proposal
    ("تم الاتفاق أن الزبون حضر" / "لم يحضر" / "ما زال هناك خلاف") records
    intent and moves `status` within the existing open set
    (escalated ↔ under_review) — it **never** closes the dispute or
    touches money/refund/commission. Tests:
    `tests/Feature/NoShowDisputeManagerProposalTest.php` (7 cases).
  - Manager App: while `has_open_no_show_dispute` is true, the payment
    card's reminder action is replaced (never shown alongside) by a
    neutral "توضيح حالة الحجز" WhatsApp message — states the recorded
    remaining amount without asserting it as settled debt, states both
    sides' accounts, asks the customer to get in touch. No accusatory
    wording either direction. The three proposal actions render in the
    same card when a dispute is open, disabled while submitting, and
    reload the booking on success so the fresh dispute state shows.
  - Explicitly not built yet (by design, staged): Admin dispute center /
    notifications, Customer App confirm-or-reject UI, venue customer
    block/unblock.

Tests: `tests/Feature/NoShowDisputeManagerProposalTest.php` (7),
`AttendanceAndRestrictionTest.php` (18) and
`CancellationExceptionAndDisputeTest.php` (18) re-verified with no
regressions (backend); `test/booking_summary_cards_test.dart` (18, Manager
App) covers the reminder/neutral-action switch, prepaid display, and the
elapsed-booking WhatsApp hide. `flutter analyze` — 0 errors. `php -l` clean
on all changed PHP files. Migration applied to the shared dev DB (additive,
nullable columns only); all PHP tests run inside `DatabaseTransactions`, no
real data persisted. Not committed. Not deployed.

## 2026-09-04 (final) — Venue customer block/unblock (Phase 4)

Full backend design/authority in `goal-master-web/CODEX_WORK_LOG.md`
(same-day final entry) — new `customer_venue_blocks` table +
`VenueCustomerBlockService`, enforced at `BookingAvailabilityService`, the
one authority every booking-creation path (customer app, this app's manual
booking, chatbot, monthly series) already shares.

Manager App side: new `venue_block_sheet.dart` (`VenueBlockSheet` — reason
required from the 5 fixed codes, optional private note, explicit warning
text; `VenueUnblockConfirmSheet` — plain confirm). Wired into the existing
`BookingCustomerCard` (booking-details "العميل" card, `booking_summary_cards.dart`)
rather than a new screen: shows "حظر الزبون" when clear, or "الزبون محظور
من الحجز — <reason>" + "إلغاء الحظر" when blocked. New repo calls
`blockCustomerFromVenue`/`unblockCustomerFromVenue`; `BookingDetails` gained
`isBlockedByVenue`/`venueBlockReasonLabel`, populated by `getDataInfo()` at
no extra round trip (same pattern as Phase 1's `has_open_no_show_dispute`).

Second UX surface from the task ("existing customer details/relationship
screen") turned out on inspection to be `kItemsUserDetainsView` — a
bookings-list-filtered-by-customer view with no header area suited to this
action — not extended this pass; the booking-details card is the one place
a manager actually reaches this from today. Noted as the deferred surface.

Tests: `test/booking_summary_cards_test.dart` (+2, block/unblock rendering,
reason shown / private note never rendered) and new
`test/venue_block_sheet_test.dart` (3 — reason required, optional note
carried through, unblock only on explicit confirm). `flutter analyze` — 0
errors project-wide. Backend: `VenueCustomerBlockTest.php` (12, 1 skipped
for a missing fixture) + full regression sweep, 161/161 passing. Not
committed. Not deployed.

## 2026-09-05 — Bug fix: last notification replayed on every app restart

**Root cause:** `NotificationSocketService`'s socket `'notification'` handler
(`lib/utils/notification_socket_service.dart`) called
`_showNotification()`/`onNotificationReceived()` unconditionally for every
event, with no deduplication at all. The socket re-sends the customer's
latest notification on every (re)connect — which happens on every app
launch — so a restart alone made the last notification look brand new every
single time, independent of whether anything had actually changed
backend-side. `NotificationCubit`'s 15s polling fallback had a *look-alike*
guard (`_lastNotificationId`), but it was a plain in-memory field that reset
to `null` on every restart, so it offered no real protection against this
specific case either — same class of bug, just less exposed since polling
only starts after the socket path already usually fires first.

**Fix:** new `NotificationDedupStore` (`lib/utils/notification_dedup_store.dart`)
— persists the id of the last notification actually shown
(`SharedPreferenceUtil`, new `PrefKey.lastShownNotificationId`), so it
survives a restart instead of resetting. `markIfNew(id)` is the one
authoritative gate; the socket handler now checks it before showing/forwarding
anything, and the polling path's old in-memory check was replaced with the
same call — one shared, persisted source of truth for both. An empty id
never suppresses (nothing to compare). Deliberately tracks only the single
most recent id, not a growing set — sized to the actual bug, not a general
history.

Nothing else changed: `_onNotificationReceived` (sound, visual alert,
list-insert), `markAsRead`/`markAllAsRead`, `unreadCount`, and the paging/
history list are untouched — dedup only gates whether that method is called
at all, never what it does once called, so read/unread state and
Notification Center history are unaffected by construction.

Files: `lib/utils/notification_dedup_store.dart` (new),
`lib/utils/notification_socket_service.dart`,
`lib/features/notification/manager/notification_cubit/notification_cubit.dart`,
`lib/core/components/keys_values.dart`, new
`test/notification_dedup_store_test.dart` (6 tests — first-time shown,
same-id-after-"restart" suppressed and stays suppressed, new id after
restart still shown, identical text with different ids both shown, empty id
never suppresses, value persists across separate reads). `flutter analyze`
— 0 errors project-wide. Not committed. Not deployed.

Deferred, not part of this bug: `NotificationSocketService`'s own generic
"📢 إشعار جديد" alert and `NotificationCubit`'s richer one (wired via
`onVisualNotification` in `main.dart`) both fire for the same genuinely-new
event — a separate, pre-existing double-notification-per-event issue,
unrelated to restart replay and out of this fix's scope.

## 2026-10-10 — Android Smart Fill unsupported-status diagnostics

- Compared Goal Master Android bridge registration, channel names, WebView
  lookup, frame-scoped WebKit API, origin gate, and resolved WebKit dependency
  with TaxiSta. Both use AndroidX WebKit 1.16.0 and the same required feature
  gates; the app previously collapsed every native install failure into one
  boolean, so the exact runtime branch from the installed phone could not be
  established from old logs.
- Native install now reports only safe status codes (missing WebView,
  unsupported feature, installation failure, or installed). Debug Flutter
  logs those codes only. A bounded retry handles only the transient
  `webview_not_registered` startup state before payment HTML is loaded.
- Retained Debug-only registration and exact Moamalat origin allowlist.

Verification: focused Flutter analysis clean; owner/card-scan tests pass;
synthetic frame-script tests pass. Customer and manager Debug APKs build and
install/launch on an Android 16 emulator. No approved provider-origin frame
was loaded; actual Moamalat Smart Fill remains unverified. APK artifacts are
not proof of live form compatibility. **Status:** uncommitted, not deployed.

## 2026-10-10 — Android Debug startup crash cross-check

- Reproduced the Customer launcher crash on the Android 16 emulator. Its
  fatal stack was `ClassNotFoundException` for the manifest launcher class
  `com.ayoub.goalmaster.MainActivity`; the class was missing from the
  affected Customer APK's DEX despite existing source. This fails before
  Flutter engine setup or Smart Fill registration.
- Confirmed Manager's APK contained `com.rahbdev.goaladmin.MainActivity` and
  started normally. Clean-built Manager as well; no Manager native change was
  needed and no payment or Smart Fill behavior was removed.

Verification: Manager final APK contains its launcher class and was
installed/launched on the Android 16 emulator; process remained alive without
a crash-buffer exception. No physical device was touched. **Status:** build
artifact regenerated; source work remains uncommitted.

## 2026-10-10 — Android Smart Fill end-to-end diagnostics

- Traced the card-panel tap through owner-scoped CardVault lookup, native
  channel, WebView id, AndroidX WebKit install, frame-origin gate and fill
  response. The selected card is still fetched only after an explicit tap;
  native output remains limited to safe completion labels. No PAN/CVV/name/
  expiry is logged or included in diagnostic UI.
- Replaced generic panel failures with Debug-only status codes and carried
  install/frame/card/fill states to the panel. The parent page inspects only
  iframe `src` origins; it never reads a child document. Added a single exact
  local fixture origin available only in Debug for the cross-origin test.
- TaxiSta's current checkout explicitly disables its Android Smart Fill
  path, so its native code is a reference for API usage, not evidence that
  Android fill currently works there. No mismatch in Goal Master's method
  channel or `exp` payload key was found.

Verification: focused analysis and owner/card-scan unit tests passed; the
synthetic DOM script checks passed. The native integration-test app built and
installed, but Flutter's emulator driver could not attach to its test isolate,
so cross-origin native filling was not verified. Both Debug APKs built,
installed and remained foreground/running on Android 16 emulator without a
fatal exception. Actual Moamalat/Samsung behavior remains unverified.
**Status:** uncommitted, not deployed.

## 2026-10-10 — Saved-card copy fallback and install diagnostics

- Added Debug-only PAN, expiry, and holder copy buttons to the existing panel.
  Each tap rechecks account scope and selected card, then reads that card from
  CardVault. Full PAN remains masked in the UI. Clipboard cleanup is
  conditional after 30 seconds and on background; Android 13+ marks the PAN
  clip sensitive when the existing clipboard still matches.
- Found that Dart mapped native `invalid_request` to `SCRIPT_INSTALL_FAILED`,
  conflating input/origin validation with a thrown installation call. Split
  these statuses. Native exceptions now identify the failing registration
  operation and return only sanitized exception type/reason in Debug.
- TaxiSta uses the same AndroidX WebKit 1.16.0 APIs and its current Dart
  checkout disables Android Smart Fill. The old Samsung exception was
  swallowed by native code, so its underlying operation cannot be recovered
  from the former status alone.

Verification: Customer and Manager copy/owner/diagnostic tests passed, focused
analysis passed, both Android Debug APKs built and launched on the Android 16
emulator without a fatal exception. Native installation on the Samsung was
not available for reproduction; actual Moamalat fill remains unverified.
Clipboard history clearing is best-effort and cannot be guaranteed on every
device. **Status:** uncommitted, not deployed.
