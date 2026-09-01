import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/booking/data/model/created_series.dart';

/// The success screen describes the series the server made, not the request.
///
/// It used to be drawn from the single occurrence the manager had selected, so
/// a four-week booking reported that one appointment's price — «66 د.ل» for a
/// 264 د.ل commitment — and named one of its four dates as if it were the
/// whole thing.
void main() {
  Map<String, dynamic> occurrence({
    required int seq,
    required String date,
    String start = '20:00:00',
    String end = '21:00:00',
    double price = 66,
    bool replacement = false,
    String? originalDate,
  }) =>
      {
        'sequence': seq,
        'date': date,
        'start_time': start,
        'end_time': end,
        'start_at': '$date $start',
        'end_at': '$date $end',
        'price': price,
        'is_replacement': replacement,
        'original_date': originalDate,
      };

  Map<String, dynamic> payload({
    double total = 264,
    double paid = 0,
    List<Map<String, dynamic>>? occurrences,
  }) {
    final rows = occurrences ??
        [
          occurrence(seq: 1, date: '2026-08-30'),
          occurrence(seq: 2, date: '2026-09-06'),
          occurrence(seq: 3, date: '2026-09-13'),
          occurrence(seq: 4, date: '2026-09-20'),
        ];

    return {
        'series_id': 100002,
        'occurrence_count': rows.length,
        'target_occurrence_count': 4,
        'price_per_occurrence': 66,
        'total_amount': total,
        'paid_amount': paid,
        'remaining_amount': total - paid,
        'payment_status': paid <= 0 ? 2 : (paid >= total ? 1 : 3),
        'branch': 'ملاعب الجدار',
        'day_name': 'الأحد',
        'occurrences': rows,
      };
  }

  test('a normal booking response carries no series', () {
    expect(CreatedSeries.tryFrom(null), isNull);
    expect(CreatedSeries.tryFrom({'msg': 'ok'}), isNull);
  });

  test('the total is the server figure, never one appointment', () {
    final series = CreatedSeries.tryFrom(payload())!;

    expect(series.totalAmount, 264);
    expect(series.occurrenceCount, 4);
    expect(
      series.totalAmount,
      isNot(series.occurrences.first.price),
      reason: 'the bug was reporting 66 as the total of a 264 booking',
    );
  });

  test('all four appointments are described, with their own times', () {
    final series = CreatedSeries.tryFrom(payload())!;

    expect(series.occurrences.map((o) => o.date), [
      '2026-08-30',
      '2026-09-06',
      '2026-09-13',
      '2026-09-20',
    ]);
    expect(series.occurrences.first.startAt, DateTime(2026, 8, 30, 20));
    expect(series.occurrences.last.endAt, DateTime(2026, 9, 20, 21));
  });

  test('a moved appointment shows its new time and is flagged', () {
    final series = CreatedSeries.tryFrom(payload(
      occurrences: [
        occurrence(seq: 1, date: '2026-08-30'),
        occurrence(
          seq: 2,
          date: '2026-09-06',
          start: '22:00:00',
          end: '23:00:00',
          replacement: true,
          originalDate: '2026-09-06',
        ),
        occurrence(seq: 3, date: '2026-09-13'),
        occurrence(seq: 4, date: '2026-09-20'),
      ],
    ))!;

    final moved = series.occurrences[1];

    expect(moved.isReplacement, isTrue);
    expect(moved.startAt, DateTime(2026, 9, 6, 22));
    expect(series.occurrences.length, 4, reason: 'a move never adds a row');
    // The original conflicting slot is not what gets shown.
    expect(moved.startTime, isNot('20:00:00'));
  });

  test('a differently priced replacement changes the total', () {
    final series = CreatedSeries.tryFrom(payload(
      total: 270,
      occurrences: [
        occurrence(seq: 1, date: '2026-08-30'),
        occurrence(seq: 2, date: '2026-09-06', price: 72, replacement: true),
        occurrence(seq: 3, date: '2026-09-13'),
        occurrence(seq: 4, date: '2026-09-20'),
      ],
    ))!;

    expect(series.totalAmount, 270);
    expect(series.hasUniformPrice, isFalse,
        reason: 'a "× 66" breakdown would be a lie here');
  });

  test('a uniform plan may show its per-appointment price', () {
    expect(CreatedSeries.tryFrom(payload())!.hasUniformPrice, isTrue);
  });

  group('the series payment summary', seriesPaymentSummary);
}


/// The series financial summary shown after a monthly booking is created.
///
/// Every figure is the server's. The screen used to report the first
/// appointment's price as the whole booking's amount.
void seriesPaymentSummary() {
  Map<String, dynamic> series({double total = 264, double paid = 0}) => {
        'series_id': 1,
        'occurrence_count': 4,
        'total_amount': total,
        'paid_amount': paid,
        'remaining_amount': total - paid,
        'payment_status': paid <= 0 ? 2 : (paid >= total ? 1 : 3),
        'price_per_occurrence': 66,
        'occurrences': const [],
      };

  test('unpaid shows the whole total outstanding', () {
    final s = CreatedSeries.tryFrom(series())!;

    expect(s.totalAmount, 264);
    expect(s.paidAmount, 0);
    expect(s.remainingAmount, 264);
    expect(s.paymentLabel, 'غير مدفوع');
  });

  test('a deposit shows what is left', () {
    final s = CreatedSeries.tryFrom(series(paid: 100))!;

    expect(s.paidAmount, 100);
    expect(s.remainingAmount, 164);
    expect(s.paymentLabel, 'مدفوع جزئي');
  });

  test('paid in full leaves nothing outstanding', () {
    final s = CreatedSeries.tryFrom(series(paid: 264))!;

    expect(s.paidAmount, 264);
    expect(s.remainingAmount, 0);
    expect(s.paymentLabel, 'خالص');
  });

  test('a replacement that raises the total is reflected', () {
    final s = CreatedSeries.tryFrom(series(total: 270, paid: 270))!;

    expect(s.totalAmount, 270);
    expect(s.paidAmount, 270);
    expect(s.remainingAmount, 0);
    // Never 66, and never 264.
    expect(s.totalAmount, isNot(66));
    expect(s.totalAmount, isNot(264));
  });
}
