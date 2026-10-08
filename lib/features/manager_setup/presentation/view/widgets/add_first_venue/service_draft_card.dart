import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/manager_service_draft.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_fields.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_theme.dart';
import 'package:image_picker/image_picker.dart';

/// One pitch/service being added or edited inside the catalog form.
///
/// Every pitch owns its own image gallery.
///
/// Existing server images are kept in [ManagerServiceDraft.existingImages].
/// Newly picked images are kept in [ManagerServiceDraft.newImages].
///
/// Actual upload/deletion is performed later by the catalog save flow.
class ServiceDraftCard extends StatefulWidget {
  const ServiceDraftCard({
    super.key,
    required this.index,
    required this.draft,
    required this.onRemove,
  });

  final int index;
  final ManagerServiceDraft draft;

  /// Null when this is the only draft left — the form always keeps one.
  final VoidCallback? onRemove;

  @override
  State<ServiceDraftCard> createState() => _ServiceDraftCardState();
}

class _ServiceDraftCardState extends State<ServiceDraftCard> {
  static const int _maxImages = 10;

  bool _isPickingImages = false;

  ManagerServiceDraft get draft => widget.draft;

  Future<void> _pickImages() async {
    if (_isPickingImages) return;

    final remaining = _maxImages - draft.totalVisibleImages;

    if (remaining <= 0) {
      _showMessage('يمكن إضافة $_maxImages صور كحد أقصى لكل ملعب.');
      return;
    }

    setState(() => _isPickingImages = true);

    try {
      final images = await ImagePicker().pickMultiImage(
        imageQuality: 80,
      );

      if (!mounted || images.isEmpty) return;

      final acceptedImages = images.take(remaining).toList();

      setState(() {
        draft.addNewImages(acceptedImages);
      });

      if (images.length > remaining && mounted) {
        _showMessage(
          'تم اختيار أول $remaining صور فقط. الحد الأقصى $_maxImages صور لكل ملعب.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('تعذر اختيار الصور. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  void _removeExistingImage(int mediaId) {
    setState(() {
      draft.markExistingImageForRemoval(mediaId);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      draft.removeNewImageAt(index);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final existingImages = draft.visibleExistingImages;
    final newImages = draft.newImages;
    final canAddMoreImages = draft.totalVisibleImages < _maxImages;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xffFBFCFB),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: const Color(0xffE5ECE6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            children: [
              Container(
                width: 26.w,
                height: 26.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Text(
                  '${widget.index + 1}',
                  style: AppTextStyles.font12Bold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              WidthSpace(10.w),
              Expanded(
                child: Text(
                  'الملعب',
                  style: AppTextStyles.font16Bold,
                ),
              ),
              if (widget.onRemove != null)
                IconButton(
                  onPressed: widget.onRemove,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'حذف الملعب',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.errorRed,
                    size: 21.sp,
                  ),
                ),
            ],
          ),

          HeightSpace(12.h),

          SetupTextField(
            controller: draft.titleController,
            label: 'اسم الملعب',
            hint: 'مثال: ملعب رقم 1',
          ),

          HeightSpace(12.h),

          SetupTextField(
            controller: draft.priceController,
            label: 'السعر بالدينار',
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),

          HeightSpace(12.h),

          SetupTextField(
            controller: draft.remarksController,
            label: 'وصف مختصر',
            hint: 'اختياري',
            maxLines: 2,
          ),

          HeightSpace(18.h),

          /// Gallery title
          Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 19.sp,
                color: AppColors.primary,
              ),
              WidthSpace(8.w),
              Expanded(
                child: Text(
                  'صور الملعب',
                  style: AppTextStyles.font14Bold,
                ),
              ),
              Text(
                '${draft.totalVisibleImages}/$_maxImages',
                style: AppTextStyles.font12Medium.copyWith(
                  color: SetupColors.secondaryText,
                ),
              ),
            ],
          ),

          HeightSpace(6.h),

          Text(
            'أضف صورًا واضحة للملعب ليشاهدها الزبون أثناء الحجز.',
            style: AppTextStyles.font12Medium.copyWith(
              color: SetupColors.secondaryText,
            ),
          ),

          HeightSpace(12.h),

          /// Images
          if (existingImages.isNotEmpty || newImages.isNotEmpty)
            SizedBox(
              height: 105.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  for (final image in existingImages)
                    _ExistingImageTile(
                      url: image.url,
                      onRemove: () => _removeExistingImage(image.id),
                    ),
                  for (int index = 0; index < newImages.length; index++)
                    _LocalImageTile(
                      file: File(newImages[index].path),
                      onRemove: () => _removeNewImage(index),
                    ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 18.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: const Color(0xffE5ECE6),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 30.sp,
                    color: SetupColors.secondaryText,
                  ),
                  HeightSpace(7.h),
                  Text(
                    'لم تتم إضافة صور لهذا الملعب بعد',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font12Medium.copyWith(
                      color: SetupColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

          HeightSpace(12.h),

          /// Add images button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canAddMoreImages && !_isPickingImages
                  ? _pickImages
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: canAddMoreImages
                      ? AppColors.primary.withValues(alpha: 0.45)
                      : const Color(0xffD9DFDA),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13.r),
                ),
              ),
              icon: _isPickingImages
                  ? SizedBox(
                      width: 17.w,
                      height: 17.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 20.sp,
                    ),
              label: Text(
                canAddMoreImages
                    ? 'إضافة صور الملعب'
                    : 'تم الوصول للحد الأقصى للصور',
                style: AppTextStyles.font14Bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExistingImageTile extends StatelessWidget {
  const _ExistingImageTile({
    required this.url,
    required this.onRemove,
  });

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _GalleryTile(
      onRemove: onRemove,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) return child;

          return Center(
            child: SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.grey,
              size: 28.sp,
            ),
          );
        },
      ),
    );
  }
}

class _LocalImageTile extends StatelessWidget {
  const _LocalImageTile({
    required this.file,
    required this.onRemove,
  });

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _GalleryTile(
      onRemove: onRemove,
      child: Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.grey,
              size: 28.sp,
            ),
          );
        },
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.child,
    required this.onRemove,
  });

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112.w,
      margin: EdgeInsetsDirectional.only(end: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(
          color: const Color(0xffE5ECE6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          PositionedDirectional(
            top: 5.h,
            end: 5.w,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(50.r),
              child: Container(
                width: 28.w,
                height: 28.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 17.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The time channels the venue currently runs, shown for context above the
/// catalog form.
class EmployeeChannelsPreview extends StatelessWidget {
  const EmployeeChannelsPreview({
    super.key,
    required this.channelNames,
  });

  final List<String> channelNames;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: SetupColors.tintedSurface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: SetupColors.doneBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 17.sp,
                color: AppColors.primary,
              ),
              WidthSpace(8.w),
              Text(
                'القنوات الزمنية الحالية',
                style: AppTextStyles.font14Bold,
              ),
            ],
          ),
          HeightSpace(10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final name in channelNames)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99.r),
                    border: Border.all(
                      color: SetupColors.doneBorder,
                    ),
                  ),
                  child: Text(
                    name,
                    style: AppTextStyles.font12Medium.copyWith(
                      color: SetupColors.secondaryText,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
