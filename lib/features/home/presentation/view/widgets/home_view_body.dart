import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_drop_down.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/arabic_bar_chart.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/status_tabs_home.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      allowBack: false,
      title: "لوحة التحكم",
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
              HeightSpace(20),
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.28,
                decoration: BoxDecoration(
                  color: Color(0xfff0faf1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    StatusTabsHome(),
                  ],
                ),
              ),
              HeightSpace(20),
              Text(
                "إحصائيات الدخل اليومي والإحصائيات الأخرى",
                style: AppTextStyles.font18Bold.copyWith(
                  color: AppColors.black,
                ),
              ),
              HeightSpace(20),
              ArabicBarChart(),
              HeightSpace(20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                // height: MediaQuery.of(context).size.height * 0.28,
                decoration: BoxDecoration(
                  color: Color(0xfff0faf1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "أفضل خدمات الحجز",
                      style: AppTextStyles.font18Bold.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    Divider(
                      thickness: 1,
                      color: AppColors.lightGrey,
                    ),
                    HeightSpace(20),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary,
                        ),
                        WidthSpace(20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ملعب سداسي",
                                style: AppTextStyles.font16Medium.copyWith(),
                              ),
                              HeightSpace(4),
                              Text(
                                "أفضل خدماتنا",
                                style: AppTextStyles.font16Medium.copyWith(
                                  color: AppColors.lightGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "7",
                          style: AppTextStyles.font16Medium.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              HeightSpace(20),
            ],
          ),
        ),
      ),
    );
  }
}
