String formatToInternationalPhone(String phone, {String countryCode = '966'}) {
  // إزالة أي محارف غير أرقام
  phone = phone.replaceAll(RegExp(r'[^\d]'), '');

  // إذا بدأ بصفر، نحذفه ونضيف رمز الدولة
  if (phone.startsWith('0')) {
    phone = phone.substring(1);
  }

  // إذا لم يبدأ برمز الدولة، نضيفه
  if (!phone.startsWith(countryCode)) {
    phone = countryCode + phone;
  }

  return phone;
}
