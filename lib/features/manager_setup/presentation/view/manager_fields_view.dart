import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/manager_field_create_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/manager_sport_images_sheet.dart';

class ManagerFieldsView extends StatelessWidget {
  const ManagerFieldsView({super.key});

  static const _green = Color(0xFF418A49);
  static const _dark = Color(0xFF20372B);
  static const _muted = Color(0xFF78847C);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        appBar: AppBar(
          title: const Text(
            'الملاعب والخدمات',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        body: BlocBuilder<ManagerSetupCubit, ManagerSetupState>(
          builder: (context, state) {
            final ManagerSetupBootstrapResponse? bootstrap = switch (state) {
              final ManagerSetupLoaded s => s.response,
              final ManagerSetupSubmitting s => s.bootstrap,
              final ManagerSetupFailure s => s.bootstrap,
              final ManagerBookingPeriodsSuccess s => s.bootstrap,
              _ => context.read<ManagerSetupCubit>().bootstrapResponse,
            };

            if (bootstrap == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final groups = <int, List<SetupServiceItem>>{};

            for (final service in bootstrap.data.catalog.services) {
              final id = service.physicalResource?.id ?? -service.id;

              groups
                  .putIfAbsent(
                    id,
                    () => <SetupServiceItem>[],
                  )
                  .add(service);
            }

            final fields = groups.values.toList();

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<ManagerSetupCubit>().loadBootstrap(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ملاعبي',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: _dark,
                          ),
                        ),
                      ),
                      Text(
                        '${fields.length} ملاعب',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'اضغط على أي ملعب لعرض رياضاته وأسعاره.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => _openCreateField(
                        context,
                        bootstrap.data.categoryTypes,
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'إضافة ملعب',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (fields.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text('لا توجد ملاعب مضافة بعد'),
                      ),
                    ),
                  for (final sports in fields) ...[
                    _fieldCard(context, sports, bootstrap.data.categoryTypes),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _fieldCard(
    BuildContext context,
    List<SetupServiceItem> sports,
    List<CategoryTypeOption> categoryTypes,
  ) {
    final resource = sports.first.physicalResource;
    final name =
        resource?.name.isNotEmpty == true ? resource!.name : sports.first.title;
    final isMulti = resource?.isMulti ?? false;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => _openFieldEditor(context, sports, categoryTypes),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: const Color(0xFFE7EBE7),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isMulti
                      ? Icons.stadium_outlined
                      : Icons.sports_soccer_rounded,
                  color: _green,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isMulti
                          ? 'مالتي · ${sports.length} رياضات'
                          : 'عادي · رياضة واحدة',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sports.length == 1
                          ? '${_price(sports.first.price)} د.ل / ساعة'
                          : 'أسعار مستقلة حسب الرياضة',
                      style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _price(double value) {
    return value.toStringAsFixed(
      value == value.roundToDouble() ? 0 : 2,
    );
  }

  void _openCreateField(
    BuildContext context,
    List<CategoryTypeOption> categories,
  ) {
    final cubit = context.read<ManagerSetupCubit>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ManagerFieldCreateSheet(
          categoryTypes: categories,
        ),
      ),
    );
  }

  void _openFieldEditor(
    BuildContext context,
    List<SetupServiceItem> sports,
    List<CategoryTypeOption> categoryTypes,
  ) {
    final resource = sports.first.physicalResource;

    if (resource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذا الملعب يحتاج إلى تحديث بياناته أولاً.'),
        ),
      );
      return;
    }

    final cubit = context.read<ManagerSetupCubit>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _FieldEditorSheet(
          resource: resource,
          sports: sports,
          categoryTypes: categoryTypes,
        ),
      ),
    );
  }
}

class _FieldEditorSheet extends StatefulWidget {
  const _FieldEditorSheet({
    required this.resource,
    required this.sports,
    required this.categoryTypes,
  });

  final SetupPhysicalResource resource;
  final List<SetupServiceItem> sports;
  final List<CategoryTypeOption> categoryTypes;

  @override
  State<_FieldEditorSheet> createState() => _FieldEditorSheetState();
}

class _FieldEditorSheetState extends State<_FieldEditorSheet> {
  static const _green = Color(0xFF418A49);
  static const _dark = Color(0xFF20372B);
  static const _muted = Color(0xFF78847C);

  late final TextEditingController _name;
  late String _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.resource.name);
    _type = widget.resource.type;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(value),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _save() async {
    if (_saving) return;

    final name = _name.text.trim();

    if (name.isEmpty || name.length > 200) {
      _message('اكتب اسمًا صحيحًا للملعب.');
      return;
    }

    if (_type == 'normal' && _liveSports(context).length > 1) {
      _message(
        'الملعب مرتبط بأكثر من رياضة، لذلك لازم يبقى مالتي.',
      );
      return;
    }

    setState(() => _saving = true);

    final error =
        await context.read<ManagerSetupCubit>().updatePhysicalResourceDetails(
              resourceId: widget.resource.id,
              name: name,
              resourceType: _type,
            );

    if (!mounted) return;

    setState(() => _saving = false);

    if (error != null) {
      _message(error);
      return;
    }

    Navigator.of(context).pop();
  }

  /// The field's sports as they actually stand right now — recomputed from
  /// the cubit's latest bootstrap so a price edit or a newly added sport
  /// shows up without closing and reopening this sheet.
  List<SetupServiceItem> _liveSports(BuildContext context) {
    final bootstrap = context.read<ManagerSetupCubit>().bootstrapResponse;
    if (bootstrap == null) return widget.sports;

    final current = bootstrap.data.catalog.services
        .where((s) => s.physicalResource?.id == widget.resource.id)
        .toList();

    return current.isEmpty ? widget.sports : current;
  }

  Future<void> _editPrice(SetupServiceItem sport) async {
    final controller = TextEditingController(
      text: sport.price.toStringAsFixed(
        sport.price == sport.price.roundToDouble() ? 0 : 2,
      ),
    );

    final newPrice = await showDialog<double>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('سعر ${sport.title}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(suffixText: 'د.ل / ساعة'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    // Not disposed here on purpose: showDialog's Future resolves as soon as
    // Navigator.pop() runs, but the dialog's own closing transition can
    // still be painting its TextField for a bit after that — disposing the
    // controller immediately races a rebuild triggered by the price-update
    // call below against a TextField still bound to it. A short-lived local
    // controller like this is reclaimed once nothing references it anymore.

    if (newPrice == null || !mounted) return;

    if (newPrice < 0) {
      _message('السعر غير صالح.');
      return;
    }

    final error = await context.read<ManagerSetupCubit>().updateSportPrice(
          resourceId: widget.resource.id,
          serviceId: sport.id,
          price: newPrice,
        );

    if (!mounted) return;

    if (error != null) {
      _message(error);
    } else {
      _message('تم تحديث السعر بنجاح');
    }
  }

  Future<void> _addSport(List<SetupServiceItem> currentSports) async {
    final usedCategoryIds = currentSports
        .map((s) => s.categoryTypeId)
        .whereType<int>()
        .toSet();

    final available = widget.categoryTypes
        .where((c) => !usedCategoryIds.contains(c.id))
        .toList();

    if (available.isEmpty) {
      _message('كل الرياضات المتاحة مضافة لهذا الملعب بالفعل.');
      return;
    }

    CategoryTypeOption selected = available.first;
    final priceController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('إضافة رياضة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<CategoryTypeOption>(
                  isExpanded: true,
                  value: selected,
                  items: [
                    for (final option in available)
                      DropdownMenuItem(
                        value: option,
                        child: Text(option.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selected = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'السعر بالساعة',
                    suffixText: 'د.ل',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('إضافة'),
              ),
            ],
          ),
        ),
      ),
    );

    final price = double.tryParse(priceController.text.trim());
    // Not disposed here — see the note in _editPrice() above for why.

    if (result != true || !mounted) return;

    if (price == null || price < 0) {
      _message('اكتب سعرًا صحيحًا.');
      return;
    }

    final error = await context.read<ManagerSetupCubit>().addSportToField(
          resourceId: widget.resource.id,
          categoryTypeId: selected.id,
          price: price,
        );

    if (!mounted) return;

    if (error != null) {
      _message(error);
    } else {
      _message('تمت إضافة الرياضة بنجاح');
    }
  }

  void _openImages(SetupServiceItem sport) {
    final cubit = context.read<ManagerSetupCubit>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ManagerSportImagesSheet(
          serviceId: sport.id,
          sportTitle: sport.title,
          initialImages: sport.images,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild this sheet whenever the cubit's bootstrap changes (a price
    // edit or a newly added sport), without closing it. A bare
    // context.watch<ManagerSetupCubit>() does NOT do this — provider only
    // rebuilds on the PROVIDED INSTANCE changing, not on the cubit's own
    // state emissions — so this must be a real BlocBuilder.
    return BlocBuilder<ManagerSetupCubit, ManagerSetupState>(
      builder: (context, _) => _buildSheet(context),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final sports = _liveSports(context);
    final multiLocked = sports.length > 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8E3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'تعديل الملعب',
                  style: TextStyle(
                    color: _dark,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'بيانات بسيطة لكل ملعب، بدون إعدادات معقدة.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'اسم الملعب',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  maxLength: 200,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'مثال: ملعب المدينة 1',
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFF8FAF8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: const BorderSide(
                        color: Color(0xFFE1E9E2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'نوع الملعب',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('⚽ عادي'),
                      selected: _type == 'normal',
                      onSelected: multiLocked
                          ? null
                          : (_) => setState(() => _type = 'normal'),
                      selectedColor: const Color(0xFFE3F2E4),
                      checkmarkColor: _green,
                    ),
                    ChoiceChip(
                      label: const Text('🏟️ مالتي'),
                      selected: _type == 'multi',
                      onSelected: (_) => setState(
                        () => _type = 'multi',
                      ),
                      selectedColor: const Color(0xFFE3F2E4),
                      checkmarkColor: _green,
                    ),
                  ],
                ),
                if (multiLocked)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'الملعب المالتي فيه أكثر من رياضة، ولا يمكن تحويله لعادي دون فصلها.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'الرياضات والأسعار',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                        ),
                      ),
                    ),
                    Text(
                      '${sports.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final sport in sports)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE7ECE7),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sports_outlined,
                          color: _green,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            sport.title,
                            style: const TextStyle(
                              color: _dark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'الصور',
                          onPressed: () => _openImages(sport),
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            color: _muted,
                            size: 20,
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _editPrice(sport),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${sport.price.toStringAsFixed(0)} د.ل',
                                  style: const TextStyle(
                                    color: _green,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: _green,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_type == 'multi')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: OutlinedButton.icon(
                      onPressed: () => _addSport(sports),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('إضافة رياضة'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _green,
                        side: const BorderSide(color: _green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'حوّل الملعب إلى مالتي لإضافة رياضة ثانية.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 25),
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
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'حفظ التغييرات',
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
    );
  }
}
