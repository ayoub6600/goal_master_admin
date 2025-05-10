class PaginatedResponse<T> {
  int? currentPage;
  List<T>? data;
  String? firstPageUrl;
  dynamic from;
  int? lastPage;
  String? lastPageUrl;
  dynamic nextPageUrl;
  String? path;
  int? perPage;
  dynamic prevPageUrl;
  dynamic to;
  int? total;

  PaginatedResponse({
    this.currentPage,
    this.data,
    this.firstPageUrl,
    this.from,
    this.lastPage,
    this.lastPageUrl,
    this.nextPageUrl,
    this.path,
    this.perPage,
    this.prevPageUrl,
    this.to,
    this.total,
  });

  @override
  String toString() {
    return 'PaginatedResponse(currentPage: $currentPage, data: $data, firstPageUrl: $firstPageUrl, from: $from, lastPage: $lastPage, lastPageUrl: $lastPageUrl, nextPageUrl: $nextPageUrl, path: $path, perPage: $perPage, prevPageUrl: $prevPageUrl, to: $to, total: $total)';
  }

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final base = json['data'] is Map<String, dynamic> ? json['data'] : json;

    final rawData = base['data'];

    List<T>? parsedData;

    if (rawData is List) {
      parsedData =
          rawData.map((e) => fromJsonT(e as Map<String, dynamic>)).toList();
    } else if (rawData is Map<String, dynamic>) {
      parsedData = rawData.values
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList();
    }

    return PaginatedResponse<T>(
      currentPage: base['current_page'] as int?,
      data: parsedData,
      firstPageUrl: base['first_page_url'] as String?,
      from: base['from'],
      lastPage: base['last_page'] as int?,
      lastPageUrl: base['last_page_url'] as String?,
      nextPageUrl: base['next_page_url'],
      path: base['path'] as String?,
      perPage: base['per_page'] as int?,
      prevPageUrl: base['prev_page_url'],
      to: base['to'],
      total: base['total'] as int?,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) => {
        'current_page': currentPage,
        'data': data?.map((e) => toJsonT(e)).toList(),
        'first_page_url': firstPageUrl,
        'from': from,
        'last_page': lastPage,
        'last_page_url': lastPageUrl,
        'next_page_url': nextPageUrl,
        'path': path,
        'per_page': perPage,
        'prev_page_url': prevPageUrl,
        'to': to,
        'total': total,
      };
}
