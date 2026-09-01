/// What a manager-created booking has actually been paid, derived from the
/// status they chose.
///
/// These two facts used to be able to disagree: the status was a pair of
/// buttons and the paid amount was a free-text field beside them, so a booking
/// could be marked «خالص» with 0 recorded, or «موافَق عليه» with the full
/// amount typed in. Neither is a thing that can be true.
///
/// The amount is therefore never stored — it is computed from the status and
/// the authoritative total every time it is needed, so no stale value can
/// survive a change of mind, however many times the manager switches.
enum PaymentSelection {
  /// «غير مدفوع» — approved, nothing collected yet.
  unpaid,

  /// «مدفوع جزئي» — the customer has paid some of it.
  partial,

  /// «خالص» — paid in full.
  paid;

  String get label => switch (this) {
        PaymentSelection.unpaid => 'غير مدفوع',
        PaymentSelection.partial => 'مدفوع جزئي',
        PaymentSelection.paid => 'خالص',
      };

  /// What this selection means in money, given the booking's total.
  ///
  /// A partial selection carries its own amount, because it is the only one
  /// the manager types; the other two are fully determined by the total.
  double amountFor(double total, {double entered = 0}) => switch (this) {
        PaymentSelection.unpaid => 0,
        PaymentSelection.paid => total > 0 ? total : 0,
        PaymentSelection.partial => entered.clamp(0, total > 0 ? total : 0),
      };

  /// The selection an amount implies — so a manager who types the full amount
  /// into the partial field is not left in a state that contradicts itself.
  static PaymentSelection forAmount(double paid, double total) {
    if (paid <= 0) return PaymentSelection.unpaid;
    if (total > 0 && paid >= total) return PaymentSelection.paid;
    return PaymentSelection.partial;
  }
}

class BookingPaymentStatus {
  /// «موافَق عليه» — confirmed, nothing collected yet.
  static const String approved = '2';

  /// «خالص» — the customer has paid in full, now.
  static const String paid = '4';

  /// The lifecycle status a manager-created booking always has.
  ///
  /// It is Approved whether the booking is unpaid, part paid or paid in full.
  /// «خالص» used to be sent as `ServiceStatus::Done`, which says the match was
  /// played — and triggers completion, settlement, coins and attendance for a
  /// session nobody has turned up to yet. Money lives in `paid_amount` and
  /// `payment_status`; this field never speaks about it.
  static const String lifecycleApproved = approved;

  /// The only two the manager booking flow offers.
  static const List<String> options = [approved, paid];

  static bool isValid(String? status) => options.contains(status);

  /// The paid amount implied by a status.
  ///
  /// `total` is the server's price for what is actually being booked — one
  /// occurrence for a single booking, the resolved plan's total for a monthly
  /// one, including any appointment the manager moved into a differently
  /// priced band. Nothing here derives a price of its own.
  static double paidAmountFor({
    required String? status,
    required double total,
  }) {
    if (status != paid) return 0;
    // A negative or absent total would otherwise be recorded as a payment.
    return total > 0 ? total : 0;
  }

  /// Formatted for the payload, which expects a plain numeric string.
  static String paidAmountStringFor({
    required String? status,
    required double total,
  }) {
    final amount = paidAmountFor(status: status, total: total);
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }
}
