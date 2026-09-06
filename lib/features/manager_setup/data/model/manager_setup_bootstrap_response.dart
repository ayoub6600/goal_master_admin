class ManagerSetupBootstrapResponse {
  final ManagerSetupData data;

  ManagerSetupBootstrapResponse({required this.data});

  factory ManagerSetupBootstrapResponse.fromJson(Map<String, dynamic> json) {
    return ManagerSetupBootstrapResponse(
      data: ManagerSetupData.fromJson(
        json['data'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class ManagerSetupData {
  final SetupStatus setup;
  final WalletSummary wallet;
  final List<ZoneOption> zones;
  final List<CategoryTypeOption> categoryTypes;
  final SetupCatalog catalog;

  ManagerSetupData({
    required this.setup,
    required this.wallet,
    required this.zones,
    required this.categoryTypes,
    required this.catalog,
  });

  factory ManagerSetupData.fromJson(Map<String, dynamic> json) {
    return ManagerSetupData(
      setup: SetupStatus.fromJson(
        json['setup'] as Map<String, dynamic>? ?? const {},
      ),
      wallet: WalletSummary.fromJson(
        json['wallet'] as Map<String, dynamic>? ?? const {},
      ),
      zones: (json['zones'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => ZoneOption.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      categoryTypes: (json['category_types'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) =>
              CategoryTypeOption.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      catalog: SetupCatalog.fromJson(
        json['catalog'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class CategoryTypeOption {
  final int id;
  final String name;

  CategoryTypeOption({required this.id, required this.name});

  factory CategoryTypeOption.fromJson(Map<String, dynamic> json) {
    return CategoryTypeOption(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class SetupStatus {
  final bool needsVenueSetup;
  final bool hasCompletedVenueSetup;
  final bool hasBranchProfile;
  final bool hasCategorySetup;
  final bool hasServiceSetup;
  final bool hasEmployeeSetup;
  final bool canStartBooking;
  final String nextStepKey;
  final String nextStepLabel;
  final ExistingBranch? branch;

  SetupStatus({
    required this.needsVenueSetup,
    required this.hasCompletedVenueSetup,
    required this.hasBranchProfile,
    required this.hasCategorySetup,
    required this.hasServiceSetup,
    required this.hasEmployeeSetup,
    required this.canStartBooking,
    required this.nextStepKey,
    required this.nextStepLabel,
    this.branch,
  });

  factory SetupStatus.fromJson(Map<String, dynamic> json) {
    return SetupStatus(
      needsVenueSetup: _toBool(json['needs_venue_setup']),
      hasCompletedVenueSetup: _toBool(json['has_completed_venue_setup']),
      hasBranchProfile: _toBool(json['has_branch_profile']),
      hasCategorySetup: _toBool(json['has_category_setup']),
      hasServiceSetup: _toBool(json['has_service_setup']),
      hasEmployeeSetup: _toBool(json['has_employee_setup']),
      canStartBooking: _toBool(json['can_start_booking']),
      nextStepKey: (json['next_step_key'] ?? '').toString(),
      nextStepLabel: (json['next_step_label'] ?? '').toString(),
      branch: json['branch'] is Map<String, dynamic>
          ? ExistingBranch.fromJson(json['branch'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ExistingBranch {
  final int id;
  final String name;
  final String phone;
  final String email;
  final int zoneId;
  final String zoneName;
  final String address;
  final String lat;
  final String long;
  final String imageUrl;

  ExistingBranch({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.zoneId,
    required this.zoneName,
    required this.address,
    required this.lat,
    required this.long,
    required this.imageUrl,
  });

  factory ExistingBranch.fromJson(Map<String, dynamic> json) {
    return ExistingBranch(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      zoneId: _toInt(json['zone_id']),
      zoneName: (json['zone_name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      lat: (json['lat'] ?? '').toString(),
      long: (json['long'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
    );
  }
}

class WalletSummary {
  final double currentBalance;
  final int transactionsCount;
  final List<WalletTransactionPreview> recentTransactions;

  WalletSummary({
    required this.currentBalance,
    required this.transactionsCount,
    required this.recentTransactions,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      currentBalance: _toDouble(json['current_balance']),
      transactionsCount: _toInt(json['transactions_count']),
      recentTransactions:
          (json['recent_transactions'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((item) => WalletTransactionPreview.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(),
    );
  }
}

class WalletTransactionPreview {
  final int id;
  final double amount;
  final int balanceType;
  final String type;
  final String description;
  final String createdAt;

  WalletTransactionPreview({
    required this.id,
    required this.amount,
    required this.balanceType,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransactionPreview.fromJson(Map<String, dynamic> json) {
    return WalletTransactionPreview(
      id: _toInt(json['id']),
      amount: _toDouble(json['amount']),
      balanceType: _toInt(json['balance_type']),
      type: (json['type'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class ZoneOption {
  final int id;
  final String name;
  final String? boundaryType; // 'circle' | 'polygon' | null
  final double? centerLat;
  final double? centerLng;
  final int? radiusMeters;
  final String? polygonPath; // raw JSON string of [{lat,lng}, ...]

  ZoneOption({
    required this.id,
    required this.name,
    this.boundaryType,
    this.centerLat,
    this.centerLng,
    this.radiusMeters,
    this.polygonPath,
  });

  bool get hasBoundary => boundaryType == 'circle' || boundaryType == 'polygon';

  factory ZoneOption.fromJson(Map<String, dynamic> json) {
    return ZoneOption(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      boundaryType: json['boundary_type']?.toString(),
      centerLat: json['center_lat'] == null
          ? null
          : double.tryParse(json['center_lat'].toString()),
      centerLng: json['center_lng'] == null
          ? null
          : double.tryParse(json['center_lng'].toString()),
      radiusMeters: json['radius_meters'] == null
          ? null
          : int.tryParse(json['radius_meters'].toString()),
      polygonPath: json['polygon_path']?.toString(),
    );
  }
}

class SetupCatalog {
  final SetupCategory? category;
  final List<SetupServiceItem> services;
  final List<SetupEmployeeItem> employees;

  SetupCatalog({
    required this.category,
    required this.services,
    required this.employees,
  });

  factory SetupCatalog.fromJson(Map<String, dynamic> json) {
    return SetupCatalog(
      category: json['category'] is Map<String, dynamic>
          ? SetupCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      services: (json['services'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) =>
              SetupServiceItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      employees: (json['employees'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) =>
              SetupEmployeeItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class SetupCategory {
  final int id;
  final String name;

  SetupCategory({
    required this.id,
    required this.name,
  });

  factory SetupCategory.fromJson(Map<String, dynamic> json) {
    return SetupCategory(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class SetupServiceItem {
  final int id;
  final String title;
  final double price;
  final int slotMinutes;
  final String remarks;
  final bool supportsEvening;
  final bool supportsAfterMidnight;

  SetupServiceItem({
    required this.id,
    required this.title,
    required this.price,
    required this.slotMinutes,
    required this.remarks,
    required this.supportsEvening,
    required this.supportsAfterMidnight,
  });

  factory SetupServiceItem.fromJson(Map<String, dynamic> json) {
    return SetupServiceItem(
      id: _toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      price: _toDouble(json['price']),
      slotMinutes: _toInt(json['slot_minutes']),
      remarks: (json['remarks'] ?? '').toString(),
      supportsEvening: _toBool(json['supports_evening']),
      supportsAfterMidnight: _toBool(json['supports_after_midnight']),
    );
  }
}

class SetupEmployeeItem {
  final int id;
  final String fullName;
  final String employeeId;
  final int status;
  final String designationName;
  final String startTime;
  final String endTime;

  SetupEmployeeItem({
    required this.id,
    required this.fullName,
    required this.employeeId,
    required this.status,
    required this.designationName,
    required this.startTime,
    required this.endTime,
  });

  factory SetupEmployeeItem.fromJson(Map<String, dynamic> json) {
    return SetupEmployeeItem(
      id: _toInt(json['id']),
      fullName: (json['full_name'] ?? '').toString(),
      employeeId: (json['employee_id'] ?? '').toString(),
      status: _toInt(json['status']),
      designationName: (json['designation_name'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
    );
  }

  /// Matches ManagerCatalogSetupService::employeeCode() on the backend —
  /// 'GM{branch_id}-EVE' / 'GM{branch_id}-AFT'. Kept here as the one place
  /// that knows the format, after a backend identifier shortening (varchar
  /// overflow fix) silently broke three separate `.contains('EVENING')` /
  /// `.contains('AFTER-MIDNIGHT')` checks scattered across this app that
  /// still expected the old, longer identifier.
  bool get isEveningChannel => employeeId.contains('-EVE');
  bool get isAfterMidnightChannel => employeeId.contains('-AFT');
}

class SaveManagerBookingPeriodsResponse {
  final String message;
  final List<SetupEmployeeItem> employees;

  SaveManagerBookingPeriodsResponse({
    required this.message,
    required this.employees,
  });

  factory SaveManagerBookingPeriodsResponse.fromJson(
      Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};

    return SaveManagerBookingPeriodsResponse(
      message: (json['message'] ?? '').toString(),
      employees: (data['employees'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) =>
              SetupEmployeeItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class CreateFirstVenueResponse {
  final String message;
  final CreatedBranchData branch;
  final CreatedUserVenueData user;

  CreateFirstVenueResponse({
    required this.message,
    required this.branch,
    required this.user,
  });

  factory CreateFirstVenueResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};

    return CreateFirstVenueResponse(
      message: (json['message'] ?? '').toString(),
      branch: CreatedBranchData.fromJson(
        data['branch'] as Map<String, dynamic>? ?? const {},
      ),
      user: CreatedUserVenueData.fromJson(
        data['user'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class SaveManagerCatalogResponse {
  final String message;

  SaveManagerCatalogResponse({
    required this.message,
  });

  factory SaveManagerCatalogResponse.fromJson(Map<String, dynamic> json) {
    return SaveManagerCatalogResponse(
      message: (json['message'] ?? '').toString(),
    );
  }
}

class CreatedBranchData {
  final int id;
  final String name;
  final String phone;
  final String email;
  final int zoneId;
  final String zoneName;
  final String address;
  final String lat;
  final String long;
  final String imageUrl;

  CreatedBranchData({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.zoneId,
    required this.zoneName,
    required this.address,
    required this.lat,
    required this.long,
    required this.imageUrl,
  });

  factory CreatedBranchData.fromJson(Map<String, dynamic> json) {
    return CreatedBranchData(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      zoneId: _toInt(json['zone_id']),
      zoneName: (json['zone_name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      lat: (json['lat'] ?? '').toString(),
      long: (json['long'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
    );
  }
}

class CreatedUserVenueData {
  final int id;
  final int zoneId;
  final int clubId;

  CreatedUserVenueData({
    required this.id,
    required this.zoneId,
    required this.clubId,
  });

  factory CreatedUserVenueData.fromJson(Map<String, dynamic> json) {
    return CreatedUserVenueData(
      id: _toInt(json['id']),
      zoneId: _toInt(json['zone_id']),
      clubId: _toInt(json['club_id']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  return value?.toString().toLowerCase() == 'true' || value?.toString() == '1';
}
