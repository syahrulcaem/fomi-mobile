import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/shop_dashboard_model.dart';
import '../../models/shop_product_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/shop_service.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const double _productCardAspectRatio = 0.56;

  bool _loading = false;
  List<ShopProduct> _products = [];
  List<ShopProduct> _allProducts = [];
  String? _selectedCategory;

  List<String> _categories = const ['All'];

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.initialCategory == 'All' ? null : widget.initialCategory;
    _load();
  }

  Future<void> _load({String? category}) async {
    setState(() => _loading = true);
    try {
      final service = context.read<ShopService>();
      final selected = category ?? _selectedCategory;
      final dashboard = await service.getShopDashboard();
      final data = await service.getProducts();
      final merchandiseOnly =
          data.where((p) => !_isSubscriptionProduct(p)).toList();

      final builtCategories = _buildCategories(dashboard, merchandiseOnly);
      if (selected != null && selected.isNotEmpty) {
        builtCategories.add(selected);
      }

      final uniqueCategories = <String>{};
      final normalizedCategories = <String>[];
      for (final categoryLabel in builtCategories) {
        final cleaned = categoryLabel.trim();
        if (cleaned.isEmpty) {
          continue;
        }
        final key = cleaned.toLowerCase();
        if (uniqueCategories.add(key)) {
          normalizedCategories.add(cleaned);
        }
      }

      if (!mounted) return;
      setState(() {
        _selectedCategory = selected;
        _allProducts = merchandiseOnly;
        _categories =
            normalizedCategories.isEmpty ? const ['All'] : normalizedCategories;
        _products = _applyCategoryFilter(merchandiseOnly, selected);
      });
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

  List<String> _buildCategories(
    ShopDashboardModel dashboard,
    List<ShopProduct> products,
  ) {
    final labels = <String>['All'];
    labels.addAll(dashboard.categories.map((e) => e.name));
    labels.addAll(dashboard.merchandise.filters);
    labels.addAll(
      products
          .map((p) => p.category)
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty),
    );
    return labels;
  }

  List<ShopProduct> _applyCategoryFilter(
    List<ShopProduct> products,
    String? selected,
  ) {
    if (selected == null || selected.trim().isEmpty || selected == 'All') {
      return products;
    }

    final selectedNorm = _normalizeText(selected);

    return products.where((product) {
      final candidates = <String>[
        product.category ?? '',
        product.type,
        product.name,
      ];

      final hasTextMatch = candidates.any((value) {
        final normalized = _normalizeText(value);
        return normalized.contains(selectedNorm) ||
            selectedNorm.contains(normalized);
      });

      if (hasTextMatch) {
        return true;
      }

      // Alias umum agar chip "Barang" tetap bekerja untuk tipe physical.
      if (selectedNorm == 'barang' &&
          _normalizeText(product.type) == 'physical') {
        return true;
      }

      return false;
    }).toList();
  }

  String _normalizeText(String raw) {
    return raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  bool _isSubscriptionProduct(ShopProduct product) {
    final type = _normalizeText(product.type);
    final category = _normalizeText(product.category ?? '');
    final name = _normalizeText(product.name);

    if (type == 'subscription' || type == 'plan' || type == 'package') {
      return true;
    }

    final hints = <String>[category, name];
    final hasSubscriptionHint = hints.any(
      (text) => text.contains('subscription') || text.contains('langganan'),
    );
    if (hasSubscriptionHint) {
      return true;
    }

    // Legacy safeguard: some package products are still sent as digital
    // with package-like naming.
    if (type == 'digital') {
      final hasPackageHint = hints.any((text) => text.contains('paket'));
      if (hasPackageHint) {
        return true;
      }
    }

    return false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primaryBlue,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                decoration:
                    const BoxDecoration(gradient: AppGradients.heroGradient),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.8),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Products',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                        ),
                        const Spacer(),
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
                                            color: Colors.red,
                                            shape: BoxShape.circle),
                                        child: Center(
                                            child: Text('${cart.count}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8))),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Semua merchandise FOMI dalam satu tempat.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    // Filter chips
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = (_selectedCategory == cat) ||
                              (cat == 'All' && _selectedCategory == null);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat == 'All' ? null : cat;
                                _products = _applyCategoryFilter(
                                  _allProducts,
                                  _selectedCategory,
                                );
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : AppColors.skyBlue,
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                            color: AppColors.primaryBlue
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3))
                                      ]
                                    : [],
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Grid
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                      (_, __) => const ProductCardSkeleton(),
                      childCount: 6),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: _productCardAspectRatio,
                  ),
                ),
              )
            else if (_products.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'Tidak ada produk',
                  subtitle: 'Coba pilih kategori lain',
                  action: () => _load(),
                  actionLabel: 'Muat ulang',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildProductCard(_products[index]),
                    childCount: _products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: _productCardAspectRatio,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
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
                offset: const Offset(0, 4))
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
                      height: 112,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(product.type.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 4),
                    Text(product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    if (product.description != null)
                      Text(product.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text(_formatPrice(product.price),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBlue)),
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
                                  child: Text(
                                    'Detail',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _addOrGo(product),
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

  Widget _placeholder() => Container(
        height: 112,
        width: double.infinity,
        color: AppColors.softBlue,
        child: const Icon(Icons.image_outlined,
            size: 40, color: AppColors.primaryBlue),
      );

  void _addOrGo(ShopProduct product) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '${product.name} ditambahkan!' : 'Stok habis!'),
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
}


