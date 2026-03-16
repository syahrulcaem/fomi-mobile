class PaginatedResponse<T> {
  PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) itemBuilder,
  ) {
    final rawItems = json['data'] is List ? json['data'] as List : <dynamic>[];
    return PaginatedResponse<T>(
      items:
          rawItems.whereType<Map<String, dynamic>>().map(itemBuilder).toList(),
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? rawItems.length,
      total: (json['total'] as num?)?.toInt() ?? rawItems.length,
    );
  }

  static PaginatedResponse<T> fromAny<T>(
    dynamic data,
    T Function(Map<String, dynamic> item) itemBuilder,
  ) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        return PaginatedResponse<T>.fromJson(data, itemBuilder);
      }

      final nested = data['data'];
      if (nested is Map<String, dynamic> && nested['data'] is List) {
        return PaginatedResponse<T>.fromJson(nested, itemBuilder);
      }
    }

    if (data is List) {
      final items =
          data.whereType<Map<String, dynamic>>().map(itemBuilder).toList();
      return PaginatedResponse<T>(
        items: items,
        currentPage: 1,
        lastPage: 1,
        perPage: items.length,
        total: items.length,
      );
    }

    return PaginatedResponse<T>(
      items: const [],
      currentPage: 1,
      lastPage: 1,
      perPage: 0,
      total: 0,
    );
  }
}
