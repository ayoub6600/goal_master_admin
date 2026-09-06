import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/booking_periods_card.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/branch_form_card.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/branch_summary_card.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/catalog_setup_card.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/manager_service_draft.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_fields.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_hero_card.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_ready_card.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_wallet_card.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/venue_logo_picker.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/location_picker_view.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/profile_cubit/profile_cubit.dart';
import 'package:image_picker/image_picker.dart';

/// Venue-setup screen: owns the form state and the save calls, and lays the
/// stage cards out in the order the manager works through them.
///
/// Every card is its own widget under `add_first_venue/` — this file stays
/// about *what happens*, not about how any one card looks.
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
  final List<ManagerServiceDraft> _serviceDrafts = [];

  @override
  void initState() {
    super.initState();
    if (_serviceDrafts.isEmpty) {
      _serviceDrafts.add(ManagerServiceDraft());
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
            (item) => ManagerServiceDraft(
              title: item.title,
              price: item.price == 0 ? '' : item.price.toStringAsFixed(0),
              remarks: item.remarks,
              // Slot duration is locked to 60 minutes for every service now,
              // regardless of what a service was previously saved with.
              slotMinutes: 60,
              supportsEvening: item.supportsEvening,
              supportsAfterMidnight: item.supportsAfterMidnight,
              isNew: false,
            ),
          ),
        );
    }

    if (_serviceDrafts.isEmpty) {
      _serviceDrafts.add(ManagerServiceDraft());
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
    final zone = await showSetupOptionSheet<ZoneOption>(
      context: context,
      title: 'اختر المنطقة',
      options: zones,
      labelOf: (option) => option.name,
      isSelected: (option) => _selectedZone?.id == option.id,
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

  Future<void> _selectCategoryType(
    List<CategoryTypeOption> categoryTypes,
  ) async {
    if (categoryTypes.isEmpty) {
      _showError('لا توجد فئات متاحة حاليًا. تواصل مع الإدارة لإضافة فئات.');
      return;
    }

    final categoryType = await showSetupOptionSheet<CategoryTypeOption>(
      context: context,
      title: 'اختر فئة الملعب',
      options: categoryTypes,
      labelOf: (option) => option.name,
      isSelected: (option) => _selectedCategoryType?.id == option.id,
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

      services.add({
        'title': title,
        'price': price,
        'slot_minutes': draft.slotMinutes,
        'remarks': remarks,
        // Derived, not asked.
        //
        // An existing pitch keeps exactly the bands it already had: the server
        // deactivates any pitch missing from a band's list, so sending "both"
        // for everything would widen a pitch that was only ever available in
        // the evening.
        //
        // A pitch being added for the first time becomes available whenever
        // the venue is open — every band that is currently switched on. It is
        // deliberately NOT added to a disabled after-midnight band: the same
        // save would re-create that band as enabled, quietly reopening hours
        // the venue had closed.
        'supports_evening': draft.isNew ? true : draft.supportsEvening,
        'supports_after_midnight': draft.isNew
            ? _afterMidnightBandEnabled
            : draft.supportsAfterMidnight,
      });
    }

    context.read<ManagerSetupCubit>().saveCatalogSetup(
          categoryTypeId: _selectedCategoryType!.id,
          services: services,
        );
  }

  /// Whether the venue's after-midnight band is switched on right now.
  ///
  /// Read from the same record «فترات الحجز» writes, so a new pitch inherits
  /// the hours the venue actually keeps rather than a hardcoded assumption.
  bool get _afterMidnightBandEnabled {
    final employees = context
            .read<ManagerSetupCubit>()
            .bootstrapResponse
            ?.data
            .catalog
            .employees ??
        const [];

    for (final e in employees) {
      if (e.isAfterMidnightChannel) return e.status != 0;
    }

    return false;
  }

  void _addServiceDraft() {
    setState(() => _serviceDrafts.add(ManagerServiceDraft()));
  }

  void _removeServiceDraft(int index) {
    if (_serviceDrafts.length == 1) return;
    final draft = _serviceDrafts.removeAt(index);
    draft.dispose();
    setState(() {});
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
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
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SetupHeroCard(setup: setup),
                      HeightSpace(16.h),
                      if (bootstrap != null) ...[
                        SetupWalletCard(
                          wallet: bootstrap.data.wallet,
                          onOpen: () =>
                              push(RoutesKeys.kManagerWallet, context),
                        ),
                        HeightSpace(16.h),
                      ],
                      if (branch != null) ...[
                        BranchSummaryCard(
                          branch: branch,
                          onEdit: _isEditingBranch ? null : _startEditBranch,
                        ),
                        HeightSpace(16.h),
                      ],
                      if (_isEditingBranch) ...[
                        VenueLogoPicker(
                          selectedImage: _selectedImage,
                          existingImageUrl: branch?.imageUrl,
                          onPick: _pickImage,
                        ),
                        HeightSpace(16.h),
                        BranchFormCard(
                          branchNameController: _branchNameController,
                          phoneController: _phoneController,
                          emailController: _emailController,
                          addressController: _addressController,
                          selectedZoneName: _selectedZone?.name,
                          latitude: _latController.text,
                          longitude: _longController.text,
                          isSubmitting: isSubmitting,
                          isDone: setup?.hasBranchProfile ?? false,
                          onSelectZone: () =>
                              _selectZone(bootstrap?.data.zones ?? const []),
                          onPickLocation: _pickLocation,
                          onSubmit: _submitBranch,
                          onCancel: branch == null
                              ? null
                              : () => _cancelEditBranch(branch),
                        ),
                      ],
                      if (canShowCatalog) ...[
                        HeightSpace(16.h),
                        CatalogSetupCard(
                          selectedCategoryName: _selectedCategoryType?.name,
                          channelNames: bootstrap?.data.catalog.employees
                                  .map((employee) => employee.fullName)
                                  .toList() ??
                              const [],
                          drafts: _serviceDrafts,
                          isSubmitting: isSubmitting,
                          isDone: (setup?.hasCategorySetup ?? false) &&
                              (setup?.hasServiceSetup ?? false),
                          onSelectCategory: () => _selectCategoryType(
                            bootstrap?.data.categoryTypes ?? const [],
                          ),
                          onAddService: _addServiceDraft,
                          onRemoveService: _removeServiceDraft,
                          onSubmit: _submitCatalog,
                        ),
                        HeightSpace(16.h),
                        BookingPeriodsCard(
                          isDone: setup?.hasEmployeeSetup ?? false,
                          onOpen: () =>
                              push(RoutesKeys.kManagerBookingPeriods, context),
                        ),
                      ],
                      if (setup?.canStartBooking == true) ...[
                        HeightSpace(16.h),
                        SetupReadyCard(
                          onGoHome: () =>
                              pushReplacement(RoutesKeys.kHome, context),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
