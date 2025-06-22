part of 'page_view_cubit_cubit.dart';

class PageViewState extends Equatable {
  final int currentPage;
  final int? customerId;
  final int? employeeId;
  final int? categoryId;
  final int? serviceId;
  final int? zoneId;
  final String? zoneTitle;
  final String? serviceTitle;
  final String? categoryTitle;
  final String? employeeTitle;
  final String? clubTitle;
  final String? status;
  final String? selectedDate;
  final String? phone;

  const PageViewState({
    required this.currentPage,
    this.customerId,
    this.employeeId,
    this.categoryId,
    this.serviceId,
    this.zoneId,
    this.phone,
    this.status,
    this.zoneTitle,
    this.serviceTitle,
    this.categoryTitle,
    this.employeeTitle,
    this.clubTitle,
    this.selectedDate,
  });

  PageViewState copyWith({
    int? currentPage,
    int? customerId,
    int? employeeId,
    int? categoryId,
    int? serviceId,
    String? status,
    int? zoneId,
    String? phone,
    String? zoneTitle,
    String? serviceTitle,
    String? categoryTitle,
    String? employeeTitle,
    String? clubTitle,
    String? selectedDate,
  }) {
    return PageViewState(
      currentPage: currentPage ?? this.currentPage,
      customerId: customerId ?? this.customerId,
      employeeId: employeeId ?? this.employeeId,
      serviceId: serviceId ?? this.serviceId,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      zoneId: zoneId ?? this.zoneId,
      phone: phone ?? this.phone,
      zoneTitle: zoneTitle ?? this.zoneTitle,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      employeeTitle: employeeTitle ?? this.employeeTitle,
      clubTitle: clubTitle ?? this.clubTitle,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  @override
  List<Object?> get props => [
        currentPage,
        customerId,
        employeeId,
        serviceId,
        zoneId,
        categoryId,
        zoneTitle,
        status,
        serviceTitle,
        categoryTitle,
        employeeTitle,
        clubTitle,
        selectedDate,
      ];
}
