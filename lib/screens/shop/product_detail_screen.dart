import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/product_type.dart';
import '../../models/shop_product_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/shop_service.dart';
import '../../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  ShopProduct? _product;
  ProductVariant? _selectedVariant;
  late AnimationController _variantsController;
  late Animation<double> _variantsAnimation;

  @override
  void initState() {
    super.initState();
    _variantsController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _variantsAnimation =
        CurvedAnimation(parent: _variantsController, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _variantsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = context.read<ShopService>();
      final data = await service.getProductDetail(widget.productId);
      if (!mounted) return;
      setState(() => _product = data);
      if (data.hasVariants) _variantsController.forward();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memuat produk.')));
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

  int get _displayPrice {
    if (_selectedVariant != null) return _selectedVariant!.price;
    return _product?.price ?? 0;
  }

  void _addToCart({bool buyNow = false}) {
    final product = _product;
    if (product == null) return;

    if (product.hasVariants && _selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih varian terlebih dahulu!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final variant = _selectedVariant;
    final cartKey =
        variant != null ? '${product.id}:${variant.id}' : '${product.id}:base';
    final itemName = variant != null
        ? '${product.name} (${variant.displayName})'
        : product.name;
    final price = variant?.price ?? product.price;
    final stock = variant?.stock ?? product.stock;

    if (isPhysicalProductType(product.type) && stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Stok habis!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
      );
      return;
    }

    final item = CartItemModel(
      id: product.id,
      productId: product.id,
      cartKey: cartKey,
      name: itemName,
      baseName: product.name,
      variantId: variant?.id,
      variantLabel: variant?.displayName,
      attributeName: variant?.attributeName,
      attributeValue: variant?.attributeValue,
      price: price,
      imageUrl: product.imageUrl,
      type: product.type,
      stock: stock,
      quantity: 1,
    );

    context.read<CartProvider>().addToCart(item).then((ok) {
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemName ditambahkan!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        if (buyNow) context.push('/cart');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Stok tidak mencukupi!'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _product == null
              ? const Center(child: Text('Produk tidak ditemukan'))
              : Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        // Hero Image
                        SliverAppBar(
                          expandedHeight: 300,
                          pinned: true,
                          backgroundColor: Colors.white,
                          leading: GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  color: AppColors.textPrimary, size: 18),
                            ),
                          ),
                          actions: [
                            GestureDetector(
                              onTap: () => context.push('/cart'),
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle),
                                child: Consumer<CartProvider>(
                                  builder: (context, cart, _) => Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(Icons.shopping_cart_outlined,
                                          color: AppColors.primaryBlue,
                                          size: 22),
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
                          flexibleSpace: FlexibleSpaceBar(
                            background: _product!.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: _product!.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _imagePlaceholder(),
                                  )
                                : _imagePlaceholder(),
                          ),
                        ),
                        // Content
                        SliverToBoxAdapter(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(28)),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 24, 20, 120),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: AppColors.softBlue,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Text(
                                          _product!.type.toUpperCase(),
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      if (_product!.type == 'digital' &&
                                          _product!.durationDays != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Text(
                                            '${_product!.durationDays} Hari',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(_product!.name,
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 8),
                                  Text(_formatPrice(_displayPrice),
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primaryBlue)),
                                  if (_product!.description != null) ...[
                                    const SizedBox(height: 16),
                                    const Text('Deskripsi',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary)),
                                    const SizedBox(height: 6),
                                    Text(_product!.description!,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                            height: 1.5)),
                                  ],
                                  // Variants
                                  if (_product!.hasVariants) ...[
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        const Text('Pilih Varian',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary)),
                                        const SizedBox(width: 8),
                                        if (_selectedVariant == null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: Colors
                                                        .orange.shade200)),
                                            child: const Text('Wajib dipilih',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.orange,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    FadeTransition(
                                      opacity: _variantsAnimation,
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _product!.variants.map((v) {
                                          final isSelected =
                                              _selectedVariant?.id == v.id;
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() => _selectedVariant =
                                                  isSelected ? null : v);
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.primaryBlue
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.primaryBlue
                                                      : AppColors.skyBlue,
                                                  width: 1.5,
                                                ),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                            color: AppColors
                                                                .primaryBlue
                                                                .withOpacity(
                                                                    0.3),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                    0, 3))
                                                      ]
                                                    : [],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(v.displayName,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isSelected
                                                              ? Colors.white
                                                              : AppColors
                                                                  .textPrimary)),
                                                  if (v.stock <= 5 &&
                                                      v.stock > 0)
                                                    Text('Sisa ${v.stock}',
                                                        style: TextStyle(
                                                            fontSize: 9,
                                                            color: isSelected
                                                                ? Colors.white70
                                                                : Colors
                                                                    .orange)),
                                                  if (v.stock <= 0)
                                                    Text('Habis',
                                                        style: TextStyle(
                                                            fontSize: 9,
                                                            color: isSelected
                                                                ? Colors.white54
                                                                : Colors.red)),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                  // Stock info
                                  const SizedBox(height: 16),
                                  Row(children: [
                                    Icon(Icons.inventory_2_outlined,
                                        size: 16,
                                        color: AppColors.textSecondary
                                            .withOpacity(0.7)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Stok: ${_selectedVariant?.stock ?? _product!.stock}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Bottom sticky bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 16,
                          bottom: MediaQuery.of(context).padding.bottom + 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                blurRadius: 16,
                                offset: const Offset(0, -4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _addToCart(),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.primaryBlue, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('+ Keranjang',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryBlue)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _addToCart(buyNow: true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Beli Sekarang',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
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

  Widget _imagePlaceholder() => Container(
        color: AppColors.softBlue,
        child: const Center(
            child: Icon(Icons.image_outlined,
                size: 80, color: AppColors.primaryBlue)),
      );
}
