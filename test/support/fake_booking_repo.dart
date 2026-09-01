import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/booking/data/model/series_preview.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';

/// A stand-in for the network, recording what the cubit asked for.
///
/// Only `previewSeries` is implemented: everything else throws, so a test that
/// accidentally exercises another path fails loudly instead of passing on a
/// silent default.
class FakeBookingRepo implements BookingRepo {
  Either<Failure, SeriesPreview> previewResult =
      Right(FakeBookingRepo.cleanPreview());

  int previewCalls = 0;
  Map<String, dynamic>? lastPreviewArgs;

  /// Lets a test observe the in-flight state.
  bool hold = false;
  Completer<void>? _gate;

  void release() {
    _gate?.complete();
    _gate = null;
    hold = false;
  }

  @override
  Future<Either<Failure, SeriesPreview>> previewSeries({
    required int branchId,
    required int employeeId,
    required int serviceId,
    required String date,
    required String startTime,
    required String endTime,
    String? startAt,
    String? endAt,
    int? customerId,
    bool strictPositions = false,
    List<Map<String, dynamic>> replacements = const [],
  }) async {
    previewCalls++;
    lastPreviewArgs = {
      'branch_id': branchId,
      'employee_id': employeeId,
      'service_id': serviceId,
      'service_date': date,
      'start_time': startTime,
      'end_time': endTime,
      'start_at': startAt,
      'end_at': endAt,
      'customer_id': customerId,
      'strict_positions': strictPositions,
      'replacements': replacements,
    };

    if (hold) {
      _gate = Completer<void>();
      await _gate!.future;
    }

    return previewResult;
  }

  // ---------- fixtures ----------

  static Map<String, dynamic> _row({
    required int sequence,
    required String date,
    required String start,
    required String end,
    bool available = true,
    bool canReplace = false,
    bool isReplacement = false,
    String? originalDate,
    List<Map<String, dynamic>> sameDay = const [],
  }) {
    return {
      'sequence': sequence,
      'date': date,
      'start_time': start,
      'end_time': end,
      'start_at': '$date $start',
      'end_at': '$date $end',
      'employee_id': 11,
      'price': 66,
      'available': available,
      'action': available ? 'book' : 'block',
      'can_replace': canReplace,
      'is_replacement': isReplacement,
      'original_date': originalDate,
      'replacement_options': canReplace
          ? {
              'same_day': sameDay,
              'nearby_days': const [],
              'window_days': 2,
              'enabled': true,
            }
          : null,
    };
  }

  static SeriesPreview _preview(List<Map<String, dynamic>> rows) {
    return SeriesPreview.fromJson({
      'dates': rows,
      'all_available': rows.every((r) => r['available'] == true),
      'satisfiable': true,
      'plan_signature': 'sig-1',
      'target_occurrence_count': 4,
      'price_per_occurrence': 66,
      'total_amount': 264,
      'resolved_total_amount': 264,
      'final_occurrence_count': rows.length,
      'replacement_enabled': true,
    });
  }

  /// Four free Sundays.
  static SeriesPreview cleanPreview() => _preview([
        _row(sequence: 1, date: '2026-08-30', start: '18:00:00', end: '19:00:00'),
        _row(sequence: 2, date: '2026-09-06', start: '18:00:00', end: '19:00:00'),
        _row(sequence: 3, date: '2026-09-13', start: '18:00:00', end: '19:00:00'),
        _row(sequence: 4, date: '2026-09-20', start: '18:00:00', end: '19:00:00'),
      ]);

  /// Week two is taken, with 19:00 free that evening.
  static SeriesPreview conflictPreview() => _preview([
        _row(sequence: 1, date: '2026-08-30', start: '18:00:00', end: '19:00:00'),
        _row(
          sequence: 2,
          date: '2026-09-06',
          start: '18:00:00',
          end: '19:00:00',
          available: false,
          canReplace: true,
          sameDay: [
            {
              'date': '2026-09-06',
              'start_time': '19:00:00',
              'end_time': '20:00:00',
              'start_at': '2026-09-06 19:00:00',
              'end_at': '2026-09-06 20:00:00',
              'employee_id': 11,
              'price': 66,
              'same_day': true,
              'day_distance': 0,
            }
          ],
        ),
        _row(sequence: 3, date: '2026-09-13', start: '18:00:00', end: '19:00:00'),
        _row(sequence: 4, date: '2026-09-20', start: '18:00:00', end: '19:00:00'),
      ]);

  /// The server's answer once the move has been applied: still four rows, with
  /// week two now at 19:00 and badged as a replacement.
  static SeriesPreview resolvedPreview() => _preview([
        _row(sequence: 1, date: '2026-08-30', start: '18:00:00', end: '19:00:00'),
        _row(
          sequence: 2,
          date: '2026-09-06',
          start: '19:00:00',
          end: '20:00:00',
          isReplacement: true,
          originalDate: '2026-09-06',
        ),
        _row(sequence: 3, date: '2026-09-13', start: '18:00:00', end: '19:00:00'),
        _row(sequence: 4, date: '2026-09-20', start: '18:00:00', end: '19:00:00'),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        'FakeBookingRepo only implements previewSeries; '
        '${invocation.memberName} was called unexpectedly.',
      );
}
