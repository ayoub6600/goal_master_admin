import 'package:url_launcher/url_launcher.dart';

Future<void> launchWhatsApp(String rawPhone) async {
  try {
    // تنظيف الرقم من أي أحرف غير رقمية
    final cleanedPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

    // التأكد من أن الرقم يبدأ بمفتاح الدولة بدون 00 أو +
    String phone;
    if (cleanedPhone.startsWith('966')) {
      phone = cleanedPhone;
    } else if (cleanedPhone.startsWith('00966')) {
      phone = cleanedPhone.substring(2);
    } else if (cleanedPhone.startsWith('0')) {
      phone = '966${cleanedPhone.substring(1)}';
    } else {
      phone = '966$cleanedPhone';
    }

    final Uri uri = Uri.parse("https://wa.me/$phone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      // محاولة فتح في المتصفح إذا فشل فتح التطبيق
      await launchUrl(
        Uri.parse("https://web.whatsapp.com/send?phone=$phone"),
        mode: LaunchMode.externalApplication,
      );
    }
  } catch (e) {
    throw 'تعذر فتح واتساب: ${e.toString()}';
  }
}
