part of 'manager_customers_cubit.dart';

class ManagerCustomersState extends Equatable {
  const ManagerCustomersState({
    this.customers = const [],
    this.selected,
    this.search = '',
    this.page = 1,
    this.hasMore = false,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<ManagerCustomer> customers;
  final ManagerCustomer? selected;
  final String search;
  final int page;
  final bool hasMore;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  ManagerCustomersState copyWith({
    List<ManagerCustomer>? customers,
    ManagerCustomer? selected,
    String? search,
    int? page,
    bool? hasMore,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return ManagerCustomersState(
      customers: customers ?? this.customers,
      selected: selected ?? this.selected,
      search: search ?? this.search,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        customers.map((c) => c.id).toList(),
        selected?.id,
        search,
        page,
        hasMore,
        total,
        isLoading,
        isLoadingMore,
        error,
      ];
}
