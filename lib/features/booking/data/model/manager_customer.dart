import 'package:characters/characters.dart';

/// A customer as their venue knows them.
///
/// Goal Master keeps three layers of identity: a `users` login, the platform
/// customer, and the alias a venue writes in its own book. The same person is
/// «محمد الجار» to one venue and whatever they called themselves on the
/// platform — both are true, and the venue's alias never overwrites the
/// platform name.
///
/// [displayName] is what the manager should read first: their own name for
/// this person when they have one, the platform name otherwise.
class ManagerCustomer {
  const ManagerCustomer({
    required this.id,
    required this.displayName,
    required this.platformName,
    required this.phoneNo,
    this.alias,
    this.hasDistinctPlatformName = false,
    this.phoneVerified = false,
  });

  final int id;
  final String displayName;
  final String platformName;
  final String phoneNo;
  final String? alias;

  /// Whether showing the platform name underneath adds anything, or would just
  /// repeat the line above it.
  final bool hasDistinctPlatformName;

  final bool phoneVerified;

  /// The first letter, for the avatar. Falls back to a neutral glyph rather
  /// than rendering an empty circle.
  String get initial {
    final trimmed = displayName.trim();
    return trimmed.isEmpty ? '؟' : trimmed.characters.first;
  }

  factory ManagerCustomer.fromJson(Map<String, dynamic> json) {
    final platform = (json['platform_name'] ?? json['full_name'] ?? '').toString();
    final alias = json['alias']?.toString();

    return ManagerCustomer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      displayName:
          (json['display_name'] ?? (alias?.isNotEmpty == true ? alias : platform) ?? '')
              .toString(),
      platformName: platform,
      alias: (alias != null && alias.isNotEmpty) ? alias : null,
      hasDistinctPlatformName: json['has_distinct_platform_name'] == true,
      phoneNo: (json['phone_no'] ?? '').toString(),
      phoneVerified: json['phone_verified'] == true || json['phone_verified'] == 1,
    );
  }
}

/// One page of the manager's customer book.
class ManagerCustomerPage {
  const ManagerCustomerPage({
    required this.customers,
    required this.currentPage,
    required this.hasMore,
    required this.total,
  });

  final List<ManagerCustomer> customers;
  final int currentPage;
  final bool hasMore;
  final int total;

  factory ManagerCustomerPage.fromJson(Map<String, dynamic> json) {
    final rows = (json['data'] as List?) ?? const [];
    final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};

    return ManagerCustomerPage(
      customers: rows
          .whereType<Map<String, dynamic>>()
          .map(ManagerCustomer.fromJson)
          .toList(),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      hasMore: meta['has_more'] == true,
      total: (meta['total'] as num?)?.toInt() ?? rows.length,
    );
  }
}
