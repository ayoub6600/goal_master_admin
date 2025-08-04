import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geoCode;
import 'layout_state.dart';

class LayoutCubit extends Cubit<LayoutState> {
  LayoutCubit() : super(LayoutState.initial());

  final Location locationController = Location();

  /// ✅ تغيير النافبار النشط
  void changeSelectedNavBar(NavBarElement activeScreen) {
    emit(state.copyWith(activeScreen: activeScreen));
  }

  /// ✅ تحديث حالة التحديث
  void changeIsUpdate(bool value) {
    emit(state.copyWith(isUpdate: value));
  }
}
