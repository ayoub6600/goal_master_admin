import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/features/manager_marketing/data/repo/manager_marketing_campaign_repo.dart';

class ManagerMarketingCampaignsView extends StatefulWidget {
  const ManagerMarketingCampaignsView({super.key});

  @override
  State<ManagerMarketingCampaignsView> createState() =>
      _ManagerMarketingCampaignsViewState();
}

class _ManagerMarketingCampaignsViewState
    extends State<ManagerMarketingCampaignsView> {
  final _repo = getIt<ManagerMarketingCampaignRepo>();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _value = TextEditingController();
  final _maxDiscount = TextEditingController();
  final _perCustomer = TextEditingController();
  final _totalLimit = TextEditingController();
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _campaigns = [];
  int? _branchId;
  int? _serviceId;
  String _discountType = 'percent';
  DateTime _startsAt = DateTime.now();
  DateTime _endsAt = DateTime.now().add(const Duration(days: 7));
  final Set<int> _selectedHours = {};
  final Set<int> _weekdays = {};
  bool _newCustomersOnly = false;
  bool _loading = true;
  bool _saving = false;
  final Set<int> _togglingCampaignIds = {};

  static const _weekdayNames = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _maxDiscount.dispose();
    _perCustomer.dispose();
    _totalLimit.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _repo.index();
    if (!mounted) return;
    result.fold(
      (failure) => _message(failure.errMessage),
      (data) {
        _branches = _maps(data['branches']);
        _services = _maps(data['services']);
        _campaigns = _maps(data['campaigns']);
        if (_branchId == null && _branches.isNotEmpty) {
          _branchId = int.tryParse('${_branches.first['id']}');
        }
      },
    );
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
      : [];

  String _dateTime(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  List<Map<String, String>> _selectedTimeRanges() {
    final hours = _selectedHours.toList()..sort();
    final ranges = <Map<String, String>>[];
    for (final hour in hours) {
      if (ranges.isNotEmpty &&
          int.parse(ranges.last['end']!.substring(0, 2)) == hour) {
        ranges.last['end'] = '${(hour + 1).toString().padLeft(2, '0')}:00';
      } else {
        ranges.add({
          'start': '${hour.toString().padLeft(2, '0')}:00',
          'end': '${(hour + 1).toString().padLeft(2, '0')}:00',
        });
      }
    }
    if (ranges.isNotEmpty && ranges.last['end'] == '24:00') {
      ranges.last['end'] = '24:00';
    }
    return ranges;
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate() || _branchId == null) return;
    if (_endsAt.isBefore(_startsAt) || _endsAt.isAtSameMomentAs(_startsAt)) {
      _message('نهاية العرض يجب أن تكون بعد بدايته.');
      return;
    }
    setState(() => _saving = true);
    final timeRanges = _selectedTimeRanges();
    final data = <String, dynamic>{
      'cmn_branch_id': _branchId,
      'sch_service_id': _serviceId,
      'name': _name.text.trim(),
      'discount_type': _discountType,
      'discount_value': double.parse(_value.text),
      'starts_at': _dateTime(_startsAt),
      'ends_at': _dateTime(_endsAt),
      'weekdays': _weekdays.isEmpty ? null : (_weekdays.toList()..sort()),
      'daily_time_ranges': timeRanges.isEmpty ? null : timeRanges,
      'new_customers_only': _newCustomersOnly,
      'max_uses_per_customer': int.tryParse(_perCustomer.text),
      'max_redemptions': int.tryParse(_totalLimit.text),
      'max_discount': double.tryParse(_maxDiscount.text),
    };
    final result = await _repo.create(data);
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold((failure) => _message(failure.errMessage), (message) {
      _message(message);
      _name.clear();
      _value.clear();
      _maxDiscount.clear();
      _perCustomer.clear();
      _totalLimit.clear();
      setState(() {
        _weekdays.clear();
        _selectedHours.clear();
        _newCustomersOnly = false;
        _serviceId = null;
      });
      _load();
    });
  }

  Future<void> _toggle(int id) async {
    if (id <= 0) {
      _message('تعذر تحديد رقم الحملة. حدّث القائمة ثم أعد المحاولة.');
      await _load();
      return;
    }
    setState(() => _togglingCampaignIds.add(id));
    final result = await _repo.toggle(id);
    if (!mounted) return;
    setState(() => _togglingCampaignIds.remove(id));
    await result.fold<Future<void>>((failure) async {
      await _load();
      if (mounted) _message(failure.errMessage);
    }, (message) async {
      _message(message);
      await _load();
    });
  }

  void _message(String value) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => PageWrapper(
        title: 'العروض والخصومات',
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  const Card(
                    color: Color(0xffeff7ed),
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                          'خصومات هذه الصفحة يتحملها الملعب. اختر مرفقًا بعينه أو طبّق العرض على كامل الملعب؛ تُحفظ العروض متوقفة حتى تفعيلها.'),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _form(),
                  SizedBox(height: 20.h),
                  Text('حملاتي', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8.h),
                  if (_campaigns.isEmpty)
                    const Card(
                        child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('لا توجد حملات حتى الآن.')))
                  else
                    ..._campaigns.map(_campaignCard),
                ],
              ),
      );

  Widget _form() => Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('إنشاء خصم جديد',
                    style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 12.h),
                DropdownButtonFormField<int>(
                  initialValue: _branchId,
                  decoration: const InputDecoration(labelText: 'الملعب'),
                  items: _branches.map((branch) {
                    final id = int.tryParse('${branch['id']}') ?? 0;
                    return DropdownMenuItem(
                        value: id,
                        child: Text('${branch['name'] ?? 'الملعب'}'));
                  }).toList(),
                  onChanged: (value) => setState(() {
                    _branchId = value;
                    _serviceId = null;
                  }),
                ),
                DropdownButtonFormField<int?>(
                  initialValue: _serviceId,
                  decoration:
                      const InputDecoration(labelText: 'المرفق المستهدف'),
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null, child: Text('كامل الملعب')),
                    ..._services
                        .where((service) =>
                            int.tryParse('${service['cmn_branch_id']}') ==
                            _branchId)
                        .map((service) => DropdownMenuItem<int?>(
                              value: int.tryParse('${service['id']}'),
                              child: Text('${service['title'] ?? 'مرفق'}'),
                            )),
                  ],
                  onChanged: (value) => setState(() => _serviceId = value),
                ),
                TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'اسم العرض'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'أدخل اسم العرض'
                            : null),
                DropdownButtonFormField<String>(
                  initialValue: _discountType,
                  decoration: const InputDecoration(labelText: 'نوع الخصم'),
                  items: const [
                    DropdownMenuItem(
                        value: 'percent', child: Text('نسبة مئوية')),
                    DropdownMenuItem(
                        value: 'fixed', child: Text('مبلغ ثابت بالدينار'))
                  ],
                  onChanged: (value) =>
                      setState(() => _discountType = value ?? 'percent'),
                ),
                TextFormField(
                    controller: _value,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: _discountType == 'percent'
                            ? 'نسبة الخصم %'
                            : 'قيمة الخصم د.ل'),
                    validator: (value) {
                      final number = double.tryParse(value ?? '');
                      if (number == null ||
                          number <= 0 ||
                          (_discountType == 'percent' && number > 100)) {
                        return 'أدخل قيمة خصم صحيحة';
                      }
                      return null;
                    }),
                TextFormField(
                    controller: _maxDiscount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'الحد الأعلى للخصم بالدينار (اختياري)')),
                SizedBox(height: 8.h),
                _dateButton('بداية العرض', _startsAt,
                    (value) => setState(() => _startsAt = value)),
                _dateButton('نهاية العرض', _endsAt,
                    (value) => setState(() => _endsAt = value)),
                Align(
                    alignment: Alignment.centerRight,
                    child: Text('أيام التفعيل: اتركها فارغة لتشمل كل الأيام',
                        style: Theme.of(context).textTheme.bodySmall)),
                Wrap(
                    spacing: 4,
                    children: List.generate(
                        7,
                        (day) => FilterChip(
                            label: Text(_weekdayNames[day]),
                            selected: _weekdays.contains(day),
                            onSelected: (selected) => setState(() => selected
                                ? _weekdays.add(day)
                                : _weekdays.remove(day))))),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('ساعات العرض',
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                Text(
                  _selectedHours.isEmpty
                      ? 'يشمل العرض كل ساعات اليوم. اضغط لتحديد ساعات بعينها.'
                      : 'حدد الساعات التي يسري عليها الخصم. يمكنك اختيار أكثر من فترة.',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _selectedHours.clear()),
                    icon: const Icon(Icons.select_all),
                    label: const Text('كل اليوم'),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: List.generate(24, (hour) {
                    final next = (hour + 1) % 24;
                    final label = '${hour.toString().padLeft(2, '0')}:00 - '
                        '${next.toString().padLeft(2, '0')}:00${hour == 23 ? ' (منتصف الليل)' : ''}';
                    return FilterChip(
                      label: Text(label),
                      selected: _selectedHours.contains(hour),
                      onSelected: (selected) => setState(() => selected
                          ? _selectedHours.add(hour)
                          : _selectedHours.remove(hour)),
                    );
                  }),
                ),
                TextFormField(
                    controller: _perCustomer,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'مرات الاستخدام لكل زبون',
                        hintText: 'فارغ = بلا حد'),
                    validator: _positiveIntValidator),
                TextFormField(
                    controller: _totalLimit,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'إجمالي مرات استخدام الحملة',
                        hintText: 'فارغ = بلا حد'),
                    validator: _positiveIntValidator),
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _newCustomersOnly,
                    onChanged: (value) =>
                        setState(() => _newCustomersOnly = value ?? false),
                    title: const Text('للزبائن الذين لم يسبق لهم الحجز')),
                SizedBox(height: 8.h),
                FilledButton.icon(
                    onPressed: _saving ? null : _create,
                    icon: const Icon(Icons.add),
                    label:
                        Text(_saving ? 'جارٍ الحفظ...' : 'حفظ العرض متوقفًا')),
              ],
            ),
          ),
        ),
      );

  String? _positiveIntValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = int.tryParse(value);
    return number == null || number < 1 ? 'أدخل عددًا صحيحًا موجبًا' : null;
  }

  Widget _dateButton(
          String label, DateTime value, ValueChanged<DateTime> onPicked) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: OutlinedButton.icon(
          onPressed: () async {
            final picked = await _pickDateTime(value);
            if (picked != null) onPicked(picked);
          },
          icon: const Icon(Icons.schedule),
          label: Text('$label: ${_dateTime(value)}'),
        ),
      );

  Widget _campaignCard(Map<String, dynamic> campaign) {
    final id = int.tryParse('${campaign['id']}') ?? 0;
    final active = campaign['is_active'] == true;
    final value = campaign['discount_type'] == 'percent'
        ? '${campaign['discount_value']}%'
        : '${campaign['discount_value']} د.ل';
    final days = (campaign['weekdays'] as List?)
            ?.map((day) => _weekdayNames[int.tryParse('$day') ?? 0])
            .join('، ') ??
        'كل الأيام';
    final ranges = (campaign['daily_time_ranges'] as List? ?? const [])
        .whereType<Map>()
        .map((range) => Map<String, dynamic>.from(range))
        .toList();
    final times = ranges.isNotEmpty
        ? ranges.map((range) => '${range['start']}–${range['end']}').join('، ')
        : (campaign['daily_start_time'] != null &&
                campaign['daily_end_time'] != null
            ? '${campaign['daily_start_time'].toString().substring(0, 5)}–${campaign['daily_end_time'].toString().substring(0, 5)}'
            : 'كل الساعات');
    final venueFunded = campaign['can_manage'] != false;
    final startsAt = campaign['starts_at']?.toString() ?? '';
    final endsAt = campaign['ends_at']?.toString() ?? '';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
              right: BorderSide(
            color: active ? const Color(0xff43894b) : Colors.orange,
            width: 5,
          )),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text('${campaign['name'] ?? 'عرض'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                Text(value,
                    style: TextStyle(
                        color: active ? const Color(0xff28743a) : Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ]),
              SizedBox(height: 8.h),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _campaignTag(active ? 'مفعّل' : 'متوقف',
                    active ? const Color(0xffe7f4e9) : const Color(0xfffff2dc)),
                _campaignTag(
                    venueFunded ? 'على حساب الملعب' : 'على حساب جول ماستر',
                    venueFunded
                        ? const Color(0xffe9f2ff)
                        : const Color(0xffffefdf)),
                _campaignTag(
                    campaign['service_name']?.toString() ?? 'كامل الملعب',
                    const Color(0xfff0f1f4)),
              ]),
              SizedBox(height: 6.h),
              Text(
                '${campaign['new_customers_only'] == true ? 'للزبائن الجدد فقط' : 'لكل الزبائن'} · $days · $times',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (startsAt.isNotEmpty || endsAt.isNotEmpty)
                Text('الفترة: $startsAt إلى $endsAt',
                    style: Theme.of(context).textTheme.bodySmall),
              Text(
                'استخدامات: ${campaign['redemptions_count'] ?? 0}${campaign['max_uses_per_customer'] != null ? ' · حد الزبون: ${campaign['max_uses_per_customer']}' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: venueFunded
                    ? Switch(
                        value: active,
                        onChanged: _togglingCampaignIds.contains(id)
                            ? null
                            : (_) => _toggle(id),
                      )
                    : const Tooltip(
                        message: 'حملات المنصة لا يديرها الملعب',
                        child: Icon(Icons.lock_outline),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campaignTag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      );
}
