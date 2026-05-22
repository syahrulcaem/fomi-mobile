import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/shop_theme.dart';
import '../../models/shop_product_model.dart';
import '../../models/cart_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/shop_service.dart';
import '../../services/renewal_service.dart';
import '../../models/renewal_package_model.dart';
import '../../widgets/skeleton_loader.dart';

class ShopHomeScreen extends StatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  bool _loading = true;
  bool _subLoading = true;
  String? _selectedCategoryKey;
  List<ShopProduct> _homeProducts = const [];
  List<RenewalPackageModel> _packages = [];

  static const _fixedCategories = [
    _Cat(key: 'all', label: 'Semua', icon: Icons.apps_rounded),
    _Cat(key: 'barang', label: 'Barang', icon: Icons.inventory_2_outlined),
    _Cat(key: 'hewan', label: 'Hewan', icon: Icons.pets_outlined),
    _Cat(key: 'orang', label: 'Orang', icon: Icons.person_pin_outlined),
  ];

  static const _staticPlans = [
    {
      'name': 'Paket Hemat 1 QR',
      'price': 2000,
      'duration': '30 hari',
      'qr': 1,
      'featured': false,
    },
    {
      'name': 'Paket Starter 5 QR',
      'price': 25000,
      'duration': '30 hari',
      'qr': 5,
      'featured': true,
    },
    {
      'name': 'Paket Growth 10 QR',
      'price': 59000,
      'duration': '90 hari',
      'qr': 10,
      'featured': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _loadSubscriptions();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final products = await context.read<ShopService>().getProducts();
      if (!mounted) return;
      setState(() => _homeProducts = products);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat produk.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _subLoading = true);
    try {
      final data = await context.read<RenewalService>().getPackages();
      if (!mounted) return;
      setState(() => _packages = data);
    } catch (_) {
      // fallback to static
    } finally {
      if (mounted) setState(() => _subLoading = false);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_load(), _loadSubscriptions()]);
  }

  List<ShopProduct> get _filtered {
    final key = _selectedCategoryKey;
    if (key == null || key == 'all') return _homeProducts;
    return _homeProducts.where((p) {
      final vals = [p.name, p.type, p.category ?? '']
          .map((s) => s.toLowerCase())
          .toList();
      if (key == 'barang') {
        return vals.any((v) => v.contains('barang') || v == 'physical');
      }
      return vals.any((v) => v.contains(key));
    }).toList();
  }

  String _price(int p) {
    final s = p.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  void _quickAdd(ShopProduct product) {
    if (product.hasVariants) {
      context.push('/shop/products/${product.id}');
      return;
    }
    final item = CartItemModel(
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
    context.read<CartProvider>().addToCart(item).then((ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? '${product.name} ditambahkan!' : 'Stok habis!'),
          backgroundColor: ok ? SC.red : Colors.grey,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = context.watch<AuthProvider>().isAuthenticated;
    return Scaffold(
      backgroundColor: SC.bg,
      body: RefreshIndicator(
        color: SC.red,
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(isAuth)),
            SliverToBoxAdapter(child: _buildSubscriptionSection()),
            SliverToBoxAdapter(child: _buildCategoryChips()),
            SliverToBoxAdapter(child: _buildProductsHeader()),
            if (_loading) _buildSkeletonGrid() else _buildProductGrid(),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isAuth) {
    return Container(
      color: SC.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: SC.redGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.shield_rounded, color: SC.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FOMI Store',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: SC.textPrimary,
                ),
              ),
              Text(
                'Lengkapi perlindungan barangmu',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: SC.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isAuth)
            GestureDetector(
              onTap: () => context.push('/cart'),
              child: Consumer<CartProvider>(
                builder: (_, cart, __) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: SC.redLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_cart_outlined,
                          color: SC.red, size: 20),
                    ),
                    if (cart.count > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                              color: SC.red, shape: BoxShape.circle),
                          child: Center(
                            child: Text('${cart.count}',
                                style: const TextStyle(
                                    color: SC.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Subscription Plans Section (replaces highlight + trust bar) ────────────
  Widget _buildSubscriptionSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title + "Lihat Semua" link
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: SC.redGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.stars_rounded,
                    color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Paket Langganan',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: SC.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/shop/subscription'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: SC.redLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SC.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_subLoading)
            _buildSubSkeleton()
          else
            _buildSubCards(),
        ],
      ),
    );
  }

  Widget _buildSubSkeleton() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const SkeletonLoader(
          width: 200,
          height: 160,
          borderRadius: 16,
        ),
      ),
    );
  }

  Widget _buildSubCards() {
    final plans = _packages.isNotEmpty
        ? _packages
            .asMap()
            .entries
            .map((e) => _subCardFromApi(e.value, e.key == 1))
            .toList()
        : _staticPlans
            .asMap()
            .entries
            .map((e) =>
                _subCardStatic(e.value, e.value['featured'] as bool))
            .toList();

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: plans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => plans[i],
      ),
    );
  }

  Widget _subCardFromApi(RenewalPackageModel pkg, bool featured) {
    return _SubCard(
      name: pkg.name,
      priceLabel: _price(pkg.price.toInt()),
      tag: '${pkg.barcodeQuota} QR',
      featured: featured,
      onTap: () => context.push('/shop/subscription'),
    );
  }

  Widget _subCardStatic(Map<String, dynamic> plan, bool featured) {
    return _SubCard(
      name: plan['name'] as String,
      priceLabel: _price(plan['price'] as int),
      tag: '${plan['qr']} QR · ${plan['duration']}',
      featured: featured,
      onTap: () => context.push('/shop/subscription'),
    );
  }

  // ── Category chips ────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 10),
            child: Text(
              'Kategori',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: SC.textPrimary,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _fixedCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _fixedCategories[i];
                final sel = (_selectedCategoryKey ?? 'all') == cat.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryKey =
                      cat.key == 'all' ? null : cat.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? SC.red : SC.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? SC.red : SC.redSoft,
                        width: 1.5,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: SC.red.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon,
                            size: 12, color: sel ? SC.white : SC.red),
                        const SizedBox(width: 5),
                        Text(
                          cat.label,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel ? SC.white : SC.red,
                          ),
                        ),
                      ],
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

  // ── Products header ───────────────────────────────────────────────────────
  Widget _buildProductsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Produk Unggulan',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: SC.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/shop/products'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SC.redLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SC.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const ProductCardSkeleton(),
          childCount: 4,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.60,
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = _filtered;
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.storefront_outlined,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Tidak ada produk di kategori ini',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: SC.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _buildProductCard(products[i]),
          childCount: products.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.60,
        ),
      ),
    );
  }

  Widget _buildProductCard(ShopProduct product) {
    return GestureDetector(
      onTap: () => context.push('/shop/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: SC.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: SC.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  product.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          height: 128,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _imgPlaceholder(),
                        )
                      : _imgPlaceholder(),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: ShopWidgets.fomiBadge(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _typeBadge(product.type),
                    const SizedBox(height: 5),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: SC.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _price(product.price),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: SC.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _quickAdd(product),
                      child: Container(
                        height: 32,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: SC.redGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: SC.redShadow,
                        ),
                        child: Center(
                          child: Text(
                            product.hasVariants ? 'Lihat' : 'Tambah',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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

  Widget _imgPlaceholder() => Container(
        height: 128,
        width: double.infinity,
        color: SC.redLight,
        child: const Icon(Icons.qr_code_2_rounded, size: 48, color: SC.red),
      );

  Widget _typeBadge(String type) {
    final t = type.toLowerCase();
    final isDigital = t == 'digital';
    final label = isDigital ? 'DIGITAL' : 'FISIK';
    final bg = isDigital ? SC.successLight : const Color(0xFFF5F5F5);
    final fg = isDigital ? SC.success : SC.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 8, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ─── Subscription compact card ────────────────────────────────────────────────
class _SubCard extends StatelessWidget {
  const _SubCard({
    required this.name,
    required this.priceLabel,
    required this.tag,
    required this.featured,
    required this.onTap,
  });

  final String name;
  final String priceLabel;
  final String tag;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: featured ? SC.redGradient : null,
          color: featured ? null : SC.white,
          borderRadius: BorderRadius.circular(18),
          border: featured ? null : Border.all(color: SC.redSoft, width: 1.5),
          boxShadow: featured ? SC.redShadow : SC.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: featured
                        ? Colors.white.withOpacity(0.25)
                        : SC.redLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    featured ? '⭐ POPULER' : 'LANGGANAN',
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: featured ? Colors.white : SC.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: featured ? Colors.white : SC.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              priceLabel,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: featured ? Colors.white : SC.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tag,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: featured
                    ? Colors.white.withOpacity(0.8)
                    : SC.textSecondary,
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: featured ? Colors.white : SC.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'Pilih Paket',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: featured ? SC.red : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cat {
  const _Cat({required this.key, required this.label, required this.icon});
  final String key;
  final String label;
  final IconData icon;
}
