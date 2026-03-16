import 'asset_model.dart';
import 'order_model.dart';
import 'renewal_package_model.dart';

class DashboardStats {
  DashboardStats({
    required this.totalAssets,
    required this.lostAssets,
    required this.activeQrCodes,
    required this.totalOrders,
    required this.remainingBarcodeQuota,
  });

  final int totalAssets;
  final int lostAssets;
  final int activeQrCodes;
  final int totalOrders;
  final int remainingBarcodeQuota;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalAssets: (json['total_assets'] as num?)?.toInt() ?? 0,
      lostAssets: (json['lost_assets'] as num?)?.toInt() ?? 0,
      activeQrCodes: (json['active_qr_codes'] as num?)?.toInt() ?? 0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      remainingBarcodeQuota: (json['remaining_barcode_quota'] as num?)?.toInt() ?? 0,
    );
  }
}

class MidtransConfig {
  MidtransConfig({
    required this.isProduction,
    this.clientKey,
    this.merchantId,
    this.snapBaseUrl,
  });

  final bool isProduction;
  final String? clientKey;
  final String? merchantId;
  final String? snapBaseUrl;

  factory MidtransConfig.fromJson(Map<String, dynamic> json) {
    return MidtransConfig(
      isProduction: json['is_production'] == true,
      clientKey: json['client_key']?.toString(),
      merchantId: json['merchant_id']?.toString(),
      snapBaseUrl: json['snap_base_url']?.toString(),
    );
  }
}

class DashboardModel {
  DashboardModel({
    required this.stats,
    required this.recentAssets,
    required this.expiredAssets,
    required this.recentOrders,
    required this.renewalPackages,
    required this.midtransConfig,
  });

  final DashboardStats stats;
  final List<AssetModel> recentAssets;
  final List<AssetModel> expiredAssets;
  final List<OrderModel> recentOrders;
  final List<RenewalPackageModel> renewalPackages;
  final MidtransConfig? midtransConfig;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return DashboardModel(
      stats: DashboardStats.fromJson(
        data['stats'] is Map<String, dynamic>
            ? data['stats'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
      recentAssets: _toAssetList(data['recent_assets']),
      expiredAssets: _toAssetList(data['expired_assets']),
      recentOrders: _toOrderList(data['recent_orders']),
      renewalPackages: _toPackageList(data['renewal_packages']),
      midtransConfig: data['midtrans_config'] is Map<String, dynamic>
          ? MidtransConfig.fromJson(data['midtrans_config'] as Map<String, dynamic>)
          : null,
    );
  }

  static List<AssetModel> _toAssetList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().map(AssetModel.fromJson).toList();
    }
    return const [];
  }

  static List<OrderModel> _toOrderList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().map(OrderModel.fromJson).toList();
    }
    return const [];
  }

  static List<RenewalPackageModel> _toPackageList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(RenewalPackageModel.fromJson)
          .toList();
    }
    return const [];
  }
}
