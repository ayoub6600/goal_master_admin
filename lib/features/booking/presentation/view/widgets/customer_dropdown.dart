import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/customer_cubit/customer_cubit.dart';
import 'package:searchable_paginated_dropdown/searchable_paginated_dropdown.dart';

class CustomerDropdownWidget extends StatelessWidget {
  const CustomerDropdownWidget({Key? key, required this.onCustomerSelected})
      : super(key: key);

  final void Function(Customer customer) onCustomerSelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, state) {
        if (state is CustomerLoaded) {
          return SearchableDropdown<Customer>.paginated(
            backgroundDecoration: (child) => Container(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey),
              ),
              child: Padding(padding: const EdgeInsets.all(8.0), child: child),
            ),
            hintText: const Text('اختر عميل'),
            requestItemCount: 10, // عدد العملاء في كل "صفحة"

            paginatedRequest: (int page, String? searchKey) async {
              final cubit = context.read<CustomerCubit>();

              final result = await cubit.fetchCustomersForDropdown(
                page: page,
                search: searchKey,
              );

              return result.fold(
                (failure) => throw Exception(failure.errMessage),
                (customers) {
                  return customers.map((customer) {
                    return SearchableDropdownMenuItem<Customer>(
                      value: customer,
                      label: customer.fullName ?? '',
                      child: Row(
                        children: [
                          Expanded(child: Text(customer.fullName ?? '')),
                          const SizedBox(width: 8),
                          Text(customer.phoneNo ?? ''),
                        ],
                      ),
                    );
                  }).toList();
                },
              );
            },
            onChanged: (Customer? selectedCustomer) {
              if (selectedCustomer != null) {
                onCustomerSelected(selectedCustomer);
                debugPrint('✅ تم اختيار العميل: ${selectedCustomer.id}');
              }
            },
          );
        }

        if (state is CustomerLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CustomerError) {
          return Center(child: Text('حدث خطأ: ${state.message}'));
        }

        return const SizedBox.shrink();
      },
    );
  }
}
