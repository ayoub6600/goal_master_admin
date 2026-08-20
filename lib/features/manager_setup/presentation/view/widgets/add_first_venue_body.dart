import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/location_picker_view.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/profile_cubit/profile_cubit.dart';
import 'package:image_picker/image_picker.dart';

class AddFirstVenueBody extends StatefulWidget {
  const AddFirstVenueBody({super.key});

  @override
  State<AddFirstVenueBody> createState() => _AddFirstVenueBodyState();
}

class _AddFirstVenueBodyState extends State<AddFirstVenueBody> {
  final _branchNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _longController = TextEditingController();
  CategoryTypeOption? _selectedCategoryType;

  ZoneOption? _selectedZone;
  XFile? _selectedImage;
  bool _didPrefillBranch = false;
  bool _didPrefillCatalog = false;
  bool _isEditingBranch = false;
  final List<_ManagerServiceDraft> _serviceDrafts = [];

  @override
  void initState() {
    super.initState();
    if (_serviceDrafts.isEmpty) {
      _serviceDrafts.add(_ManagerServiceDraft());
    }
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _longController.dispose();
    for (final draft in _serviceDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _prefillBranch(ManagerSetupBootstrapResponse? bootstrap) {
    if (_didPrefillBranch || bootstrap == null) return;

    final branch = bootstrap.data.setup.branch;
    if (branch != null) {
      _branchNameController.text = branch.name;
      _phoneController.text = branch.phone;
      _emailController.text = branch.email;
      _addressController.text = branch.address;
      _latController.text = branch.lat;
      _longController.text = branch.long;
      _selectedZone = bootstrap.data.zones.cast<ZoneOption?>().firstWhere(
            (item) => item?.id == branch.zoneId,
            orElse: () => null,
          );
    } else {
      // No branch yet: default the branch contact fields to the manager's
      // own account email/phone so they don't have to retype them. This is
      // just a starting value — the branch's contact info is a separate
      // field from the manager's login email and can be changed here.
      final profileState = context.read<ProfileCubit>().state;
      if (profileState is ProfileLoaded) {
        final accountEmail = profileState.user.email?.toString() ?? '';
        final accountPhone = profileState.user.phoneNumber ?? '';
        if (accountEmail.isNotEmpty) _emailController.text = accountEmail;
        if (accountPhone.isNotEmpty) _phoneController.text = accountPhone;
      }
    }

    // Start in read-only mode when there is already saved company data, so
    // the screen shows a tidy summary first instead of an open form. First
    // time setup (no branch yet) has nothing to summarize, so go straight
    // to editing.
    _isEditingBranch = branch == null;
    _didPrefillBranch = true;
  }

  void _startEditBranch() {
    setState(() => _isEditingBranch = true);
  }

  void _cancelEditBranch(ExistingBranch branch) {
    _branchNameController.text = branch.name;
    _phoneController.text = branch.phone;
    _emailController.text = branch.email;
    _addressController.text = branch.address;
    _latController.text = branch.lat;
    _longController.text = branch.long;
    setState(() {
      _selectedImage = null;
      _isEditingBranch = false;
    });
  }

  void _prefillCatalog(ManagerSetupBootstrapResponse? bootstrap) {
    if (_didPrefillCatalog || bootstrap == null) return;

    final catalog = bootstrap.data.catalog;
    if (catalog.category != null) {
      _selectedCategoryType = bootstrap.data.categoryTypes
          .cast<CategoryTypeOption?>()
          .firstWhere(
            (type) => type?.name == catalog.category!.name,
            orElse: () => null,
          );
    }

    if (catalog.services.isNotEmpty) {
      for (final draft in _serviceDrafts) {
        draft.dispose();
      }
      _serviceDrafts
        ..clear()
        ..addAll(
          catalog.services.map(
            (item) => _ManagerServiceDraft(
              title: item.title,
              price: item.price == 0 ? '' : item.price.toStringAsFixed(0),
              remarks: item.remarks,
              // Slot duration is locked to 60 minutes for every service now,
              // regardless of what a service was previously saved with.
              slotMinutes: 60,
              supportsEvening: item.supportsEvening,
              supportsAfterMidnight: item.supportsAfterMidnight,
            ),
          ),
        );
    }

    if (_serviceDrafts.isEmpty) {
      _serviceDrafts.add(_ManagerServiceDraft());
    }

    _didPrefillCatalog = true;
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null || !mounted) return;
    setState(() => _selectedImage = image);
  }

  Future<void> _pickLocation() async {
    if (_selectedZone == null) {
      _showError('اختر المنطقة أولاً حتى تظهر لك حدودها على الخريطة.');
      return;
    }

    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerView(
          initialLatitude: double.tryParse(_latController.text),
          initialLongitude: double.tryParse(_longController.text),
          zone: _selectedZone,
        ),
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _latController.text = result.latitude.toStringAsFixed(6);
      _longController.text = result.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _selectZone(List<ZoneOption> zones) async {
    final zone = await showModalBottomSheet<ZoneOption>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.all(16.w),
            itemCount: zones.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = zones[index];
              return ListTile(
                title: Text(
                  item.name,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.font16Bold,
                ),
                trailing: _selectedZone?.id == item.id
                    ? Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, item),
              );
            },
          ),
        );
      },
    );

    if (zone == null || !mounted) return;
    final zoneChanged = _selectedZone?.id != zone.id;
    setState(() {
      _selectedZone = zone;
      // A location picked under the old zone may fall outside the new
      // zone's boundary, so make the manager re-pick it on the map.
      if (zoneChanged) {
        _latController.clear();
        _longController.clear();
      }
    });
  }

  void _submitBranch() {
    final branchName = _branchNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    final lat = _latController.text.trim();
    final long = _longController.text.trim();

    if (branchName.length < 3) {
      _showError('اكتب اسم الفرع بشكل صحيح.');
      return;
    }
    if (_selectedZone == null) {
      _showError('اختر المنطقة أولاً.');
      return;
    }
    if (phone.isEmpty) {
      _showError('اكتب رقم الهاتف.');
      return;
    }
    if (email.isNotEmpty && !email.contains('@')) {
      _showError('اكتب بريدًا إلكترونيًا صحيحًا، أو اترك الحقل فارغًا.');
      return;
    }
    if (address.isEmpty) {
      _showError('اكتب العنوان.');
      return;
    }

    context.read<ManagerSetupCubit>().saveBranchSetup(
          branchName: branchName,
          zoneId: _selectedZone!.id,
          phone: phone,
          email: email,
          address: address,
          lat: lat.isEmpty ? null : lat,
          long: long.isEmpty ? null : long,
          image: _selectedImage == null ? null : File(_selectedImage!.path),
        );
  }

  Future<void> _selectCategoryType(List<CategoryTypeOption> categoryTypes) async {
    if (categoryTypes.isEmpty) {
      _showError('لا توجد فئات متاحة حاليًا. تواصل مع الإدارة لإضافة فئات.');
      return;
    }

    final categoryType = await showModalBottomSheet<CategoryTypeOption>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.all(16.w),
            itemCount: categoryTypes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = categoryTypes[index];
              return ListTile(
                title: Text(
                  item.name,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.font16Bold,
                ),
                trailing: _selectedCategoryType?.id == item.id
                    ? Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, item),
              );
            },
          ),
        );
      },
    );

    if (categoryType == null || !mounted) return;
    setState(() => _selectedCategoryType = categoryType);
  }

  void _submitCatalog() {
    if (_selectedCategoryType == null) {
      _showError('اختر فئة الملعب أولاً.');
      return;
    }

    final services = <Map<String, dynamic>>[];

    for (final draft in _serviceDrafts) {
      final title = draft.titleController.text.trim();
      final priceText = draft.priceController.text.trim();
      final remarks = draft.remarksController.text.trim();

      if (title.isEmpty) {
        _showError('اكتب اسم كل خدمة أو ملعب.');
        return;
      }

      final price = double.tryParse(priceText);
      if (price == null || price < 0) {
        _showError('اكتب سعرًا صحيحًا لكل خدمة.');
        return;
      }

      if (!draft.supportsEvening && !draft.supportsAfterMidnight) {
        _showError(
            'كل خدمة يجب أن ترتبط بالمسائي أو بعد منتصف الليل أو بهما معًا.');
        return;
      }

      services.add({
        'title': title,
        'price': price,
        'slot_minutes': draft.slotMinutes,
        'remarks': remarks,
        'supports_evening': draft.supportsEvening,
        'supports_after_midnight': draft.supportsAfterMidnight,
      });
    }

    context.read<ManagerSetupCubit>().saveCatalogSetup(
          categoryTypeId: _selectedCategoryType!.id,
          services: services,
        );
  }

  void _addServiceDraft() {
    setState(() => _serviceDrafts.add(_ManagerServiceDraft()));
  }

  void _removeServiceDraft(int index) {
    if (_serviceDrafts.length == 1) return;
    final draft = _serviceDrafts.removeAt(index);
    draft.dispose();
    setState(() {});
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManagerSetupCubit, ManagerSetupState>(
      listener: (context, state) {
        if (state is ManagerSetupFailure) {
          _showError(state.message);
        }
        if (state is ManagerSetupSuccess) {
          showCustomSuccessToast(state.response.message);
          setState(() {
            _selectedImage = null;
            _isEditingBranch = false;
          });
        }
        if (state is ManagerCatalogSetupSuccess) {
          showCustomSuccessToast(state.response.message);
        }
        if (state is ManagerBookingPeriodsSuccess) {
          showCustomSuccessToast(state.response.message);
        }
      },
      builder: (context, state) {
        final bootstrap = switch (state) {
          final ManagerSetupLoaded s => s.response,
          final ManagerSetupSubmitting s => s.bootstrap,
          final ManagerSetupFailure s => s.bootstrap,
          final ManagerSetupSuccess s => s.bootstrap,
          final ManagerCatalogSetupSuccess s => s.bootstrap,
          final ManagerBookingPeriodsSuccess s => s.bootstrap,
          _ => null,
        };

        _prefillBranch(bootstrap);
        _prefillCatalog(bootstrap);

        final isLoading = state is ManagerSetupLoading;
        final isSubmitting = state is ManagerSetupSubmitting;
        final setup = bootstrap?.data.setup;
        final branch = setup?.branch;
        final canShowCatalog = branch != null;

        return PageWrapper(
          title: 'بيانات الملعب',
          child: isLoading && bootstrap == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntroCard(setup, bootstrap?.data.wallet),
                      HeightSpace(18.h),
                      if (bootstrap != null) ...[
                        _buildWalletCard(bootstrap.data.wallet),
                        HeightSpace(18.h),
                      ],
                      if (branch != null) ...[
                        _buildCurrentBranchCard(
                          branch,
                          onEdit: _isEditingBranch ? null : _startEditBranch,
                        ),
                        HeightSpace(18.h),
                      ],
                      if (_isEditingBranch) ...[
                        _buildImagePickerCard(branch?.imageUrl),
                        HeightSpace(18.h),
                        _buildBranchFormCard(
                          zones: bootstrap?.data.zones ?? const [],
                          isSubmitting: isSubmitting,
                          onCancel: branch == null
                              ? null
                              : () => _cancelEditBranch(branch),
                        ),
                      ],
                      if (canShowCatalog) ...[
                        HeightSpace(18.h),
                        _buildBookingPeriodsEntryCard(),
                        HeightSpace(18.h),
                        _buildCatalogSetupCard(
                          bootstrap: bootstrap,
                          isSubmitting: isSubmitting,
                        ),
                      ],
                      if (setup?.canStartBooking == true) ...[
                        HeightSpace(18.h),
                        _buildReadyCard(),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildIntroCard(SetupStatus? setup, WalletSummary? wallet) {
    final nextStep = setup?.nextStepLabel ?? 'إعداد بيانات شركة الملاعب';
    final stageTitle = switch (setup?.nextStepKey) {
      'branch' => 'المرحلة الحالية: بيانات شركة الملاعب',
      'category' ||
      'service' ||
      'employee' =>
        'المرحلة الحالية: الفئة والخدمات',
      'ready' => 'المرحلة الحالية: الحساب جاهز',
      _ => 'المرحلة الحالية: التهيئة',
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff0E2A1D), Color(0xff1E4B31)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99.r),
            ),
            child: Text(
              'لديك تجربة مجانية لمدة 30 يوم — لن يُخصم أي مبلغ حتى تنتهي',
              style: AppTextStyles.font12Bold.copyWith(color: Colors.white),
            ),
          ),
          HeightSpace(12.h),
          Text(
            stageTitle,
            style: AppTextStyles.font20Bold.copyWith(color: Colors.white),
          ),
          HeightSpace(8.h),
          Text(
            'مرحبًا بك! حتى يبدأ ملعبك في استقبال الحجوزات، اتبع هذه الخطوات بالترتيب:\n'
            '1) أدخل اسم الشركة المالكة للملاعب وبياناتها وصورة شعارها.\n'
            '2) أضف فئة الملاعب (مثال: كرة قدم) والخدمات/الملاعب التابعة لها.\n'
            '3) اربط كل خدمة بفترة الحجز المسائي أو بعد منتصف الليل.',
            style: AppTextStyles.font14Regular.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.6,
            ),
          ),
          HeightSpace(12.h),
          Text(
            'الخطوة التالية: $nextStep',
            style: AppTextStyles.font14Bold.copyWith(color: Colors.white),
          ),
          if (wallet != null) ...[
            HeightSpace(8.h),
            Text(
              'الرصيد الحالي: ${wallet.currentBalance.toStringAsFixed(2)} د.ل',
              style: AppTextStyles.font12Medium.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWalletCard(WalletSummary wallet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xffF7FBF6),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xffD7E8D3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primary,
              size: 22.sp,
            ),
          ),
          WidthSpace(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('محفظة مدير الملعب', style: AppTextStyles.font16Bold),
                HeightSpace(4.h),
                Text(
                  'الرصيد الحالي ${wallet.currentBalance.toStringAsFixed(2)} د.ل',
                  style: AppTextStyles.font14Medium,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => push(RoutesKeys.kManagerWallet, context),
            child: const Text('فتح المحفظة'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBranchCard(
    ExistingBranch branch, {
    required VoidCallback? onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xffE8ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'بيانات شركة الملاعب الحالية',
                  style: AppTextStyles.font16Bold,
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined,
                      size: 16.sp, color: AppColors.primary),
                  label: Text(
                    'تعديل',
                    style: AppTextStyles.font14Bold
                        .copyWith(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          HeightSpace(4.h),
          _buildReadOnlyRow('اسم الشركة', branch.name),
          _buildReadOnlyRow('المنطقة', branch.zoneName),
          _buildReadOnlyRow('الهاتف', branch.phone),
          _buildReadOnlyRow('البريد', branch.email),
          _buildReadOnlyRow('العنوان', branch.address),
        ],
      ),
    );
  }

  Widget _buildImagePickerCard(String? existingImageUrl) {
    final hasLocalImage = _selectedImage != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xffF6F9F3),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xffD9E8D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('شعار شركة الملاعب', style: AppTextStyles.font16Bold),
          HeightSpace(12.h),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: hasLocalImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18.r),
                      child: Image.file(
                        File(_selectedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    )
                  : existingImageUrl != null && existingImageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18.r),
                          child: Image.network(
                            existingImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          ),
                        )
                      : _buildImagePlaceholder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 38.sp,
          color: AppColors.primary,
        ),
        HeightSpace(10.h),
        Text(
          'اضغط لاختيار شعار الشركة',
          style: AppTextStyles.font14Bold.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildBranchFormCard({
    required List<ZoneOption> zones,
    required bool isSubmitting,
    VoidCallback? onCancel,
  }) {
    return _buildSectionCard(
      title: 'بيانات شركة الملاعب',
      subtitle:
          'هذه المرحلة تحفظ اسم الشركة المالكة للملاعب، المنطقة، الهاتف، العنوان، وموقع أول ملعب تابع لها.',
      child: Column(
        children: [
          _buildTextField(
            controller: _branchNameController,
            label: 'اسم الشركة المالكة للملاعب',
            hint: 'مثال: ملاعب الجزيرة',
          ),
          HeightSpace(12.h),
          _buildSelectField(
            label: 'المنطقة',
            value: _selectedZone?.name,
            onTap: () => _selectZone(zones),
          ),
          HeightSpace(12.h),
          _buildTextField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            keyboardType: TextInputType.phone,
          ),
          HeightSpace(12.h),
          _buildTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني (اختياري)',
            keyboardType: TextInputType.emailAddress,
          ),
          HeightSpace(4.h),
          Text(
            'بريد التواصل الخاص بالملعب/الشركة، ويمكن أن يختلف عن بريد الدخول لحسابك. اتركه فارغًا إذا لم يكن لديك بريد مختلف.',
            style: AppTextStyles.font12Medium.copyWith(
              color: const Color(0xff8A93A0),
            ),
          ),
          HeightSpace(12.h),
          _buildTextField(
            controller: _addressController,
            label: 'العنوان',
            maxLines: 2,
          ),
          HeightSpace(12.h),
          Text('موقع الملعب', style: AppTextStyles.font14Bold),
          HeightSpace(8.h),
          InkWell(
            onTap: _pickLocation,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: const Color(0xffFAFBFC),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xffD7DDE3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.map_outlined, color: AppColors.primary, size: 20.sp),
                  WidthSpace(10.w),
                  Expanded(
                    child: Text(
                      _latController.text.isNotEmpty &&
                              _longController.text.isNotEmpty
                          ? '${_latController.text}, ${_longController.text}'
                          : 'اضغط لتحديد موقع الملعب على الخريطة',
                      style: AppTextStyles.font14Medium.copyWith(
                        color: _latController.text.isNotEmpty
                            ? AppColors.fontColor
                            : const Color(0xff8A93A0),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_left, color: const Color(0xff8A93A0)),
                ],
              ),
            ),
          ),
          HeightSpace(16.h),
          ButtonApp(
            text: isSubmitting ? 'جارٍ الحفظ...' : 'حفظ بيانات الشركة',
            onTap: isSubmitting ? null : _submitBranch,
          ),
          if (onCancel != null) ...[
            HeightSpace(8.h),
            TextButton(
              onPressed: isSubmitting ? null : onCancel,
              child: Text(
                'إلغاء',
                style: AppTextStyles.font14Bold.copyWith(
                  color: const Color(0xff8A93A0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCatalogSetupCard({
    required ManagerSetupBootstrapResponse? bootstrap,
    required bool isSubmitting,
  }) {
    final catalog = bootstrap?.data.catalog;
    final categoryTypes = bootstrap?.data.categoryTypes ?? const [];

    return _buildSectionCard(
      title: 'الفئة والخدمات والجداول الزمنية',
      subtitle:
          'اختر فئة الملعب من القائمة (مثل كرة قدم)، ثم أضف الخدمات مثل سداسي أو سباعي أو ملعب 1، ثم اربط كل خدمة بالمسائي أو بعد منتصف الليل. الفئات تُدار من لوحة الإدارة فقط.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (catalog != null && catalog.employees.isNotEmpty) ...[
            _buildEmployeeChannelsPreview(catalog.employees),
            HeightSpace(14.h),
          ],
          _buildSelectField(
            label: 'فئة الملعب',
            value: _selectedCategoryType?.name,
            onTap: () => _selectCategoryType(categoryTypes),
          ),
          HeightSpace(16.h),
          Text('الخدمات أو الملاعب', style: AppTextStyles.font16Bold),
          HeightSpace(8.h),
          ...List.generate(
            _serviceDrafts.length,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: _buildServiceDraftCard(index, _serviceDrafts[index]),
            ),
          ),
          TextButton.icon(
            onPressed: _addServiceDraft,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('إضافة خدمة أخرى'),
          ),
          HeightSpace(12.h),
          ButtonApp(
            text: isSubmitting ? 'جارٍ الحفظ...' : 'حفظ الفئة والخدمات',
            onTap: isSubmitting ? null : _submitCatalog,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingPeriodsEntryCard() {
    return _buildSectionCard(
      title: 'فترات الحجز',
      subtitle:
          'هذه المرحلة مستقلة. منها تضيف أو تعدل الحجز المسائي والحجز بعد منتصف الليل مع ساعات كل فترة.',
      child: ButtonApp(
        text: 'فتح إدارة فترات الحجز',
        onTap: () => push(RoutesKeys.kManagerBookingPeriods, context),
      ),
    );
  }

  Widget _buildServiceDraftCard(int index, _ManagerServiceDraft draft) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xffFBFCFB),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xffE5ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('الخدمة ${index + 1}', style: AppTextStyles.font16Bold),
              const Spacer(),
              if (_serviceDrafts.length > 1)
                IconButton(
                  onPressed: () => _removeServiceDraft(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
            ],
          ),
          _buildTextField(
            controller: draft.titleController,
            label: 'اسم الخدمة أو الملعب',
            hint: 'مثال: سداسي 1 أو ملعب سباعي',
          ),
          HeightSpace(12.h),
          _buildTextField(
            controller: draft.priceController,
            label: 'السعر',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          HeightSpace(12.h),
          _buildTextField(
            controller: draft.remarksController,
            label: 'وصف مختصر',
            hint: 'اختياري',
            maxLines: 2,
          ),
          HeightSpace(12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _buildAvailabilityChip(
                label: 'المسائي',
                value: draft.supportsEvening,
                onTap: () => setState(
                  () => draft.supportsEvening = !draft.supportsEvening,
                ),
              ),
              _buildAvailabilityChip(
                label: 'بعد منتصف الليل',
                value: draft.supportsAfterMidnight,
                onTap: () => setState(
                  () => draft.supportsAfterMidnight =
                      !draft.supportsAfterMidnight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityChip({
    required String label,
    required bool value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: value
              ? AppColors.primary.withValues(alpha: 0.10)
              : const Color(0xffF2F4F7),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: value ? AppColors.primary : const Color(0xffD8DEE5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              color: value ? AppColors.primary : Colors.grey,
              size: 18.sp,
            ),
            WidthSpace(8.w),
            Text(
              label,
              style: AppTextStyles.font14Bold.copyWith(
                color: value ? AppColors.primary : AppColors.fontColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeChannelsPreview(List<SetupEmployeeItem> employees) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xffF7FBF6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xffD7E8D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('القنوات الزمنية الحالية', style: AppTextStyles.font16Bold),
          HeightSpace(8.h),
          ...employees.map(
            (employee) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Text(
                '• ${employee.fullName}',
                style: AppTextStyles.font14Medium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xffEEF8F0),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xffCBE5D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الحساب أصبح جاهزًا للحجز', style: AppTextStyles.font16Bold),
          HeightSpace(8.h),
          Text(
            'تم تجهيز الفرع والفئة والخدمات وربطها بقنوات الحجز. يمكنك الآن الرجوع للشاشة الرئيسية وبدء التجربة.',
            style: AppTextStyles.font14Medium.copyWith(height: 1.5),
          ),
          HeightSpace(14.h),
          ButtonApp(
            text: 'الرجوع للرئيسية',
            onTap: () => pushReplacement(RoutesKeys.kHome, context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xffE8ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.font18Bold),
          HeightSpace(8.h),
          Text(
            subtitle,
            style: AppTextStyles.font14Regular.copyWith(
              color: const Color(0xff6D7580),
              height: 1.5,
            ),
          ),
          HeightSpace(16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: RichText(
        text: TextSpan(
          style:
              AppTextStyles.font14Medium.copyWith(color: AppColors.fontColor),
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTextStyles.font14Bold.copyWith(
                color: AppColors.black,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.font14Bold),
        HeightSpace(8.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xffFAFBFC),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Color(0xffD7DDE3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Color(0xffD7DDE3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectField({
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.font14Bold),
        HeightSpace(8.h),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: const Color(0xffFAFBFC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xffD7DDE3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'اختر الفئة ',
                    style: AppTextStyles.font14Medium.copyWith(
                      color: value == null
                          ? const Color(0xff8A93A0)
                          : AppColors.fontColor,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ManagerServiceDraft {
  _ManagerServiceDraft({
    String title = '',
    String price = '',
    String remarks = '',
    this.slotMinutes = 60,
    this.supportsEvening = true,
    this.supportsAfterMidnight = false,
  })  : titleController = TextEditingController(text: title),
        priceController = TextEditingController(text: price),
        remarksController = TextEditingController(text: remarks);

  final TextEditingController titleController;
  final TextEditingController priceController;
  final TextEditingController remarksController;
  int slotMinutes;
  bool supportsEvening;
  bool supportsAfterMidnight;

  void dispose() {
    titleController.dispose();
    priceController.dispose();
    remarksController.dispose();
  }
}
