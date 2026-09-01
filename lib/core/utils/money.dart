/// Money as a manager reads it on an invoice.
///
/// Amounts arrive as raw doubles, so a card was showing «66.0 د.ل» — a number
/// that looks like a rounding artefact rather than a price. One formatter, used
/// everywhere, so the same amount never appears two ways on one screen.
///
/// Whole amounts drop the decimals; anything else keeps exactly two, because
/// «66.5» reads as an error where «66.50» reads as money.
String formatMoney(double amount, {String currency = 'د.ل'}) {
  final value = _trim(amount);

  return currency.isEmpty ? value : '$value $currency';
}

/// The number alone, for places that label the currency separately.
String formatAmount(double amount) => _trim(amount);

String _trim(double amount) {
  // Guard against -0.0, which formats as "-0".
  final safe = amount == 0 ? 0.0 : amount;
  final isWhole = (safe - safe.roundToDouble()).abs() < 0.005;

  return isWhole ? safe.round().toString() : safe.toStringAsFixed(2);
}
