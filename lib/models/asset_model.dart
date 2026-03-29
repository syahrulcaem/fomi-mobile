class AssetModel {
  AssetModel({
    required this.id,
    required this.name,
    this.description,
    this.status,
    this.image,
    this.contactInfo,
    this.scanLogsCount,
    this.qrCodes = const [],
  });

  final String id;
  final String name;
  final String? description;
  final String? status;
  final String? image;
  final Map<String, dynamic>? contactInfo;
  final int? scanLogsCount;
  final List<AssetQrCode> qrCodes;

  AssetQrCode? get primaryQrCode => qrCodes.isNotEmpty ? qrCodes.first : null;

  bool get isLost => status == 'lost';

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    final scanLogs = json['scan_logs'];
    final scanLogsCount = scanLogs is List
        ? scanLogs.length
        : (json['scan_logs_count'] as num?)?.toInt();

    return AssetModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '-',
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      image: _normalizeImageUrl(json['image']?.toString()),
      contactInfo: json['contact_info'] is Map<String, dynamic>
          ? json['contact_info'] as Map<String, dynamic>
          : null,
      scanLogsCount: scanLogsCount,
      qrCodes: (json['qr_codes'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(AssetQrCode.fromJson)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'description': description,
      'contact_info': contactInfo,
    };
  }
}

class AssetQrCode {
  AssetQrCode({
    required this.id,
    required this.assetId,
    required this.code,
    required this.isActive,
    this.scanUrl,
    this.imageUrl,
  });

  final String id;
  final String assetId;
  final String code;
  final bool isActive;
  final String? scanUrl;
  final String? imageUrl;

  factory AssetQrCode.fromJson(Map<String, dynamic> json) {
    return AssetQrCode(
      id: json['id']?.toString() ?? '',
      assetId: json['asset_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '-',
      isActive: json['is_active'] == true,
      scanUrl: json['scan_url']?.toString(),
      imageUrl: _normalizeImageUrl(json['image_url']?.toString()),
    );
  }
}

String? _normalizeImageUrl(String? raw) {
  if (raw == null || raw.isEmpty) {
    return raw;
  }

  final uri = Uri.tryParse(raw);
  if (uri == null) {
    return raw;
  }

  final host = uri.host.toLowerCase();
  final isLocalHost =
      host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';

  if (uri.hasScheme && uri.scheme == 'http' && !isLocalHost) {
    return uri.replace(scheme: 'https').toString();
  }

  if (!uri.hasScheme && raw.startsWith('//')) {
    return 'https:$raw';
  }

  return raw;
}
