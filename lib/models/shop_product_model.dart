class ProductVariant {
  ProductVariant({
    required this.id,
    required this.productId,
    required this.displayName,
    this.attributeName,
    this.attributeValue,
    this.secondaryAttributeName,
    this.secondaryAttributeValue,
    required this.price,
    required this.stock,
    required this.isActive,
    this.sortOrder = 0,
  });

  final String id;
  final String productId;
  final String displayName;
  final String? attributeName;
  final String? attributeValue;
  final String? secondaryAttributeName;
  final String? secondaryAttributeValue;
  final int price;
  final int stock;
  final bool isActive;
  final int sortOrder;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      attributeName: json['attribute_name']?.toString(),
      attributeValue: json['attribute_value']?.toString(),
      secondaryAttributeName: json['secondary_attribute_name']?.toString(),
      secondaryAttributeValue: json['secondary_attribute_value']?.toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] == true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class ShopProduct {
  ShopProduct({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.type,
    this.durationDays,
    required this.isActive,
    required this.variants,
    this.categoryId,
    this.category,
  });

  final String id;
  final String name;
  final String? description;
  final int price;
  final int stock;
  final String? imageUrl;
  final String type;
  final int? durationDays;
  final bool isActive;
  final List<ProductVariant> variants;
  final String? categoryId;
  final String? category;

  bool get hasVariants => variants.isNotEmpty;

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    final rawVariants = json['variants'];
    final rawCategory = json['category'];

    String? categoryValue;
    if (rawCategory is Map<String, dynamic>) {
      categoryValue = rawCategory['name']?.toString();
    } else {
      categoryValue = rawCategory?.toString();
    }

    final normalizedType = _normalizeProductType(
      primaryType: json['type']?.toString(),
      secondaryType: json['product_type']?.toString(),
      categoryHint: categoryValue,
    );

    final List<ProductVariant> variantList = rawVariants is List
        ? rawVariants
            .whereType<Map<String, dynamic>>()
            .map(ProductVariant.fromJson)
            .where((v) => v.isActive)
            .toList()
        : [];

    return ShopProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url']?.toString(),
      type: normalizedType,
      durationDays: (json['duration_days'] as num?)?.toInt(),
      isActive: json['is_active'] == true,
      variants: variantList,
      categoryId: json['category_id']?.toString(),
      category: categoryValue,
    );
  }

  static String _normalizeProductType({
    String? primaryType,
    String? secondaryType,
    String? categoryHint,
  }) {
    final candidates = <String?>[primaryType, secondaryType, categoryHint];

    for (final candidate in candidates) {
      if (candidate == null) {
        continue;
      }

      final normalized = candidate.trim().toLowerCase();
      if (normalized == 'physical' || normalized == 'digital') {
        return normalized;
      }
    }

    final fallback = primaryType?.trim() ?? '';
    return fallback.toLowerCase();
  }
}
