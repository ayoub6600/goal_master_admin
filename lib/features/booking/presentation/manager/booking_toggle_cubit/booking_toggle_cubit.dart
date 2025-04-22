import 'package:flutter_bloc/flutter_bloc.dart';

import 'booking_toggle_state.dart';

class FavToggleCubit extends Cubit<FavToggleState> {
  FavToggleCubit() : super(FavDoctors());

  Future<void> toggle({required bool isDoc}) async {
    if (isDoc) {
      emit(FavDoctors());
    } else {
      emit(FavArticles());
    }
  }
}
