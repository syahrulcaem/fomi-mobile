class UserDigitalProductAsset {
  UserDigitalProductAsset({
    required this.id,
    required this.name,
    this.expiresAt,
  });

  final String id;
  final String name;
  final String? expiresAt;

  factory UserDigitalProductAsset.fromJson(Map<String, dynamic> json) {
    return UserDigitalProductAsset(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['asset_name']?.toString() ??
          'QR Asset',
      expiresAt: json['active_subscription'] is Map<String, dynamic>
          ? (json['active_subscription'] as Map<String, dynamic>)['expires_at']
              ?.toString()
          : json['expires_at']?.toString(),
    );
  }
}

class UserDigitalProductItem {
  UserDigitalProductItem({
    required this.id,
    required this.name,
    this.description,
    this.orderNumber,
    this.purchasedAt,
    this.templateName,
    this.previewUrlTemplate,
    this.downloadUrlTemplate,
    this.previewUrl,
    this.downloadUrl,
  });

  final String id;
  final String name;
  final String? description;
  final String? orderNumber;
  final String? purchasedAt;
  final String? templateName;
  final String? previewUrlTemplate;
  final String? downloadUrlTemplate;
  final String? previewUrl;
  final String? downloadUrl;

  factory UserDigitalProductItem.fromJson(Map<String, dynamic> json) {
    return UserDigitalProductItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '-',
      description: json['description']?.toString(),
      orderNumber: json['order_number']?.toString(),
      purchasedAt: json['purchased_at']?.toString(),
      templateName: json['template_name']?.toString(),
      previewUrlTemplate: json['preview_url_template']?.toString(),
      downloadUrlTemplate: json['download_url_template']?.toString(),
      previewUrl: json['preview_url']?.toString(),
      downloadUrl: json['download_url']?.toString(),
    );
  }
}

class UserDigitalProductsResponse {
  UserDigitalProductsResponse({
    required this.items,
    required this.activeQrAssets,
    required this.hasActiveQrAssets,
    required this.raw,
  });

  final List<UserDigitalProductItem> items;
  final List<UserDigitalProductAsset> activeQrAssets;
  final bool hasActiveQrAssets;
  final Map<String, dynamic> raw;

  factory UserDigitalProductsResponse.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final itemRaw = root['data'] is List
        ? root['data'] as List
        : json['data'] is List
            ? json['data'] as List
            : const <dynamic>[];

    final assetsRaw = root['active_qr_assets'] is List
        ? root['active_qr_assets'] as List
        : json['active_qr_assets'] is List
            ? json['active_qr_assets'] as List
            : const <dynamic>[];

    final hasActiveQr = root['has_active_qr_assets'] == true ||
        json['has_active_qr_assets'] == true;

    return UserDigitalProductsResponse(
      items: itemRaw
          .whereType<Map<String, dynamic>>()
          .map(UserDigitalProductItem.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList(),
      activeQrAssets: assetsRaw
          .whereType<Map<String, dynamic>>()
          .map(UserDigitalProductAsset.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList(),
      hasActiveQrAssets: hasActiveQr || assetsRaw.isNotEmpty,
      raw: root,
    );
  }
}
