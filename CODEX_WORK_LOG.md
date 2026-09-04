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
