part of 'manager_setup_cubit.dart';

sealed class ManagerSetupState {}

final class ManagerSetupInitial extends ManagerSetupState {}

final class ManagerSetupLoading extends ManagerSetupState {}

final class ManagerSetupLoaded extends ManagerSetupState {
  final ManagerSetupBootstrapResponse response;

  ManagerSetupLoaded(this.response);
}

final class ManagerSetupSubmitting extends ManagerSetupState {
  final ManagerSetupBootstrapResponse? bootstrap;

  ManagerSetupSubmitting(this.bootstrap);
}

final class ManagerSetupSuccess extends ManagerSetupState {
  final CreateFirstVenueResponse response;
  final ManagerSetupBootstrapResponse? bootstrap;

  ManagerSetupSuccess({
    required this.response,
    required this.bootstrap,
  });
}

final class ManagerCatalogSetupSuccess extends ManagerSetupState {
  final SaveManagerCatalogResponse response;
  final ManagerSetupBootstrapResponse? bootstrap;

  ManagerCatalogSetupSuccess({
    required this.response,
    required this.bootstrap,
  });
}

final class ManagerBookingPeriodsSuccess extends ManagerSetupState {
  final SaveManagerBookingPeriodsResponse response;
  final ManagerSetupBootstrapResponse? bootstrap;

  ManagerBookingPeriodsSuccess({
    required this.response,
    required this.bootstrap,
  });
}

final class ManagerSetupFailure extends ManagerSetupState {
  final String message;
  final ManagerSetupBootstrapResponse? bootstrap;

  ManagerSetupFailure(
    this.message, {
    this.bootstrap,
  });
}
