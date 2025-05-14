import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_cubit/booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/employee_cubit/employee_cubit.dart';

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
              const Center(child: CircularProgressIndicator()),
            if (state is EmployeeFailure) Text('خطأ: ${state.message}'),
          ],
        );
      },
    );
  }
}
