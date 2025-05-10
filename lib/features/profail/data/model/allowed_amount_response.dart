class AllowedAmountResponse {
  final bool status;
  final List<AllowedAmountData> data;
  final Pagination pagination;

  AllowedAmountResponse({
    required this.status,
    required this.data,
    required this.pagination,
  });

  factory AllowedAmountResponse.fromJson(Map<String, dynamic> json) {
    return AllowedAmountResponse(
      status: json['status'],
      data: (json['data'] as List)
          .map((e) => AllowedAmountData.fromJson(e))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

class AllowedAmountData {
  final int id;
  final int bookingId;
  final String allowedAmount;
  final int approvedBy;
  final String createdAt;
  final String updatedAt;
  final Booking booking;

  AllowedAmountData({
    required this.id,
    required this.bookingId,
    required this.allowedAmount,
    required this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.booking,
  });

  factory AllowedAmountData.fromJson(Map<String, dynamic> json) {
    return AllowedAmountData(
      id: json['id'],
      bookingId: json['booking_id'],
      allowedAmount: json['allowed_amount'],
      approvedBy: json['approved_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      booking: Booking.fromJson(json['booking']),
    );
  }
}

class Booking {
  final int id;
  final String date;
  final String startTime;
  final String endTime;
  final int cmnBranchId;
  final int cmnCustomerId;
  final int schEmployeeId;
  final int schServiceId;
  final Branch branch;
  final Customer customer;
  final Employee employee;
  final Service service;

  Booking({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.cmnBranchId,
    required this.cmnCustomerId,
    required this.schEmployeeId,
    required this.schServiceId,
    required this.branch,
    required this.customer,
    required this.employee,
    required this.service,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      date: json['date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      cmnBranchId: json['cmn_branch_id'],
      cmnCustomerId: json['cmn_customer_id'],
      schEmployeeId: json['sch_employee_id'],
      schServiceId: json['sch_service_id'],
      branch: Branch.fromJson(json['branch']),
      customer: Customer.fromJson(json['customer']),
      employee: Employee.fromJson(json['employee']),
      service: Service.fromJson(json['service']),
    );
  }
}

class Branch {
  final int id;
  final String name;

  Branch({required this.id, required this.name});

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Customer {
  final int id;
  final String fullName;
  final String phoneNo;

  Customer({
    required this.id,
    required this.fullName,
    required this.phoneNo,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      fullName: json['full_name'],
      phoneNo: json['phone_no'],
    );
  }
}

class Employee {
  final int id;
  final String fullName;

  Employee({required this.id, required this.fullName});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      fullName: json['full_name'],
    );
  }
}

class Service {
  final int id;
  final String title;
  final int schServiceCategoryId;
  final Category category;

  Service({
    required this.id,
    required this.title,
    required this.schServiceCategoryId,
    required this.category,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      title: json['title'],
      schServiceCategoryId: json['sch_service_category_id'],
      category: Category.fromJson(json['category']),
    );
  }
}

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Pagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;

  Pagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      from: json['from'],
      to: json['to'],
    );
  }
}
