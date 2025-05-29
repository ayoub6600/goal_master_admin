import 'package:url_launcher/url_launcher.dart';

Future<void> launchPhoneCall(String phoneNumber) async {
  try {
    // تنظيف الرقم وإعداده بشكل صحيح
    final formattedNumber = _formatPhoneNumber(phoneNumber);

    if (formattedNumber.isEmpty) {
      throw 'رقم الهاتف غير صالح';
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: formattedNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      // محاولة بديلة إذا فشلت الطريقة الأولى
      await _tryAlternativeDialMethods(formattedNumber);
    }
  } catch (e) {
    throw 'لا يمكن إجراء المكالمة: ${e.toString()}';
  }
}

String _formatPhoneNumber(String phoneNumber) {
  // إزالة جميع الأحرف غير الرقمية باستثناء +
  final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

  // إذا كان الرقم يبدأ بـ 00 نستبدلها بـ +
  if (cleaned.startsWith('00')) {
    return '+${cleaned.substring(2)}';
  }

  // إذا كان الرقم يبدأ بـ 0 نضيف مفتاح الدولة (966 للسعودية)
  if (cleaned.startsWith('0') && !cleaned.startsWith('+')) {
    return '+966${cleaned.substring(1)}';
  }

  // إذا كان الرقم لا يحتوي على + نضيفها
  if (!cleaned.startsWith('+')) {
    return '+$cleaned';
  }

  return cleaned;
}

Future<void> _tryAlternativeDialMethods(String formattedNumber) async {
  try {
    // محاولة باستخدام intent مباشر (لأندرويد)
    final Uri altUri = Uri.parse('tel:$formattedNumber');
    await launchUrl(altUri, mode: LaunchMode.externalApplication);
  } catch (e) {
    // إذا فشل كل شيء، نفتح لوحة الاتصال مع الرقم مملوء
    final Uri fallbackUri = Uri(
      scheme: 'tel',
      path: formattedNumber,
      queryParameters: {'autodial': 'false'},
    );
    await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
  }
}
