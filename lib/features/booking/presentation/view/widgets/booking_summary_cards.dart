import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_details.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/venue_block_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// PaymentType::LocalPayment — the same id the backend itself treats as
/// "collected by the venue" (see `pay_on_arrival` in BookingRepository and
/// MonthlyBookingController, computed the same way). Paypal, Stripe and
/// wallet/UserBalance payments are platform-controlled and never venue money,
/// regardless of what `payment_status` currently shows.
const _localPaymentTypeId = 1;

/// Whether this booking's outstanding balance, if any, is money the venue
/// itself is owed — as opposed to money Goal Master already holds or has
/// processed online.
bool isVenueCollectedBooking(BookingDetails booking) =>
    booking.paymentTypeId == _localPaymentTypeId;

double remainingAmount(BookingDetails booking) {
  final total = double.tryParse(booking.serviceAmount) ?? 0;
  final paid = double.tryParse(booking.paidAmount) ?? 0;
  final remaining = total - paid;
  return remaining > 0 ? remaining : 0;
}

String formatMoney(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);

/// A real display name — Arabic text or anything with a space — as opposed
/// to a bare login-style handle like "ayoubbelhaj". A booking whose stored
/// name doesn't look like one falls back to a generic greeting rather than
/// exposing it in a customer-facing message.
bool _looksLikeDisplayName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return false;

  final hasArabic = RegExp(r'[؀-ۿ]').hasMatch(trimmed);
  return hasArabic || trimmed.contains(' ');
}

String? _greetingName(BookingDetails booking) {
  final name = booking.customerName;
  if (name == null || !_looksLikeDisplayName(name)) return null;
  return name;
}

DateTime _combineDateAndTime(DateTime date, String hhmmss) {
  final parts = hhmmss.split(':');
  return DateTime(
    date.year,
    date.month,
    date.day,
    int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0,
    int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
  );
}

/// "الأحد، 13 سبتمبر 2026"
String bookingDateLine(BookingDetails booking) {
  final iso = booking.date.toIso8601String();
  return '${arabicWeekday(iso)}، ${arabicDateWithYear(iso)}';
}

/// "من 8:00 م إلى 9:00 م" — short م/ص, not the English AM/PM the raw
/// "HH:mm:ss" strings would otherwise render as.
String bookingTimeLine(BookingDetails booking) {
  final start = _combineDateAndTime(booking.date, booking.startTime);
  final end = _combineDateAndTime(booking.date, booking.endTime);
  return 'من ${arabicSlotClock(start)} إلى ${arabicSlotClock(end)}';
}

/// "Local Payment" etc. as the API stores it → what a manager should read.
const _paymentMethodNames = {
  'Local Payment': 'نقدي',
  'Cash': 'نقدي',
  'Paypal': 'بايبال',
  'Stripe': 'سترايب',
  'User Balance': 'رصيد المحفظة',
};

String friendlyPaymentMethod(String raw) =>
    _paymentMethodNames[raw.trim()] ?? raw;

/// A Libyan number in any common shape → the digits-only form WhatsApp's
/// `wa.me` link expects (country code, no leading `0`, no `+`/`00`).
///
/// Returns null when what's left after cleanup is too short to be a real
/// number, so a bad value hides the action instead of opening WhatsApp to a
/// broken chat.
String? normalizeLibyanPhoneForWhatsApp(String? raw) {
  if (raw == null) return null;

  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;

  if (digits.startsWith('00218')) {
    digits = digits.substring(2);
  } else if (digits.startsWith('218')) {
    // already has the country code
  } else if (digits.startsWith('0')) {
    digits = '218${digits.substring(1)}';
  } else {
    digits = '218$digits';
  }

  // 218 + a 9-digit local number is the shortest real Libyan mobile/landline.
  if (digits.length < 12) return null;

  return digits;
}

Future<void> _launchWhatsAppWithMessage(String phone, String message) async {
  final encoded = Uri.encodeComponent(message);
  final appUri = Uri.parse('https://wa.me/$phone?text=$encoded');

  if (await canLaunchUrl(appUri)) {
    await launchUrl(appUri, mode: LaunchMode.externalApplication);
    return;
  }

  await launchUrl(
    Uri.parse('https://web.whatsapp.com/send?phone=$phone&text=$encoded'),
    mode: LaunchMode.externalApplication,
  );
}

/// The three cards on the booking-details screen: when, who, and money.
///
/// Presentation only — every value here already exists on [BookingDetails];
/// nothing is fetched or computed beyond formatting.
const _cardBorder = Color(0xffE8ECEF);
const _cardFill = Color(0xffFAFBFC);

Widget _card({required String title, required Widget child}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(14.r),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.font16Bold),
        HeightSpace(12.h),
        child,
      ],
    ),
  );
}

Widget _iconRow(IconData icon, Widget content) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18.sp, color: AppColors.primary),
      WidthSpace(8.w),
      Expanded(child: content),
    ],
  );
}

/// "موعد الحجز" — date, one clear time row, service, with a small outlined
/// reschedule action beside the time.
class BookingTimeCard extends StatelessWidget {
  const BookingTimeCard({
    super.key,
    required this.booking,
    this.onEditTime,
  });

  final BookingDetails booking;

  /// Null hides the action — the caller already decides whether this booking
  /// can still be moved (elapsed / cancelled / done sessions cannot).
  final VoidCallback? onEditTime;

  @override
  Widget build(BuildContext context) {
    return _card(
      title: 'موعد الحجز',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconRow(
            Icons.calendar_month_rounded,
            Text(bookingDateLine(booking), style: AppTextStyles.font14Bold),
          ),
          HeightSpace(10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.schedule_rounded, size: 18.sp, color: AppColors.primary),
              WidthSpace(8.w),
              Expanded(
                child: Text(
                  bookingTimeLine(booking),
                  style: AppTextStyles.font14Bold,
                ),
              ),
              if (onEditTime != null)
                OutlinedButton.icon(
                  onPressed: onEditTime,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  icon: Icon(Icons.edit_calendar_rounded, size: 15.sp),
                  label: Text('تعديل الموعد', style: AppTextStyles.font12Bold),
                ),
            ],
          ),
          HeightSpace(10.h),
          _iconRow(
            Icons.sports_soccer_rounded,
            Text(booking.service, style: AppTextStyles.font14Medium),
          ),
        ],
      ),
    );
  }
}

/// "العميل" — only what the current model already carries.
class BookingCustomerCard extends StatefulWidget {
  const BookingCustomerCard({super.key, required this.booking, this.onChanged});

  final BookingDetails booking;

  /// Called after a block/unblock is recorded, so the caller can reload the
  /// booking and pick up the fresh state.
  final VoidCallback? onChanged;

  @override
  State<BookingCustomerCard> createState() => _BookingCustomerCardState();
}

class _BookingCustomerCardState extends State<BookingCustomerCard> {
  bool _submitting = false;

  BookingDetails get booking => widget.booking;

  @override
  Widget build(BuildContext context) {
    return _card(
      title: 'العميل',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (booking.customerName != null) ...[
            _iconRow(
              Icons.person_outline_rounded,
              Text(booking.customerName!, style: AppTextStyles.font14Bold),
            ),
            HeightSpace(10.h),
          ],
          _iconRow(
            Icons.badge_outlined,
            Text(
              'رقم العميل: ${booking.cmnCustomerId}',
              style: AppTextStyles.font14Medium,
            ),
          ),
          if (booking.customerPhone != null) ...[
            HeightSpace(10.h),
            _iconRow(
              Icons.phone_outlined,
              Text(
                booking.customerPhone!,
                textDirection: TextDirection.ltr,
                style: AppTextStyles.font14Medium,
              ),
            ),
          ],
          // "ننتظرك في الموعد" makes no sense once the slot has already
          // passed — the same [hasElapsed] authority the reschedule action
          // uses, not a separate date rule.
          if (_whatsAppPhone != null && !booking.hasElapsed) ...[
            HeightSpace(12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _launchWhatsAppWithMessage(
                  _whatsAppPhone!,
                  _message(),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: BorderSide(color: AppColors.success),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 17.sp),
                label: Text('واتساب العميل', style: AppTextStyles.font14Bold),
              ),
            ),
          ],
          HeightSpace(12.h),
          _blockSection(),
        ],
      ),
    );
  }

  Widget _blockSection() {
    if (booking.isBlockedByVenue) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AppColors.dangerLight1,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block_rounded, size: 16.sp, color: AppColors.redcolor),
                WidthSpace(6.w),
                Expanded(
                  child: Text(
                    'الزبون محظور من الحجز'
                    '${booking.venueBlockReasonLabel != null ? ' — ${booking.venueBlockReasonLabel}' : ''}',
                    style: AppTextStyles.font12Bold.copyWith(color: AppColors.redcolor),
                  ),
                ),
              ],
            ),
            HeightSpace(8.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _submitting ? null : _confirmUnblock,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('إلغاء الحظر', style: AppTextStyles.font12Bold),
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _submitting ? null : _openBlockSheet,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.redcolor,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(Icons.block_rounded, size: 15.sp),
        label: Text('حظر الزبون', style: AppTextStyles.font12Bold),
      ),
    );
  }

  Future<void> _openBlockSheet() async {
    final decision = await VenueBlockSheet.show(context);
    if (decision == null || !mounted) return;

    setState(() => _submitting = true);
    final repo = GetIt.instance<BookingRepoImp>();
    final result = await repo.blockCustomerFromVenue(
      customerId: booking.cmnCustomerId,
      branchId: booking.branchId,
      reasonCode: decision.reasonCode,
      note: decision.note,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      (failure) => showCustomFailureToast(failure.errMessage),
      (message) {
        showCustomSuccessToast(message);
        widget.onChanged?.call();
      },
    );
  }

  Future<void> _confirmUnblock() async {
    final confirmed = await VenueUnblockConfirmSheet.show(context);
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    final repo = GetIt.instance<BookingRepoImp>();
    final result = await repo.unblockCustomerFromVenue(
      customerId: booking.cmnCustomerId,
      branchId: booking.branchId,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      (failure) => showCustomFailureToast(failure.errMessage),
      (message) {
        showCustomSuccessToast(message);
        widget.onChanged?.call();
      },
    );
  }

  String? get _whatsAppPhone =>
      normalizeLibyanPhoneForWhatsApp(booking.customerPhone);

  String _message() {
    final name = _greetingName(booking);
    final greeting = 'السلام عليكم${name != null ? ' $name' : ''} 👋⚽';

    return '''
$greeting

هذه تفاصيل حجزك في ${booking.branch} 🏟️

🎫 رقم الحجز: #${booking.id}
📅 التاريخ: ${bookingDateLine(booking)}
🕗 موعد اللعب: ${bookingTimeLine(booking)}
⚽ الملعب: ${booking.service}
💰 القيمة: ${booking.serviceAmount} د.ل
💳 حالة الدفع: ${booking.paymentName}
💵 طريقة الدفع: ${friendlyPaymentMethod(booking.paymentType)}

ننتظرك في الموعد 🤝⚽
وشكرًا لاختيارك ${booking.branch} 💚''';
  }
}

/// "الدفع" — total amount and status made visually obvious; the raw payment
/// method name is mapped to Arabic where a known mapping exists rather than
/// showing e.g. "Local Payment" as-is.
///
/// While an open no-show dispute sits on this booking, the debt-reminder
/// action is replaced by a neutral one — WhatsApp is communication only, and
/// nothing said there should read as though a contested amount were already
/// settled fact. The manager may also propose an agreed result here, but that
/// proposal never closes the dispute by itself.
class BookingPaymentCard extends StatefulWidget {
  const BookingPaymentCard({super.key, required this.booking, this.onProposed});

  final BookingDetails booking;

  /// Called after a proposal is recorded, so the caller can reload the
  /// booking and pick up the fresh dispute state.
  final VoidCallback? onProposed;

  @override
  State<BookingPaymentCard> createState() => _BookingPaymentCardState();
}

class _BookingPaymentCardState extends State<BookingPaymentCard> {
  bool _submitting = false;

  BookingDetails get booking => widget.booking;

  String get _method => friendlyPaymentMethod(booking.paymentType);

  /// Paid to Goal Master online/through the wallet — money the platform
  /// already holds, not something the customer still owes anyone. Distinct
  /// from `payment_status`, which on this booking can (rarely, from older
  /// data) still read unpaid/partial even though the charge already went
  /// through; that field describes venue settlement, not customer debt, once
  /// the payment isn't venue-collected in the first place.
  bool get _isPlatformPrepaid => !isVenueCollectedBooking(booking);

  /// The pill text, from the customer's point of view. A platform-prepaid
  /// booking is always shown as paid regardless of what `payment_status`
  /// says — that field is about venue settlement, a different concept the
  /// current API does not separately expose, so no secondary settlement
  /// badge is shown either.
  String get _statusLabel =>
      _isPlatformPrepaid ? 'مدفوع عبر Goal Master' : booking.paymentName;

  (Color, Color) get _statusColors {
    if (_isPlatformPrepaid) return (AppColors.lightSuccess, AppColors.success);

    return switch (booking.paymentStatus) {
      1 => (AppColors.lightSuccess, AppColors.success),
      3 => (const Color(0xFFFFF4E5), const Color(0xFFB26A00)),
      _ => (AppColors.dangerLight1, AppColors.redcolor),
    };
  }

  /// A reminder only makes sense for money the venue itself is chasing, and
  /// only while there is actually something left to chase. It must NOT
  /// appear just because `payment_status` reads unpaid — a Goal Master
  /// wallet/online payment can sit in that state too, and that money is not
  /// the venue's to remind anyone about.
  bool get _reminderEligible =>
      isVenueCollectedBooking(booking) &&
      booking.status != 3 && // cancelled — nothing to collect
      remainingAmount(booking) > 0;

  String? get _whatsAppPhone =>
      normalizeLibyanPhoneForWhatsApp(booking.customerPhone);

  String _reminderMessage() {
    final name = _greetingName(booking);
    final greeting = 'السلام عليكم${name != null ? ' $name' : ''} 👋';
    final paid = double.tryParse(booking.paidAmount) ?? 0;
    final remaining = remainingAmount(booking);

    return '''
$greeting

نود تذكيرك بوجود مبلغ متبقي على حجزك في ${booking.branch} 🏟️

🎫 رقم الحجز: #${booking.id}
📅 التاريخ: ${bookingDateLine(booking)}
🕗 موعد اللعب: ${bookingTimeLine(booking)}
⚽ الملعب: ${booking.service}

💰 قيمة الحجز: ${booking.serviceAmount} د.ل
💳 المدفوع: ${formatMoney(paid)} د.ل
🔴 المبلغ المتبقي: ${formatMoney(remaining)} د.ل

نرجو منك تسوية المبلغ المتبقي، وشكرًا لك 🤝💚''';
  }

  /// Communication only, while the dispute is still open — never claims the
  /// remaining amount as an established debt, and never accuses either side.
  String _clarifyMessage() {
    final name = _greetingName(booking);
    final greeting = 'السلام عليكم${name != null ? ' $name' : ''} 👋';

    return '''
$greeting

بخصوص حجزك في ${booking.branch} 🏟️

🎫 رقم الحجز: #${booking.id}
📅 التاريخ: ${bookingDateLine(booking)}
🕗 موعد اللعب: ${bookingTimeLine(booking)}
⚽ الملعب: ${booking.service}
💰 المبلغ المتبقي المسجّل: ${formatMoney(remainingAmount(booking))} د.ل

تم تسجيل الحجز من إدارة الملعب على أنك لم تحضر، بينما أكدتَ أنك حضرت إلى الموعد.

نرجو التواصل معنا لتوضيح الأمر وتسوية حالة الحجز والمبلغ المتبقي 🤝

وشكرًا لك 💚''';
  }

  static const _proposalLabels = {
    'attended': 'تم الاتفاق أن الزبون حضر',
    'no_show': 'تم الاتفاق أن الزبون لم يحضر',
  };

  Future<void> _propose(String result) async {
    setState(() => _submitting = true);

    final repo = GetIt.instance<BookingRepoImp>();
    final res = await repo.proposeNoShowResolution(
      bookingId: booking.id,
      result: result,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    res.fold(
      (failure) => showCustomFailureToast(failure.errMessage),
      (message) {
        showCustomSuccessToast(message);
        widget.onProposed?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors;

    return _card(
      title: 'الدفع',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${booking.serviceAmount} د.ل',
                style: AppTextStyles.font24Bold,
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  _statusLabel,
                  style: AppTextStyles.font12Bold.copyWith(color: fg),
                ),
              ),
            ],
          ),
          if (!_isPlatformPrepaid &&
              booking.paymentStatus != 2 &&
              booking.paidAmount.isNotEmpty &&
              booking.paidAmount != '0' &&
              booking.paidAmount != booking.serviceAmount) ...[
            HeightSpace(6.h),
            Text(
              'المدفوع: ${booking.paidAmount} د.ل',
              style: AppTextStyles.font12Regular.copyWith(color: AppColors.fontColor),
            ),
          ],
          HeightSpace(12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _cardFill,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: _iconRow(
              Icons.payments_outlined,
              Text('طريقة الدفع: $_method', style: AppTextStyles.font14Medium),
            ),
          ),
          if (_reminderEligible && _whatsAppPhone != null) ...[
            HeightSpace(10.h),
            Align(
              alignment: Alignment.centerLeft,
              child: booking.hasOpenNoShowDispute
                  ? TextButton.icon(
                      onPressed: () => _launchWhatsAppWithMessage(
                        _whatsAppPhone!,
                        _clarifyMessage(),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.dark2,
                        padding:
                            EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(Icons.forum_outlined, size: 15.sp),
                      label: Text(
                        'توضيح حالة الحجز',
                        style: AppTextStyles.font12Bold,
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () => _launchWhatsAppWithMessage(
                        _whatsAppPhone!,
                        _reminderMessage(),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB26A00),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(Icons.notifications_active_outlined, size: 15.sp),
                      label: Text(
                        'تذكير بالمبلغ المتبقي',
                        style: AppTextStyles.font12Bold,
                      ),
                    ),
            ),
          ],
          if (booking.hasOpenNoShowDispute) ...[
            HeightSpace(10.h),
            _disputeProposalSection(),
          ],
        ],
      ),
    );
  }

  Widget _disputeProposalSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.dark2.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.dark2.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconRow(
            Icons.info_outline_rounded,
            Text(
              'هناك نزاع مفتوح حول الحضور — لم يُحسم بعد.',
              style: AppTextStyles.font12Bold.copyWith(color: AppColors.dark2),
            ),
          ),
          if (booking.noShowDisputeManagerProposal != null) ...[
            HeightSpace(6.h),
            Text(
              'اقتراحك الحالي: '
              '${_proposalLabels[booking.noShowDisputeManagerProposal] ?? booking.noShowDisputeManagerProposal} '
              '— بانتظار تأكيد الزبون. هذا لا يُغلق النزاع.',
              style: AppTextStyles.font12Regular.copyWith(color: AppColors.fontColor),
            ),
          ],
          HeightSpace(8.h),
          Text('اقترح نتيجة متفق عليها:', style: AppTextStyles.font12Bold),
          HeightSpace(8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _proposalChip('تم الاتفاق أن الزبون حضر', 'attended', AppColors.primary),
              _proposalChip(
                  'تم الاتفاق أن الزبون لم يحضر', 'no_show', AppColors.primary),
              _proposalChip('ما زال هناك خلاف', 'disagreement', AppColors.redcolor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _proposalChip(String label, String result, Color color) {
    return OutlinedButton(
      onPressed: _submitting ? null : () => _propose(result),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
      child: Text(label, style: AppTextStyles.font12Bold),
    );
  }
}
