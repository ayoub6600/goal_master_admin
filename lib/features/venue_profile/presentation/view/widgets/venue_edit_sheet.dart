import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';
import 'package:image_picker/image_picker.dart';

/// Which part of the venue the manager asked to change.
enum VenueEditSection {
  identity,
  contact,
  location;

  String get title => switch (this) {
        VenueEditSection.identity => 'تعديل المعلومات الأساسية',
        VenueEditSection.contact => 'تعديل بيانات التواصل',
        VenueEditSection.location => 'تعديل الموقع',
      };
}

void showVenueEditSheet({
  required BuildContext context,
  required VenueEditSection section,
}) {
  final cubit = context.read<ManagerSetupCubit>();
  final branch = cubit.bootstrapResponse?.data.setup.branch;
  if (branch == null) return;

  baseBottomSheet(
    title: section.title,
    context: context,
    hideNavBar: false,
    child: BlocProvider.value(
      value: cubit,
      child: VenueEditForm(section: section, branch: branch),
    ),
  );
}

/// Edits one section, and saves the venue as a whole.
///
/// `saveBranchSetup` replaces every field of the branch in one call, so the
/// untouched values are sent back exactly as they were read. Editing the phone
/// therefore cannot silently blank the address — a real risk with a
/// full-replacement endpoint driven by a partial form.
class VenueEditForm extends StatefulWidget {
  const VenueEditForm({
    super.key,
    required this.section,
    required this.branch,
    this.onSubmit,
  });

  final VenueEditSection section;
  final dynamic branch;

  /// Injected by tests to capture the payload instead of sending it.
  final void Function(Map<String, String> values)? onSubmit;

  @override
  State<VenueEditForm> createState() => _VenueEditFormState();
}

class _VenueEditFormState extends State<VenueEditForm> {
  late final Map<String, TextEditingController> _fields;
  late final Map<String, String> _original;
  XFile? _image;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();

    _original = {
      'name': widget.branch.name.toString(),
      'phone': widget.branch.phone.toString(),
      'email': widget.branch.email.toString(),
      'address': widget.branch.address.toString(),
    };

    _fields = {
      for (final entry in _original.entries)
        entry.key: TextEditingController(text: entry.value),
    };

    for (final c in _fields.values) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _visibleKeys => switch (widget.section) {
        VenueEditSection.identity => ['name'],
        VenueEditSection.contact => ['phone', 'email'],
        VenueEditSection.location => ['address'],
      };

  String _label(String key) => switch (key) {
        'name' => 'اسم الملعب',
        'phone' => 'رقم الهاتف',
        'email' => 'البريد الإلكتروني',
        _ => 'العنوان',
      };

  /// Nothing to save until something actually differs.
  bool get _dirty {
    if (_image != null) return true;

    return _visibleKeys
        .any((k) => _fields[k]!.text.trim() != _original[k]!.trim());
  }

  String? get _problem {
    for (final key in _visibleKeys) {
      if (_fields[key]!.text.trim().isEmpty) {
        return '${_label(key)} لا يمكن أن يكون فارغًا.';
      }
    }
    return null;
  }

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _image = picked);
  }

  void _save() {
    final problem = _problem;
    if (problem != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
      return;
    }

    // Guards a double tap: the endpoint replaces the whole branch, so sending
    // twice is not merely wasteful.
    if (_submitted) return;
    setState(() => _submitted = true);

    final values = {
      for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
    };

    if (widget.onSubmit != null) {
      widget.onSubmit!(values);
      return;
    }

    context.read<ManagerSetupCubit>().saveBranchSetup(
          branchName: values['name']!,
          zoneId: widget.branch.zoneId as int,
          phone: values['phone']!,
          email: values['email']!,
          address: values['address']!,
          lat: widget.branch.lat.toString(),
          long: widget.branch.long.toString(),
          image: _image == null ? null : File(_image!.path),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ManagerSetupCubit, ManagerSetupState>(
      listener: (context, state) {
        if (state is ManagerSetupFailure) {
          setState(() => _submitted = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is ManagerSetupLoaded && _submitted) {
          // Confirmed by a reload, not assumed from a 200.
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ بيانات الملعب.')),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.section == VenueEditSection.identity) ...[
              _logoPicker(),
              SizedBox(height: 14.h),
            ],
            for (final key in _visibleKeys) ...[
              _field(key),
              SizedBox(height: 12.h),
            ],
            if (widget.section == VenueEditSection.location)
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text(
                  'لتحديد الموقع على الخريطة استخدم شاشة إعداد الملعب.',
                  style: AppTextStyles.font12Regular
                      .copyWith(color: AppColors.dark2),
                ),
              ),
            SizedBox(height: 4.h),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _logoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: AppColors.primaryBlueLight2,
              shape: BoxShape.circle,
              image: _image == null
                  ? null
                  : DecorationImage(
                      image: FileImage(File(_image!.path)), fit: BoxFit.cover),
            ),
            child: _image == null
                ? Icon(Icons.add_a_photo_outlined,
                    size: 22.r, color: AppColors.primary)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _image == null ? 'تغيير شعار الملعب' : 'تم اختيار صورة جديدة',
              style:
                  AppTextStyles.font14SemiBold.copyWith(color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_label(key),
            style:
                AppTextStyles.font12Regular.copyWith(color: AppColors.dark2)),
        SizedBox(height: 6.h),
        TextField(
          controller: _fields[key],
          keyboardType: switch (key) {
            'phone' => TextInputType.phone,
            'email' => TextInputType.emailAddress,
            _ => TextInputType.text,
          },
          textDirection: key == 'phone' || key == 'email'
              ? TextDirection.ltr
              : null,
          style: AppTextStyles.font14Regular.copyWith(color: AppColors.dark),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.inactive3,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.inactive4),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.inactive4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _saveButton() {
    final ready = _dirty && !_submitted;

    return GestureDetector(
      onTap: ready ? _save : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          color: ready ? AppColors.primary : AppColors.inactive4,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            _submitted ? 'جارٍ الحفظ…' : 'حفظ التغييرات',
            style: AppTextStyles.font16Bold.copyWith(
              color: ready ? AppColors.white : AppColors.dark2,
            ),
          ),
        ),
      ),
    );
  }
}
