class CustomerListResponse {
  final bool status;
  final CustomerData data;

  CustomerListResponse({
    required this.status,
    required this.data,
  });

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) {
    return CustomerListResponse(
      status: json['status'] == 'true',
      data: CustomerData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.toString(),
        'data': data.toJson(),
      };
}

class CustomerData {
  final int? currentPage;
  final List<Customer> data;
  final String? firstPageUrl;
  final int? from;
  final int? lastPage;
  final String? lastPageUrl;
  final List<PageLink>? links;
  final String? nextPageUrl;
  final String? path;
  final int? perPage;
  final String? prevPageUrl;
  final int? to;
  final int? total;

  CustomerData({
    this.currentPage,
    required this.data,
    this.firstPageUrl,
    this.from,
    this.lastPage,
    this.lastPageUrl,
    this.links,
    this.nextPageUrl,
    this.path,
    this.perPage,
    this.prevPageUrl,
    this.to,
    this.total,
  });

  factory CustomerData.fromJson(Map<String, dynamic> json) {
    return CustomerData(
      currentPage: json['current_page'],
      data: List<Customer>.from(json['data'].map((x) => Customer.fromJson(x))),
      firstPageUrl: json['first_page_url'],
      from: json['from'],
      lastPage: json['last_page'],
      lastPageUrl: json['last_page_url'],
      links: json['links'] != null
          ? List<PageLink>.from(json['links'].map((x) => PageLink.fromJson(x)))
          : [],
      nextPageUrl: json['next_page_url'],
      path: json['path'],
      perPage: json['per_page'],
      prevPageUrl: json['prev_page_url'],
      to: json['to'],
      total: json['total'],
    );
  }

  /// ✅ جديدة: تستخدم مع API اللي يرجّع List مباشرة
  factory CustomerData.fromList(List<dynamic> list) {
    return CustomerData(
      data: list.map((e) => Customer.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'data': data.map((x) => x.toJson()).toList(),
        'first_page_url': firstPageUrl,
        'from': from,
        'last_page': lastPage,
        'last_page_url': lastPageUrl,
        'links': links?.map((x) => x.toJson()).toList(),
        'next_page_url': nextPageUrl,
        'path': path,
        'per_page': perPage,
        'prev_page_url': prevPageUrl,
        'to': to,
        'total': total,
      };
}

class Customer {
  final int id;
  final String fullName;
  final String phoneNo;
  final int phoneVerified;

  Customer({
    required this.id,
    required this.fullName,
    required this.phoneNo,
    required this.phoneVerified,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      phoneNo: json['phone_no'] ?? '',
      phoneVerified: json['phone_verified'] ??
          json['is_phone_verified'] ??
          0, // يتعامل مع الحالتين
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone_no': phoneNo,
        'phone_verified': phoneVerified,
      };
}

class PageLink {
  final String? url;
  final String label;
  final bool active;

  PageLink({
    this.url,
    required this.label,
    required this.active,
  });

  factory PageLink.fromJson(Map<String, dynamic> json) {
    return PageLink(
      url: json['url'],
      label: json['label'],
      active: json['active'],
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'label': label,
        'active': active,
      };
}
