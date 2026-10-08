import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';

class ManagerFieldCreateSheet extends StatefulWidget {
  const ManagerFieldCreateSheet({
    super.key,
    required this.categoryTypes,
  });

  final List<CategoryTypeOption> categoryTypes;

  @override
  State<ManagerFieldCreateSheet> createState() =>
      _ManagerFieldCreateSheetState();
}

class _SportDraft {
  int? categoryId;
  final price = TextEditingController();

  void dispose() => price.dispose();
}

class _ManagerFieldCreateSheetState extends State<ManagerFieldCreateSheet> {
  static const _green = Color(0xFF418A49);
  static const _dark = Color(0xFF20372B);
  static const _muted = Color(0xFF78847C);

  final _name = TextEditingController();
  final List<_SportDraft> _sports = [_SportDraft()];

  String _type = 'normal';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();

    for (final sport in _sports) {
      sport.dispose();
    }

    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _addSport() {
    final maxSports =
        widget.categoryTypes.length < 8 ? widget.categoryTypes.length : 8;

    if (_sports.length >= maxSports) {
      _message('وصلت للحد الأقصى للرياضات المتاحة.');
      return;
    }

    setState(() => _sports.add(_SportDraft()));
  }

  void _removeSport(int index) {
    if (index == 0 || index >= _sports.length) return;

    setState(() {
      final removed = _sports.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    final name = _name.text.trim();

    if (name.isEmpty || name.length > 200) {
      _message('اكتب اسم الملعب بشكل صحيح.');
      return;
    }

    final activeSports = _type == 'normal' ? _sports.take(1).toList() : _sports;

    if (widget.categoryTypes.isEmpty) {
      _message('لا توجد رياضات متاحة. تواصل مع الإدارة.');
      return;
    }

    final selectedIds = <int>{};
    final payload = <Map<String, dynamic>>[];

    for (final sport in activeSports) {
      final categoryId = sport.categoryId;

      if (categoryId == null) {
        _message('اختر الرياضة لكل صف.');
        return;
      }

      if (!selectedIds.add(categoryId)) {
        _message('لا يمكن إضافة نفس الرياضة مرتين.');
        return;
      }

      final price = double.tryParse(
        sport.price.text.trim().replaceAll(',', '.'),
      );

      if (price == null || !price.isFinite || price < 0 || price > 999999) {
        _message('أدخل سعرًا صحيحًا لكل رياضة.');
        return;
      }

      payload.add({
        'category_type_id': categoryId,
        'price': price,
      });
    }

    setState(() => _saving = true);

    final error = await context.read<ManagerSetupCubit>().createPhysicalField(
          name: name,
          resourceType: _type,
          sports: payload,
        );

    if (!mounted) return;

    setState(() => _saving = false);

    if (error != null) {
      _message(error);
      return;
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إضافة الملعب بنجاح'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleSports =
        _type == 'normal' ? _sports.take(1).toList() : _sports;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = MediaQuery.sizeOf(context).height - bottomInset;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: availableHeight * 0.88,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1E8E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'إضافة ملعب',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'أضف ملعبك وحدد الرياضات المتاحة فيه.',
                    style: TextStyle(
                      fontSize: 13,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'اسم الملعب',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _name,
                    maxLength: 200,
                    enabled: !_saving,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'مثال: ملعب المدينة 1',
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF8FAF8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'نوع الملعب',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('⚽ عادي'),
                        selected: _type == 'normal',
                        onSelected: _saving
                            ? null
                            : (_) => setState(
                                  () => _type = 'normal',
                                ),
                        selectedColor: const Color(0xFFE2F1E4),
                        checkmarkColor: _green,
                      ),
                      ChoiceChip(
                        label: const Text('🏟️ مالتي'),
                        selected: _type == 'multi',
                        onSelected: _saving
                            ? null
                            : (_) => setState(
                                  () => _type = 'multi',
                                ),
                        selectedColor: const Color(0xFFE2F1E4),
                        checkmarkColor: _green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _type == 'multi'
                        ? 'نفس الملعب، عدة رياضات بأسعار مستقلة.'
                        : 'ملعب لرياضة واحدة فقط.',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'الرياضات والأسعار',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (int index = 0; index < visibleSports.length; index++)
                    _sportCard(
                      visibleSports[index],
                      index,
                    ),
                  if (_type == 'multi')
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _addSport,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('إضافة رياضة'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _green,
                        side: const BorderSide(
                          color: Color(0xFFC8DCCA),
                        ),
                        minimumSize: const Size.fromHeight(45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'حفظ الملعب',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sportCard(_SportDraft sport, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5ECE6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الرياضة ${index + 1}',
                  style: const TextStyle(
                    color: _dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_type == 'multi' && index > 0)
                IconButton(
                  onPressed: _saving ? null : () => _removeSport(index),
                  tooltip: 'إزالة الرياضة',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 19,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: const Color(0xFFE0E7E1),
              ),
            ),
            child: DropdownButton<int>(
              value: sport.categoryId,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              hint: const Text('اختر الرياضة'),
              items: [
                for (final category in widget.categoryTypes)
                  DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(
                      category.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(
                        () => sport.categoryId = value,
                      ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: sport.price,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: 'السعر للساعة',
              suffixText: 'د.ل',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
