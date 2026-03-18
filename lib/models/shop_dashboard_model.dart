import 'shop_product_model.dart';

class ShopCategory {
  ShopCategory({
    required this.id,
    required this.name,
    this.iconUrl,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? iconUrl;
  final String? imageUrl;

  factory ShopCategory.fromJson(Map<String, dynamic> json) {
    return ShopCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconUrl: json['icon_url']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }
}

class ShopHeroSection {
  ShopHeroSection({
    required this.title,
    required this.subtitle,
    required this.ctaPrimaryLabel,
    required this.ctaPrimaryLink,
    required this.ctaSecondaryLabel,
    required this.ctaSecondaryLink,
    this.leftCardTag,
    this.leftCardImage,
    this.rightCardTag,
    this.rightCardImage,
  });

  final String title;
  final String subtitle;
  final String ctaPrimaryLabel;
  final String ctaPrimaryLink;
  final String ctaSecondaryLabel;
  final String ctaSecondaryLink;
  final String? leftCardTag;
  final String? leftCardImage;
  final String? rightCardTag;
  final String? rightCardImage;

  factory ShopHeroSection.fromJson(Map<String, dynamic> json) {
    final ctaPrimary = json['cta_primary'] as Map<String, dynamic>? ?? {};
    final ctaSecondary = json['cta_secondary'] as Map<String, dynamic>? ?? {};
    final leftCard = json['left_card'] as Map<String, dynamic>? ?? {};
    final rightCard = json['right_card'] as Map<String, dynamic>? ?? {};

    return ShopHeroSection(
      title: json['title']?.toString() ?? 'If Found... Scan Me Home',
      subtitle: json['subtitle']?.toString() ?? '',
      ctaPrimaryLabel: ctaPrimary['label']?.toString() ?? 'Daftar Gratis',
      ctaPrimaryLink: ctaPrimary['link']?.toString() ?? '/register',
      ctaSecondaryLabel: ctaSecondary['label']?.toString() ?? 'Ubah Akun Anak',
      ctaSecondaryLink: ctaSecondary['link']?.toString() ?? '/profile/child',
      leftCardTag: leftCard['tag']?.toString(),
      leftCardImage: leftCard['image_url']?.toString(),
      rightCardTag: rightCard['tag']?.toString(),
      rightCardImage: rightCard['image_url']?.toString(),
    );
  }
}

class ShopSocialProof {
  ShopSocialProof({
    required this.customerCount,
    required this.rating,
    required this.totalReviews,
    required this.avatars,
  });

  final int customerCount;
  final double rating;
  final int totalReviews;
  final List<String> avatars;

  factory ShopSocialProof.fromJson(Map<String, dynamic> json) {
    final avatarList = json['avatars'] as List? ?? [];
    return ShopSocialProof(
      customerCount: (json['customer_count'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      avatars: avatarList.map((e) => e.toString()).toList(),
    );
  }
}

class ShopMerchandise {
  ShopMerchandise({required this.filters, required this.products});

  final List<String> filters;
  final List<ShopProduct> products;

  factory ShopMerchandise.fromJson(Map<String, dynamic> json,
      List<ShopProduct> productList) {
    final filterList = json['filters'] as List? ?? [];
    return ShopMerchandise(
      filters: filterList.map((e) => e.toString()).toList(),
      products: productList,
    );
  }
}

class ShopDashboardModel {
  ShopDashboardModel({
    required this.hero,
    required this.categories,
    required this.merchandise,
    required this.socialProof,
  });

  final ShopHeroSection hero;
  final List<ShopCategory> categories;
  final ShopMerchandise merchandise;
  final ShopSocialProof socialProof;

  factory ShopDashboardModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final heroJson = data['hero_section'] as Map<String, dynamic>? ?? {};
    final categoriesList = data['categories'] as List? ?? [];
    final merchandiseJson = data['merchandise'] as Map<String, dynamic>? ?? {};
    final productsRaw = merchandiseJson['products'] as List? ?? [];
    final socialJson = data['social_proof'] as Map<String, dynamic>? ?? {};

    final products = productsRaw
        .whereType<Map<String, dynamic>>()
        .map(ShopProduct.fromJson)
        .toList();

    return ShopDashboardModel(
      hero: ShopHeroSection.fromJson(heroJson),
      categories: categoriesList
          .whereType<Map<String, dynamic>>()
          .map(ShopCategory.fromJson)
          .toList(),
      merchandise: ShopMerchandise.fromJson(merchandiseJson, products),
      socialProof: ShopSocialProof.fromJson(socialJson),
    );
  }
}
