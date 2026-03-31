import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/shop_dashboard_model.dart';
import '../../models/shop_product_model.dart';
import '../../services/shop_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item_model.dart';
import '../../widgets/skeleton_loader.dart';

class ShopHomeScreen extends StatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  bool _loading = true;
  ShopDashboardModel? _dashboard;
  String? _selectedCategoryKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = context.read<ShopService>();
      final data = await service.getShopDashboard();
      if (!mounted) return;
      setState(() => _dashboard = data);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data toko.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatPrice(int price) {
    final str = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  String _buildCategoryRoute(String label) {
    return Uri(
      path: '/shop/products',
      queryParameters: {'category': label},
    ).toString();
  }

  String _normalizeText(String raw) {
    return raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  String _displayCategoryLabel(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return cleaned;
    }

    final lower = cleaned.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  List<_CategoryChipItem> _homeCategoryItems() {
    final cats = _dashboard?.categories.map((e) => e.name) ?? const <String>[];
    final filters = _dashboard?.merchandise.filters ?? const <String>[];
    final merged = [...cats, ...filters];

    final seen = <String>{};
    final items = <_CategoryChipItem>[
      const _CategoryChipItem(key: 'all', label: 'Semua'),
    ];

    for (final raw in merged) {
      final cleaned = raw.trim();
      if (cleaned.isEmpty) {
        continue;
      }

      final key = _normalizeText(cleaned);
      if (key.isEmpty || !seen.add(key)) {
        continue;
      }

      items.add(
          _CategoryChipItem(key: key, label: _displayCategoryLabel(cleaned)));
    }

    return items;
  }

  bool _matchesCategory(ShopProduct product, String selectedKey) {
    final candidates = <String>[
      product.category ?? '',
      product.type,
      product.name,
    ];

    final hasTextMatch = candidates.any((value) {
      final normalized = _normalizeText(value);
      return normalized.contains(selectedKey) ||
          selectedKey.contains(normalized);
    });

    if (hasTextMatch) {
      return true;
    }

    if (selectedKey == 'barang' && _normalizeText(product.type) == 'physical') {
      return true;
    }

    return false;
  }

  List<ShopProduct> _filteredHomeProducts() {
    final products = _dashboard?.merchandise.products ?? const <ShopProduct>[];
    final selectedKey = _selectedCategoryKey;

    if (selectedKey == null || selectedKey.isEmpty || selectedKey == 'all') {
      return products;
    }

    return products
        .where((product) => _matchesCategory(product, selectedKey))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = context.watch<AuthProvider>().isAuthenticated;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primaryBlue,
        child: CustomScrollView(
          slivers: [
            // Gradient AppBar / Hero
            SliverToBoxAdapter(child: _buildHero(isAuth)),
            // Guest login prompt
            if (!isAuth) SliverToBoxAdapter(child: _buildGuestBanner()),
            // Categories
            SliverToBoxAdapter(child: _buildCategories()),
            // Products header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Produk Unggulan 🛍️',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/shop/products'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Product Grid
            _loading ? _buildSkeletonGrid() : _buildProductGrid(),
            // Social Proof
            SliverToBoxAdapter(child: _buildSocialProof()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool isAuth) {
    final hero = _dashboard?.hero;

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.heroGradient),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('F',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20)),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Fomi Shop',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.darkBlue)),
              const Spacer(),
              if (isAuth)
                GestureDetector(
                  onTap: () => context.push('/cart'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Consumer<CartProvider>(
                      builder: (context, cart, _) => Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.shopping_cart_outlined,
                              color: AppColors.primaryBlue, size: 22),
                          if (cart.count > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                                child: Center(
                                  child: Text('${cart.count}',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 8)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Left card (ORANG)
              _buildHeroCard(
                tag: hero?.leftCardTag ?? 'ORANG',
                imageUrl: hero?.leftCardImage,
                fallbackIcon: Icons.child_care,
              ),
              const SizedBox(width: 16),
              // Center text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      hero?.title ?? 'If Found...\nScan Me Home',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkBlue,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Subscribe button (always shown)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/shop/subscription'),
                        icon: const Icon(Icons.stars_rounded, size: 16),
                        label: const Text('Langganan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!isAuth)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.push('/login'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.primaryBlue, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Masuk / Daftar',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue)),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      hero?.subtitle ??
                          'Gunakan teknologi FOMI untuk tetap terhubung.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right card (BARANG)
              _buildHeroCard(
                tag: hero?.rightCardTag ?? 'BARANG',
                imageUrl: hero?.rightCardImage,
                fallbackIcon: Icons.inventory_2_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestBanner() {
    return GestureDetector(
      onTap: () => context.push('/login'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.softBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.skyBlue, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.login_rounded,
                color: AppColors.primaryBlue, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Masuk untuk akses keranjang & checkout',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AppColors.primaryBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
      {required String tag, String? imageUrl, required IconData fallbackIcon}) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 80,
                    height: 90,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 80,
                      height: 90,
                      color: AppColors.softBlue,
                      child: Icon(fallbackIcon,
                          color: AppColors.primaryBlue, size: 36),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 90,
                    color: AppColors.softBlue,
                    child: Icon(fallbackIcon,
                        color: AppColors.primaryBlue, size: 36),
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Text(
              tag,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    if (_loading) {
      return Container(
        height: 90,
        padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) =>
              const SkeletonLoader(width: 80, height: 36, borderRadius: 20),
        ),
      );
    }

    final allItems = _homeCategoryItems();

    if (allItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kategori',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = allItems[index];
                final selected = (_selectedCategoryKey ?? 'all') == item.key;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategoryKey =
                        item.key == 'all' ? null : item.key);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryBlue
                            : AppColors.skyBlue,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lightBlue.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.primaryBlue,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const ProductCardSkeleton(),
          childCount: 4,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.62,
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = _filteredHomeProducts();
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.storefront_outlined,
                    size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('Tidak ada produk pada kategori ini',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => context.push('/shop/products'),
                  child: const Text(
                    'Lihat semua produk',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildProductCard(products[index]),
          childCount: products.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.62,
        ),
      ),
    );
  }

  Widget _buildProductCard(ShopProduct product) {
    return GestureDetector(
      onTap: () => context.push('/shop/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightBlue.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _productPlaceholder(),
                    )
                  : _productPlaceholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.type.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      _formatPrice(product.price),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                context.push('/shop/products/${product.id}'),
                            child: Container(
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.primaryBlue, width: 1.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Detail',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _quickAddToCart(product),
                            child: Container(
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  AppColors.primaryBlue,
                                  AppColors.midBlue
                                ]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    product.hasVariants ? 'Pilih' : 'Tambah',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      height: 130,
      width: double.infinity,
      color: AppColors.softBlue,
      child: const Icon(Icons.image_outlined,
          size: 40, color: AppColors.primaryBlue),
    );
  }

  void _quickAddToCart(ShopProduct product) {
    if (product.hasVariants) {
      context.push('/shop/products/${product.id}');
      return;
    }
    final cartItem = CartItemModel(
      id: product.id,
      productId: product.id,
      cartKey: '${product.id}:base',
      name: product.name,
      baseName: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
      type: product.type,
      stock: product.stock,
      quantity: 1,
    );
    context.read<CartProvider>().addToCart(cartItem).then((ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? '${product.name} ditambahkan ke keranjang!'
                : 'Stok habis!'),
            backgroundColor: ok ? AppColors.success : Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  }

  Widget _buildSocialProof() {
    final sp = _dashboard?.socialProof;
    if (sp == null && !_loading) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.midBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                const Text(
                  'Have peace of mind your loved ones are safe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _socialStat('${sp?.customerCount ?? 500}+', 'Pengguna'),
                    Container(width: 1, height: 40, color: Colors.white30),
                    _socialStat('⭐ ${sp?.rating ?? 4.9}', 'Rating'),
                    Container(width: 1, height: 40, color: Colors.white30),
                    _socialStat('${sp?.totalReviews ?? 1200}+', 'Ulasan'),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _socialStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _CategoryChipItem {
  const _CategoryChipItem({required this.key, required this.label});

  final String key;
  final String label;
}
