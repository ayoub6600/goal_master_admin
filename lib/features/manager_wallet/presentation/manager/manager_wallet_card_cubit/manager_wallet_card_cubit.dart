import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:goal_master_admin/features/manager_wallet/data/repo/manager_wallet_repo.dart';

part 'manager_wallet_card_state.dart';

class ManagerWalletCardCubit extends Cubit<ManagerWalletCardState> {
  ManagerWalletCardCubit(this._repo) : super(ManagerWalletCardInitial());

  final ManagerWalletRepo _repo;
  final codeController = TextEditingController();

  Future<void> chargeCard() async {
    final code = codeController.text.trim();
    if (code.isEmpty) {
      emit(ManagerWalletCardFailure('ادخل رقم الكرت'));
      return;
    }

    emit(ManagerWalletCardLoading());
    final result = await _repo.chargeCard(code);
    result.fold(
      (failure) => emit(ManagerWalletCardFailure(failure.errMessage)),
      (message) => emit(ManagerWalletCardSuccess(message)),
    );
  }

  @override
  Future<void> close() {
    codeController.dispose();
    return super.close();
  }
}
