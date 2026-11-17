import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_cubit/booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/employee_cubit/employee_cubit.dart';
import 'package:goal_master_admin/core/components/skeletons.dart';

class EmployeeDropdownSelection extends StatefulWidget {
  final BuildContext cubitContext;

  const EmployeeDropdownSelection({Key? key, required this.cubitContext})
      : super(key: key);

  @override
  State<EmployeeDropdownSelection> createState() =>
      _EmployeeDropdownSelectionState();
}

class _EmployeeDropdownSelectionState extends State<EmployeeDropdownSelection> {
  int? selectedEmployeeId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeCubit, EmployeeState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state is EmployeeSuccess)
              DropdownButtonFormField<int>(
                value: selectedEmployeeId,
                decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  labelText: 'اختر الموظف',
                ),
                items: state.employees.map((emp) {
                  return DropdownMenuItem<int>(
                    value: emp.id,
                    child: Text(emp.fullName ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEmployeeId = value;
                    widget.cubitContext
                        .read<BookingCubit>()
                        .updateEmployeeId(value!.toString());
                  });
                },
              ),
            if (state is EmployeeLoading)
              const Skeleton(child: Wrap(spacing: 10, runSpacing: 10, children: [SkeletonBox(width: 90, height: 38, radius: 19), SkeletonBox(width: 110, height: 38, radius: 19), SkeletonBox(width: 80, height: 38, radius: 19)])),
            if (state is EmployeeFailure) Text('خطأ: ${state.message}'),
          ],
        );
      },
    );
  }
}
