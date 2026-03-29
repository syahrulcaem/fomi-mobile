import 'asset_model.dart';

class QrCodeModel {
  QrCodeModel({
    required this.id,
    required this.name,
    this.description,
    this.status,
    this.contactInfo,
    this.scanLogsCount,
    this.code,
    this.assetId,
    this.imageUrl,
    this.privacyMode,
    this.visibleFields = const [],
  });

  final String id;
  final String name;
  final String? description;
  final String? status;
  final Map<String, dynamic>? contactInfo;
  final int? scanLogsCount;
  final String? code;
  final String? assetId;
  final String? imageUrl;
  final String? privacyMode;
  final List<String> visibleFields;

  String get routeAssetId => assetId ?? id;

  bool get isLost => status == 'lost';

  factory QrCodeModel.fromJson(Map<String, dynamic> json) {
    return QrCodeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '-',
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      contactInfo: json['contact_info'] is Map<String, dynamic>
          ? json['contact_info'] as Map<String, dynamic>
          : null,
      scanLogsCount: (json['scan_logs_count'] as num?)?.toInt(),
      code: json['code']?.toString(),
      assetId: json['asset_id']?.toString(),
      imageUrl: _normalizeImageUrl(json['image']?.toString()),
      privacyMode: json['privacy_mode']?.toString(),
      visibleFields: _toStringList(json['visible_fields']),
    );
  }

  factory QrCodeModel.fromAsset(AssetModel asset) {
    final primaryQr = asset.primaryQrCode;
    return QrCodeModel(
      id: asset.id,
      assetId: asset.id,
      name: asset.name,
      description: asset.description,
      status: asset.status,
      contactInfo: asset.contactInfo,
      scanLogsCount: asset.scanLogsCount,
      code: primaryQr?.code,
      imageUrl: primaryQr?.imageUrl ?? asset.image,
      privacyMode: null,
      visibleFields: const [],
    );
  }

  Map<String, dynamic> toUpdatePayload({
    required String name,
    String? description,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? contactAddress,
    String? contactNote,
    String? privacyMode,
    List<String>? visibleFields,
  }) {
    final payload = <String, dynamic>{
      'name': name,
      'description': description,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'contact_address': contactAddress,
      'contact_note': contactNote,
    };

    if (privacyMode != null) {
      payload['privacy_mode'] = privacyMode;
    }
    if (visibleFields != null) {
      payload['visible_fields'] = visibleFields;
    }

    return payload;
  }
}

List<String> _toStringList(dynamic value) {
  if (value is! List) {
    return const [];
  }
  return value.map((item) => item.toString()).toList();
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
