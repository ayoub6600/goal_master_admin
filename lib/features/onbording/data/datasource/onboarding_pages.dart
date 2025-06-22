import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/features/onbording/data/model/onboarding_model.dart';

class OnboardingPages {
  static List<OnboardingModel> getPages(BuildContext context) {
    return [
      OnboardingModel(
        title: "إدارة الملاعب والأسعار",
        subtitle: "تابع أحدث العروض والخصومات، وقم بتحديث الأسعار بكل سهولة.",
        imageIndex: 0,
        images: Assets.imagesPngImageOn2,
      ),
      OnboardingModel(
        title: "سهولة إدارة الحجوزات",
        subtitle:
            "تحكّم في جميع الحجوزات، عدّل المواعيد والتفاصيل بنقرة زر واحدة.",
        imageIndex: 1,
        images: Assets.imagesPngImage1,
      ),
      OnboardingModel(
        title: "متابعة الفِرق والبطولات",
        subtitle: "راقب نشاطات الفِرق، وأدِر البطولات والتحديات بكل احترافية.",
        imageIndex: 2,
        images: Assets.imagesPngImageOn3,
      ),
    ];
  }
}
