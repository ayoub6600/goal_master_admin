import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'page_view_cubit_state.dart';

class PageViewCubit extends Cubit<PageViewState> {
  PageViewCubit() : super(const PageViewState(currentPage: 0));

  void nextPage() {
    if (state.currentPage < 7) {
      emit(state.copyWith(currentPage: state.currentPage + 1));
    }
  }

  void previousPage() {
    if (state.currentPage > 0) {
      emit(state.copyWith(currentPage: state.currentPage - 1));
    }
  }

  void setCategoryId(int id, String title) {
    emit(state.copyWith(categoryId: id, categoryTitle: title));
  }

  void goToNextPageIfReady(PageController controller) {
    if (state.status != null && state.customerId != null) {
      nextPage();
      controller.animateToPage(
        controller.page!.toInt() + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void updateStatus(String val) {
    emit(state.copyWith(status: val));
  }

  void setCustomerId(
    int id,
    String phone,
    String name,
  ) {
    emit(state.copyWith(customerId: id, phone: phone, nameCustomer: name));
  }
  //status

  void setEmployeeId(
    int id,
  ) {
    emit(state.copyWith(employeeId: id));
  }

  void setServiceId(int id, String title) {
    emit(state.copyWith(serviceId: id, serviceTitle: title));
  }

  void setDate(String date) {
    emit(state.copyWith(selectedDate: date));
  }

  void reset() {
    emit(const PageViewState(currentPage: 0));
  }
}
