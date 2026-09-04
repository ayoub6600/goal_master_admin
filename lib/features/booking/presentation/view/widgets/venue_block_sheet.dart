import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';

/// What the manager picked: a reason, and an optional private note.
class VenueBlockDecision {
  const VenueBlockDecision({required this.reasonCode, this.note});

  final String reasonCode;
  final String? note;
}

const _venueBlockReasons = {
  'repeated_disputes': 'نزاعات متكررة',
  'repeated_no_show': 'عدم الحضور المتكرر',
  'unpaid_amounts': 'مبالغ غير مسددة',
  'inappropriate_behavior': 'سلوك غير مناسب',
  'other': 'سبب آخر',
};

/// "حظر الزبون" — reason required, note optional, warns before anything is
/// sent. The reason and note stay private to the venue; only the fact of
/// being blocked ever reaches the Customer App.
class VenueBlockSheet extends StatefulWidget {
  const VenueBlockSheet({super.key});

  static Future<VenueBlockDecision?> show(BuildContext context) {
    return showModalBottomSheet<VenueBlockDecision>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => const VenueBlockSheet(),
    );
  }

  @override
  State<VenueBlockSheet> createState() => _VenueBlockSheetState();
}

class _VenueBlockSheetState extends State<VenueBlockSheet> {
  String? _reasonCode;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 12.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xffD7DDE3),
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
          ),
          HeightSpace(16.h),
          Text('حظر الزبون', style: AppTextStyles.font18Bold),
          HeightSpace(10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.dangerLight1,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              'لن يتمكن هذا الزبون من إنشاء حجوزات جديدة مع هذا الملعب.',
              style: AppTextStyles.font12Bold.copyWith(color: AppColors.redcolor),
            ),
          ),
          HeightSpace(16.h),
          Text('السبب', style: AppTextStyles.font14Bold),
          HeightSpace(8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _venueBlockReasons.entries.map((e) {
              final selected = _reasonCode == e.key;
              return InkWell(
                onTap: () => setState(() => _reasonCode = e.key),
                borderRadius: BorderRadius.circular(99.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.redcolor.withValues(alpha: 0.1)
                        : const Color(0xffFAFBFC),
                    borderRadius: BorderRadius.circular(99.r),
                    border: Border.all(
                      color: selected ? AppColors.redcolor : const Color(0xffD7DDE3),
                    ),
                  ),
                  child: Text(
                    e.value,
                    style: AppTextStyles.font12Bold.copyWith(
                      color: selected ? AppColors.redcolor : AppColors.fontColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          HeightSpace(16.h),
          Text('ملاحظة (اختياري، خاصة بالملعب فقط)', style: AppTextStyles.font14Bold),
          HeightSpace(8.h),
          TextField(
            controller: _noteController,
            maxLines: 3,
            style: AppTextStyles.font12Regular,
            decoration: InputDecoration(
              hintText: 'لن يراها الزبون...',
              filled: true,
              fillColor: const Color(0xffFAFBFC),
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xffD7DDE3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xffD7DDE3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.redcolor, width: 1.4),
              ),
            ),
          ),
          HeightSpace(20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.redcolor,
                disabledBackgroundColor: const Color(0xffD7DDE3),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              onPressed: _reasonCode == null
                  ? null
                  : () => Navigator.of(context).pop(
                        VenueBlockDecision(
                          reasonCode: _reasonCode!,
                          note: _noteController.text.trim().isEmpty
                              ? null
                              : _noteController.text.trim(),
                        ),
                      ),
              child: Text(
                'تأكيد الحظر',
                style: AppTextStyles.font16Bold.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "إلغاء الحظر" — a plain yes/no, no reason needed to lift a block.
class VenueUnblockConfirmSheet extends StatelessWidget {
  const VenueUnblockConfirmSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => const VenueUnblockConfirmSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 12.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xffD7DDE3),
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
          ),
          HeightSpace(16.h),
          Text('إلغاء الحظر', style: AppTextStyles.font18Bold),
          HeightSpace(8.h),
          Text(
            'سيتمكن هذا الزبون من إنشاء حجوزات جديدة مع هذا الملعب مرة أخرى.',
            style: AppTextStyles.font12Regular.copyWith(color: AppColors.fontColor),
          ),
          HeightSpace(20.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text('تراجع', style: AppTextStyles.font14Bold),
                ),
              ),
              WidthSpace(12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'تأكيد',
                    style: AppTextStyles.font14Bold.copyWith(color: Colors.white),
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
