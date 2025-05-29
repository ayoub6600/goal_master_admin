import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_details.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/%20booking_details_cubit/booking_details_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_deposit_cubit/booking_deposit_cubit.dart';

class DepositBookingButton extends StatelessWidget {
  final BookingDetails bookingDetails;

  const DepositBookingButton({super.key, required this.bookingDetails});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingDepositCubit, BookingDepositState>(
      listener: (context, state) {
        if (state is BookingDepositSuccess) {
          showCustomSuccessToast("تم الدفع بنجاح");
          context.read<BookingDetailsCubit>().getBookingInfo();
          Navigator.pop(context);
        } else if (state is BookingDepositError) {
          CustomFailureToastWidget(toastText: state.message);
        }
      },
      builder: (context, state) {
        return Expanded(
          child: ButtonApp(
            text: state is BookingDepositLoading
                ? "جاري ايداع الدفع"
                : "ايداع دفعة",
            textColor: Colors.white,
            onTap: () {
              baseBottomSheet(
                title: "ايداع دفعة",
                context: context,
                child: BlocProvider(
                  create: (context) => BookingDepositCubit(
                    bookingRepo: getIt<BookingRepoImp>(),
                    bookingDetails.id,
                  ),
                  child: DepositBookingPaymentWidget(
                      bookingDetails: bookingDetails),
                ),
                hideNavBar: false,
              );
            },
          ),
        );
      },
    );
  }
}

class DepositBookingPaymentWidget extends StatefulWidget {
  final BookingDetails bookingDetails;

  const DepositBookingPaymentWidget({super.key, required this.bookingDetails});

  @override
  State<DepositBookingPaymentWidget> createState() =>
      _DepositBookingPaymentWidgetState();
}

class _DepositBookingPaymentWidgetState
    extends State<DepositBookingPaymentWidget> {
  final TextEditingController dueController = TextEditingController();
  final TextEditingController extraInputController = TextEditingController();

  int selectedToleranceType = 1;

  @override
  void initState() {
    super.initState();
    dueController.text = widget.bookingDetails.paidAmount;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingDepositCubit, BookingDepositState>(
      listener: (context, state) {
        if (state is BookingDepositLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        } else if (state is BookingDepositSuccess) {
          Navigator.of(context).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم الدفع بنجاح')),
          );
          Navigator.of(context).pop(); // Close deposit screen
        } else if (state is BookingDepositError) {
          Navigator.of(context).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: ${state.message}')),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: dueController,
            inputType: TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: selectedToleranceType,
            items: const [
              DropdownMenuItem(value: 1, child: Text(' ايداع مبلغ ')),
              DropdownMenuItem(value: 0, child: Text('مسامحة ')),
            ],
            onChanged: (value) {
              setState(() {
                selectedToleranceType = value ?? 1;
              });
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          HeightSpace(16),
          if (selectedToleranceType == 0) ...[
            const Text("ادخل قيمة المسامحة"),
            const SizedBox(height: 8),
            CustomTextField(
              hint: "ادخل قيمة المسامحة",
              controller: extraInputController,
              inputType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
          ],
          ButtonApp(
            text: "ايداع دفعة",
            textColor: Colors.white,
            onTap: () {
              context.read<BookingDepositCubit>().depositBookingPayment(
                    due: dueController.text,
                    toleranceType: selectedToleranceType,
                    extraInputValue: selectedToleranceType == 1
                        ? extraInputController.text
                        : null,
                  );
            },
          ),
        ],
      ),
    );
  }
}
