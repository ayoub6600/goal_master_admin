import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_drop_down.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeViewBody();
  }
}

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      allowBack: false,
      title: "لوحة التحكم",
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeightSpace(20),
            CustomTextField(
              hint: "ابحث",
              inputType: TextInputType.text,
              trailing: const Icon(Icons.search),
            ),
            HeightSpace(20),
            ButtonApp(text: "اضافة حجز جديد", onTap: () {}),
            HeightSpace(20),
            Text(
              "احصائيات الخدمات ",
              style: AppTextStyles.font18Bold.copyWith(
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Text(
                "عرض جميع إحصائيات الخدمة بناءً على إذن فرع المستخدم.",
                style: AppTextStyles.font16Medium.copyWith(
                  color: AppColors.lightGrey,
                ),
              ),
            ),
            HeightSpace(20),
            Row(
              children: [
                Expanded(
                  child: CustomDropdown(
                    label: "اختر الفترة الزمنية",
                    hint: "اختر الفترة ",
                    items: ["ملعب 1", "ملعب 2", "ملعب 3", "ملعب 4"],
                    onChanged: (value) {
                      // cubit.changeSelectedBrand(value!);
                      // cubit.getBrandTypes();
                    },
                  ),
                ),
                WidthSpace(20),
                Expanded(
                  child: CustomDropdown(
                    label: "ادارة الملعب",
                    hint: "اختر الادارة ",
                    items: ["ملعب 1", "ملعب 2", "ملعب 3", "ملعب 4"],
                    onChanged: (value) {
                      // cubit.changeSelectedBrand(value!);
                      // cubit.getBrandTypes();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
