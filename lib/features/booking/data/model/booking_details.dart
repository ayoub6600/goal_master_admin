class BookingDetails {
  final int id;
  final int cmnCustomerId;
  final String? customerName;
  final String? customerPhone;
  final int branchId;
  final String branch;
  final String address;
  final String latitude;
  final String longitude;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int employeeId;
  final int serviceId;
  final String service;
  final String serviceAmount;
  final String paidAmount;
  final int paymentStatus;
  final String paymentName;
  final int paymentTypeId;
  final String paymentType;
  final int status;
  final String statusName;
  final String? remarks;
  final String category;

  /// Authoritative — from `BookingDispute`, never inferred from the
  /// historical attendance_status/customer_confirmation pair, which stay
  /// frozen at their reported values even after a dispute is resolved.
  final bool hasOpenNoShowDispute;

  /// The manager's live proposal on that open dispute, if one exists —
  /// 'attended' | 'no_show' | null. Cleared once the manager flags
  /// continued disagreement, so a stale round is never mistaken for current.
  final String? noShowDisputeManagerProposal;

  /// This venue's own decision, never a Goal Master ban. Existing bookings
  /// (this one included) are unaffected by it either way.
  final bool isBlockedByVenue;
  final String? venueBlockReasonLabel;

  const BookingDetails({
    required this.id,
    required this.cmnCustomerId,
    this.customerName,
    this.customerPhone,
    required this.branchId,
    required this.branch,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.employeeId,
    required this.serviceId,
    required this.service,
    required this.serviceAmount,
    required this.paidAmount,
    required this.paymentStatus,
    required this.paymentName,
    required this.paymentTypeId,
    required this.paymentType,
    required this.status,
    required this.statusName,
    this.remarks,
    required this.category,
    this.hasOpenNoShowDispute = false,
    this.noShowDisputeManagerProposal,
    this.isBlockedByVenue = false,
    this.venueBlockReasonLabel,
  });

  factory BookingDetails.fromJson(Map<String, dynamic> json) {
    return BookingDetails(
      id: _asInt(json['id']),
      cmnCustomerId: _asInt(json['cmn_customer_id']),
      // Only present on endpoints that already join the customer; left null
      // rather than defaulted so the UI can tell "not returned" from "empty".
      customerName: (json['customer_name'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['customer_name'] as String,
      customerPhone:
          (json['phone_number'] as String?)?.trim().isEmpty ?? true
              ? null
              : json['phone_number'] as String,
      branchId: _asInt(json['cmn_branch_id']),
      branch: _asString(json['branch']),
      address: _asString(json['address']),
      latitude: _asString(json['latitude']),
      longitude: _asString(json['longitude']),
      date: DateTime.parse(_asString(json['date'])),
      startTime: _asString(json['start_time']),
      endTime: _asString(json['end_time']),
      employeeId: _asInt(json['sch_employee_id']),
      serviceId: _asInt(json['sch_service_id']),
      service: _asString(json['service']),
      serviceAmount: _asString(json['service_amount']),
      paidAmount: _asString(json['paid_amount']),
      paymentStatus: _asInt(json['payment_status']),
      paymentName: _asString(json['payment_name']),
      paymentTypeId: _asInt(json['cmn_payment_type_id']),
      paymentType: _asString(json['payment_type']),
      status: _asInt(json['status']),
      statusName: _asString(json['status_name']),
      remarks: json['remarks']?.toString(),
      category: _asString(json['category']),
      hasOpenNoShowDispute: json['has_open_no_show_dispute'] == true,
      noShowDisputeManagerProposal:
          (json['no_show_dispute_manager_proposal'] as String?)?.trim().isEmpty ??
                  true
              ? null
              : json['no_show_dispute_manager_proposal'] as String,
      isBlockedByVenue: json['is_blocked_by_venue'] == true,
      venueBlockReasonLabel:
          (json['venue_block_reason_label'] as String?)?.trim().isEmpty ?? true
              ? null
              : json['venue_block_reason_label'] as String,
    );
  }

  /// The session's end time has already passed.
  ///
  /// A played session does not flip to status Done on its own — that needs an
  /// explicit attendance mark — so a booking can still read Approved long
  /// after it happened. Offering to edit or reschedule it at that point makes
  /// no sense regardless of what the status field says.
  bool get hasElapsed {
    final parts = endTime.split(':');
    if (parts.length < 2) return false;

    final end = DateTime(
      date.year,
      date.month,
      date.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
    );
    return end.isBefore(DateTime.now());
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _asString(dynamic value) {
    return value?.toString() ?? '';
  }
}
