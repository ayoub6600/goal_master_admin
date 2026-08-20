import 'dart:convert';

NotificationResponse notificationResponseFromJson(String str) =>
    NotificationResponse.fromJson(json.decode(str));

String notificationResponseToJson(NotificationResponse data) =>
    json.encode(data.toJson());

class NotificationResponse {
  final bool status;
  final NotificationData data;

  NotificationResponse({
    required this.status,
    required this.data,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      NotificationResponse(
        status: json["status"] == "true",
        data: NotificationData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "data": data.toJson(),
      };
}

class NotificationData {
  final int currentPage;
  final List<NotificationItem> data;
  final String? firstPageUrl;
  final int from;
  final int lastPage;
  final String? lastPageUrl;
  final List<Link> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final dynamic prevPageUrl;
  final int to;
  final int total;

  NotificationData({
    required this.currentPage,
    required this.data,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    required this.nextPageUrl,
    required this.path,
    required this.perPage,
    required this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) =>
      NotificationData(
        currentPage: _asInt(json["current_page"]),
        data: List<NotificationItem>.from((json["data"] as List<dynamic>? ?? [])
            .map((x) => NotificationItem.fromJson(x))),
        firstPageUrl: json["first_page_url"],
        from: _asInt(json["from"]),
        lastPage: _asInt(json["last_page"]),
        lastPageUrl: json["last_page_url"],
        links: List<Link>.from((json["links"] as List<dynamic>? ?? [])
            .map((x) => Link.fromJson(x))),
        nextPageUrl: json["next_page_url"],
        path: json["path"]?.toString() ?? '',
        perPage: _asInt(json["per_page"]),
        prevPageUrl: json["prev_page_url"],
        to: _asInt(json["to"]),
        total: _asInt(json["total"]),
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "first_page_url": firstPageUrl,
        "from": from,
        "last_page": lastPage,
        "last_page_url": lastPageUrl,
        "links": List<dynamic>.from(links.map((x) => x.toJson())),
        "next_page_url": nextPageUrl,
        "path": path,
        "per_page": perPage,
        "prev_page_url": prevPageUrl,
        "to": to,
        "total": total,
      };
}

class NotificationItem {
  final String id;
  final String type;
  final String notifiableType;
  final int notifiableId;
  final NotificationInnerData data;
  final String? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.notifiableType,
    required this.notifiableId,
    required this.data,
    required this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json["id"]?.toString() ?? '',
        type: json["type"]?.toString() ?? '',
        notifiableType: json["notifiable_type"]?.toString() ?? '',
        notifiableId: _asInt(json["notifiable_id"]),
        data: NotificationInnerData.fromJson(
            json["data"] as Map<String, dynamic>? ?? const {}),
        readAt: json["read_at"],
        createdAt: DateTime.tryParse(json["created_at"]) ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json["updated_at"]) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
        "notifiable_type": notifiableType,
        "notifiable_id": notifiableId,
        "data": data.toJson(),
        "read_at": readAt,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
      };

  // دالة copyWith المحدثة
  NotificationItem copyWith({
    String? id,
    String? type,
    String? notifiableType,
    int? notifiableId,
    NotificationInnerData? data,
    String? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      notifiableType: notifiableType ?? this.notifiableType,
      notifiableId: notifiableId ?? this.notifiableId,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // دالة مساعدة للتحقق من حالة القراءة
  bool get isRead => readAt != null;

  // Override لدوال المساواة والتجزئة
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
// class NotificationItem {
//   final String id;
//   final String type;
//   final String notifiableType;
//   final int notifiableId;
//   final NotificationInnerData data;
//   final String? readAt;
//   final DateTime createdAt;
//   final DateTime updatedAt;

//   NotificationItem({
//     required this.id,
//     required this.type,
//     required this.notifiableType,
//     required this.notifiableId,
//     required this.data,
//     required this.readAt,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   factory NotificationItem.fromJson(Map<String, dynamic> json) =>
//       NotificationItem(
//         id: json["id"],
//         type: json["type"],
//         notifiableType: json["notifiable_type"],
//         notifiableId: json["notifiable_id"],
//         data: NotificationInnerData.fromJson(json["data"]),
//         readAt: json["read_at"],
//         createdAt: DateTime.parse(json["created_at"]),
//         updatedAt: DateTime.parse(json["updated_at"]),
//       );

//   Map<String, dynamic> toJson() => {
//         "id": id,
//         "type": type,
//         "notifiable_type": notifiableType,
//         "notifiable_id": notifiableId,
//         "data": data.toJson(),
//         "read_at": readAt,
//         "created_at": createdAt.toIso8601String(),
//         "updated_at": updatedAt.toIso8601String(),
//       };
// }

class NotificationInnerData {
  final String message;
  final int? id;
  final int? bookingId;
  final String? createdAt;
  final String? type;

  NotificationInnerData({
    required this.message,
    this.id,
    this.bookingId,
    this.createdAt,
    this.type,
  });

  factory NotificationInnerData.fromJson(Map<String, dynamic> json) =>
      NotificationInnerData(
        message: json["message"]?.toString() ?? '',
        id: _asNullableInt(json["id"]),
        bookingId:
            _asNullableInt(json["booking_id"]) ?? _asNullableInt(json["id"]),
        createdAt: json["created_at"]?.toString(),
        type: json["type"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "id": id,
        "booking_id": bookingId,
        "created_at": createdAt,
        "type": type,
      };
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

class Link {
  final String? url;
  final String label;
  final bool active;

  Link({
    required this.url,
    required this.label,
    required this.active,
  });

  factory Link.fromJson(Map<String, dynamic> json) => Link(
        url: json["url"],
        label: json["label"],
        active: json["active"],
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "label": label,
        "active": active,
      };
}
