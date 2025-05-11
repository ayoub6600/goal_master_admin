import 'package:flutter/material.dart';

class CustomDropDownShimmerNew extends StatelessWidget {
  const CustomDropDownShimmerNew({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    this.onChanged,
    this.selectedValue,
  });

  final String label;
  final String hint;
  final List<Map<String, dynamic>> items;
  final Function(String?)? onChanged;
  final String? selectedValue;

  @override
  Widget build(BuildContext context) {
    final dropdownItems = items
        .map((e) => DropdownMenuItem<String>(
              value: e['id'].toString(), // تأكد أن القيمة String
              child: Text(e['name_ar']),
            ))
        .toList();

    final isValidValue =
        dropdownItems.any((item) => item.value == selectedValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: isValidValue ? selectedValue : null, // فقط لو القيمة موجودة
          hint: Text(hint),
          items: dropdownItems,
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
