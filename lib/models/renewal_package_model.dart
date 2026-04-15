class RenewalPackageModel {
  RenewalPackageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.barcodeQuota,
    this.description,
  });

  final String id;
  final String name;
  final int price;
  final int barcodeQuota;
  final String? description;

  factory RenewalPackageModel.fromJson(Map<String, dynamic> json) {
    final includedPlan =
        json['included_subscription_plan'] is Map<String, dynamic>
            ? json['included_subscription_plan'] as Map<String, dynamic>
            : null;

    final explicitPlanId =
        json['subscription_plan_id']?.toString() ?? json['plan_id']?.toString();
    final nestedPlanId = includedPlan?['id']?.toString();
    final fallbackId = json['id']?.toString();

    final resolvedId = [explicitPlanId, nestedPlanId, fallbackId]
        .whereType<String>()
        .map((value) => value.trim())
        .firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => '',
        );

    final resolvedQuota = (json['barcode_quota'] as num?)?.toInt() ??
        (json['qr_quota'] as num?)?.toInt() ??
        (json['quota'] as num?)?.toInt() ??
        (includedPlan?['qr_quota'] as num?)?.toInt() ??
        (includedPlan?['barcode_quota'] as num?)?.toInt() ??
        0;

    final resolvedName = json['name']?.toString() ??
        json['plan_name']?.toString() ??
        json['title']?.toString() ??
        '-';

    final resolvedDescription = json['description']?.toString() ??
        includedPlan?['description']?.toString();

    return RenewalPackageModel(
      id: resolvedId,
      name: resolvedName,
      price: (json['price'] as num?)?.toInt() ?? 0,
      barcodeQuota: resolvedQuota,
      description: resolvedDescription,
    );
  }
}
