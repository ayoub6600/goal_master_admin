import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_details.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/booking_summary_cards.dart';

BookingDetails _booking({
  required int paymentTypeId,
  required int paymentStatus,
  required String paidAmount,
  required String serviceAmount,
  int status = 2,
  String startTime = '20:00:00',
  String endTime = '21:00:00',
  bool hasOpenNoShowDispute = false,
  String? noShowDisputeManagerProposal,
  bool isBlockedByVenue = false,
  String? venueBlockReasonLabel,
}) =>
    BookingDetails(
      id: 100026,
      cmnCustomerId: 58,
      customerName: 'أيوب بالحاج',
      customerPhone: '0911234567',
      branchId: 1,
      branch: 'ملاعب الجدار',
      address: 'مصراتة',
      latitude: '0',
      longitude: '0',
      date: DateTime(2026, 9, 13),
      startTime: startTime,
      endTime: endTime,
      employeeId: 1,
      serviceId: 1,
      service: 'سداسي 1',
      serviceAmount: serviceAmount,
      paidAmount: paidAmount,
      paymentStatus: paymentStatus,
      paymentName: paymentStatus == 1 ? 'مدفوع' : 'غير مدفوع',
      paymentTypeId: paymentTypeId,
      paymentType: paymentTypeId == 1 ? 'Local Payment' : 'User Balance',
      status: status,
      statusName: 'موافق عليه',
      category: 'كرة قدم',
      hasOpenNoShowDispute: hasOpenNoShowDispute,
      noShowDisputeManagerProposal: noShowDisputeManagerProposal,
      isBlockedByVenue: isBlockedByVenue,
      venueBlockReasonLabel: venueBlockReasonLabel,
    );

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

void main() {
  group('bookingTimeLine — short Arabic م/ص', () {
    test('evening slot', () {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 2,
        paidAmount: '0',
        serviceAmount: '66',
      );
      expect(bookingTimeLine(booking), 'من 8:00 م إلى 9:00 م');
    });

    test('morning slot', () {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 2,
        paidAmount: '0',
        serviceAmount: '66',
        startTime: '08:00:00',
        endTime: '09:00:00',
      );
      expect(bookingTimeLine(booking), 'من 8:00 ص إلى 9:00 ص');
    });
  });

  test('bookingDateLine includes the weekday, comma, and year', () {
    final booking = _booking(
      paymentTypeId: 1,
      paymentStatus: 2,
      paidAmount: '0',
      serviceAmount: '66',
    );
    expect(bookingDateLine(booking), 'الأحد، 13 سبتمبر 2026');
  });

  group('payment reminder eligibility', () {
    const reminderText = 'تذكير بالمبلغ المتبقي';

    testWidgets('Manager-created / local payment, fully unpaid → visible',
        (tester) async {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 2,
        paidAmount: '0',
        serviceAmount: '66',
      );
      await _pump(tester, BookingPaymentCard(booking: booking));
      expect(find.text(reminderText), findsOneWidget);
    });

    testWidgets('local payment, partially paid → visible', (tester) async {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 3,
        paidAmount: '30',
        serviceAmount: '66',
      );
      await _pump(tester, BookingPaymentCard(booking: booking));
      expect(find.text(reminderText), findsOneWidget);
    });

    testWidgets(
        'wallet/prepaid booking that looks unpaid → hidden (never a venue debt)',
        (tester) async {
      final booking = _booking(
        paymentTypeId: 4, // PaymentType::UserBalance
        paymentStatus: 2,
        paidAmount: '0',
        serviceAmount: '66',
      );
      await _pump(tester, BookingPaymentCard(booking: booking));
      expect(find.text(reminderText), findsNothing);
    });

    testWidgets('fully paid, local payment → hidden', (tester) async {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 1,
        paidAmount: '66',
        serviceAmount: '66',
      );
      await _pump(tester, BookingPaymentCard(booking: booking));
      expect(find.text(reminderText), findsNothing);
    });

    testWidgets('cancelled booking with an unpaid balance → hidden',
        (tester) async {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 2,
        paidAmount: '0',
        serviceAmount: '66',
        status: 3,
      );
      await _pump(tester, BookingPaymentCard(booking: booking));
      expect(find.text(reminderText), findsNothing);
    });
  });

  group('platform-prepaid payment display', () {
    testWidgets(
        'wallet booking shows "paid via Goal Master" even when payment_status still reads unpaid',
        (tester) async {
      final booking = _booking(
        paymentTypeId: 4, // PaymentType::UserBalance
        paymentStatus: 2, // stale/legacy "unpaid" — must not surface as debt
        paidAmount: '0',
        serviceAmount: '66',
      );
      await _pump(tester, BookingPaymentCard(booking: booking));
      expect(find.text('مدفوع عبر Goal Master'), findsOneWidget);
      expect(find.text('غير مدفوع'), findsNothing);
      // No "المدفوع: ..." secondary debt-shaped line either.
      expect(find.textContaining('المدفوع:'), findsNothing);
    });

    testWidgets('venue-collected booking keeps the raw payment_status label',
        (tester) async {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 2,
        paidAmount: '0',
        serviceAmount: '66',
      );
      await _pump(tester, BookingPaymentCard(booking: booking));
      expect(find.text('غير مدفوع'), findsOneWidget);
      expect(find.text('مدفوع عبر Goal Master'), findsNothing);
    });
  });

  group('normal "واتساب العميل" visibility', () {
    const whatsAppText = 'واتساب العميل';

    testWidgets('future booking with a valid phone → visible',
        (tester) async {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 2,
        paidAmount: '0',
        serviceAmount: '66',
      ); // date is 2026-09-13, ahead of "now" in this test run
      await _pump(tester, BookingCustomerCard(booking: booking));
      expect(find.text(whatsAppText), findsOneWidget);
    });

    testWidgets('ended booking → hidden regardless of payment type',
        (tester) async {
      final booking = BookingDetails(
        id: 100010,
        cmnCustomerId: 58,
        customerName: 'أيوب بالحاج',
        customerPhone: '0911234567',
        branchId: 1,
        branch: 'ملاعب الجدار',
        address: 'مصراتة',
        latitude: '0',
        longitude: '0',
        date: DateTime(2020, 1, 1),
        startTime: '20:00:00',
        endTime: '21:00:00',
        employeeId: 1,
        serviceId: 1,
        service: 'سداسي 1',
        serviceAmount: '66',
        paidAmount: '66',
        paymentStatus: 1,
        paymentName: 'مدفوع',
        paymentTypeId: 4,
        paymentType: 'User Balance',
        status: 4,
        statusName: 'تم',
        category: 'كرة قدم',
      );

      expect(booking.hasElapsed, isTrue);
      await _pump(tester, BookingCustomerCard(booking: booking));
      expect(find.text(whatsAppText), findsNothing);
    });
  });

  testWidgets(
      'ended + wallet booking: paid via Goal Master, no normal WhatsApp, no reminder',
      (tester) async {
    final booking = BookingDetails(
      id: 100010,
      cmnCustomerId: 58,
      customerName: 'أيوب بالحاج',
      customerPhone: '0911234567',
      branchId: 1,
      branch: 'ملاعب الجدار',
      address: 'مصراتة',
      latitude: '0',
      longitude: '0',
      date: DateTime(2020, 1, 1),
      startTime: '20:00:00',
      endTime: '21:00:00',
      employeeId: 1,
      serviceId: 1,
      service: 'سداسي 1',
      serviceAmount: '66',
      paidAmount: '66',
      paymentStatus: 1,
      paymentName: 'مدفوع',
      paymentTypeId: 4,
      paymentType: 'User Balance',
      status: 4,
      statusName: 'تم',
      category: 'كرة قدم',
    );

    await _pump(
      tester,
      Column(
        children: [
          BookingCustomerCard(booking: booking),
          BookingPaymentCard(booking: booking),
        ],
      ),
    );

    expect(find.text('مدفوع عبر Goal Master'), findsOneWidget);
    expect(find.text('واتساب العميل'), findsNothing);
    expect(find.text('تذكير بالمبلغ المتبقي'), findsNothing);
  });

  group('WhatsApp/payment action switches only while a no-show dispute is open',
      () {
    testWidgets('no open dispute → normal reminder wording, no proposal box',
        (tester) async {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 2,
        paidAmount: '0',
        serviceAmount: '66',
        hasOpenNoShowDispute: false,
      );
      await _pump(tester, BookingPaymentCard(booking: booking));

      expect(find.text('تذكير بالمبلغ المتبقي'), findsOneWidget);
      expect(find.text('توضيح حالة الحجز'), findsNothing);
      expect(find.text('هناك نزاع مفتوح حول الحضور — لم يُحسم بعد.'),
          findsNothing);
    });

    testWidgets(
        'open dispute → neutral action replaces the reminder, never both',
        (tester) async {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 2,
        paidAmount: '0',
        serviceAmount: '66',
        hasOpenNoShowDispute: true,
      );
      await _pump(tester, BookingPaymentCard(booking: booking));

      expect(find.text('توضيح حالة الحجز'), findsOneWidget);
      expect(find.text('تذكير بالمبلغ المتبقي'), findsNothing);
    });

    testWidgets('open dispute shows the three manager proposal actions',
        (tester) async {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 2,
        paidAmount: '0',
        serviceAmount: '66',
        hasOpenNoShowDispute: true,
      );
      await _pump(tester, BookingPaymentCard(booking: booking));

      expect(find.text('تم الاتفاق أن الزبون حضر'), findsOneWidget);
      expect(find.text('تم الاتفاق أن الزبون لم يحضر'), findsOneWidget);
      expect(find.text('ما زال هناك خلاف'), findsOneWidget);
    });

    testWidgets('shows the manager\'s current live proposal, not as a closed case',
        (tester) async {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 2,
        paidAmount: '0',
        serviceAmount: '66',
        hasOpenNoShowDispute: true,
        noShowDisputeManagerProposal: 'attended',
      );
      await _pump(tester, BookingPaymentCard(booking: booking));

      expect(find.textContaining('اقتراحك الحالي'), findsOneWidget);
      expect(find.textContaining('بانتظار تأكيد الزبون'), findsOneWidget);
      // Still open — the proposal action row must still be offered.
      expect(find.text('ما زال هناك خلاف'), findsOneWidget);
    });

    testWidgets(
        'a dispute with no remaining venue-collected amount shows the proposal box but no WhatsApp action',
        (tester) async {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 1,
        paidAmount: '66',
        serviceAmount: '66',
        hasOpenNoShowDispute: true,
      );
      await _pump(tester, BookingPaymentCard(booking: booking));

      expect(find.text('توضيح حالة الحجز'), findsNothing);
      expect(find.text('تذكير بالمبلغ المتبقي'), findsNothing);
      expect(find.text('هناك نزاع مفتوح حول الحضور — لم يُحسم بعد.'),
          findsOneWidget);
    });
  });

  group('venue customer block', () {
    testWidgets('not blocked → shows the block action', (tester) async {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 2,
        paidAmount: '0',
        serviceAmount: '66',
        isBlockedByVenue: false,
      );
      await _pump(tester, BookingCustomerCard(booking: booking));

      expect(find.text('حظر الزبون'), findsOneWidget);
      expect(find.text('الزبون محظور من الحجز'), findsNothing);
    });

    testWidgets('blocked → shows the blocked state and unblock action, '
        'with the reason but never the private note', (tester) async {
      final booking = _booking(
        paymentTypeId: 1,
        paymentStatus: 2,
        paidAmount: '0',
        serviceAmount: '66',
        isBlockedByVenue: true,
        venueBlockReasonLabel: 'مبالغ غير مسددة',
      );
      await _pump(tester, BookingCustomerCard(booking: booking));

      expect(find.textContaining('الزبون محظور من الحجز'), findsOneWidget);
      expect(find.textContaining('مبالغ غير مسددة'), findsOneWidget);
      expect(find.text('إلغاء الحظر'), findsOneWidget);
      expect(find.text('حظر الزبون'), findsNothing);
    });
  });
}
