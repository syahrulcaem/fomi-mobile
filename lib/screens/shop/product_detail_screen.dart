import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/shop_theme.dart';
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
      final data = await context.read<ShopService>().getProductDetail(widget.productId);
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

  String _fmt(int p) {
    final s = p.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  int get _displayPrice => _selectedVariant?.price ?? _product?.price ?? 0;

  void _addToCart({bool buyNow = false}) {
    final product = _product;
    if (product == null) return;
    if (product.hasVariants && _selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Pilih varian terlebih dahulu!'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    final v = _selectedVariant;
    final cartKey = v != null ? '${product.id}:${v.id}' : '${product.id}:base';
    final itemName = v != null ? '${product.name} (${v.displayName})' : product.name;
    final price = v?.price ?? product.price;
    final stock = v?.stock ?? product.stock;

    if (isPhysicalProductType(product.type) && stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Stok habis!'),
          backgroundColor: SC.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      return;
    }

    final item = CartItemModel(
      id: product.id,
      productId: product.id,
      cartKey: cartKey,
      name: itemName,
      baseName: product.name,
      variantId: v?.id,
      variantLabel: v?.displayName,
      attributeName: v?.attributeName,
      attributeValue: v?.attributeValue,
      price: price,
      imageUrl: product.imageUrl,
      type: product.type,
      stock: stock,
      quantity: 1,
    );

    context.read<CartProvider>().addToCart(item).then((ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '$itemName ditambahkan!' : 'Stok tidak mencukupi!'),
        backgroundColor: ok ? SC.red : Colors.grey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      if (ok && buyNow) context.push('/cart');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SC.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SC.red))
          : _product == null
              ? const Center(child: Text('Produk tidak ditemukan'))
              : Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 300,
                          pinned: true,
                          backgroundColor: SC.white,
                          leading: GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: SC.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: SC.cardShadow),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  color: SC.red, size: 16),
                            ),
                          ),
                          actions: [
                            GestureDetector(
                              onTap: () => context.push('/cart'),
                              child: Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                    color: SC.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: SC.cardShadow),
                                child: Consumer<CartProvider>(
                                  builder: (_, cart, __) => Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(Icons.shopping_cart_outlined,
                                          color: SC.red, size: 22),
                                      if (cart.count > 0)
                                        Positioned(
                                          right: -4, top: -4,
                                          child: Container(
                                            width: 15, height: 15,
                                            decoration: const BoxDecoration(
                                                color: SC.red,
                                                shape: BoxShape.circle),
                                            child: Center(child: Text(
                                              '${cart.count}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800))),
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
                                    errorWidget: (_, __, ___) => _imgPlaceholder(),
                                  )
                                : _imgPlaceholder(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: SC.white,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(28)),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 24, 20, 120),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Badges
                                  Wrap(
                                    spacing: 8, runSpacing: 6,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: SC.redLight,
                                            borderRadius: BorderRadius.circular(10)),
                                        child: Text(
                                          _product!.type.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: SC.red,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      ShopWidgets.fomiBadge(),
                                      if (_product!.type == 'digital' &&
                                          _product!.durationDays != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: SC.successLight,
                                              borderRadius: BorderRadius.circular(10)),
                                          child: Text(
                                            '${_product!.durationDays} Hari',
                                            style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: SC.success,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(_product!.name,
                                      style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: SC.textPrimary)),
                                  const SizedBox(height: 8),
                                  Text(_fmt(_displayPrice),
                                      style: GoogleFonts.poppins(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: SC.red)),
                                  if (_product!.description != null) ...[
                                    const SizedBox(height: 16),
                                    Text('Deskripsi',
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: SC.textPrimary)),
                                    const SizedBox(height: 6),
                                    Text(_product!.description!,
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: SC.textSecondary,
                                            height: 1.6)),
                                  ],
                                  // Variants
                                  if (_product!.hasVariants) ...[
                                    const SizedBox(height: 20),
                                    Row(children: [
                                      Text('Pilih Varian',
                                          style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: SC.textPrimary)),
                                      const SizedBox(width: 8),
                                      if (_selectedVariant == null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: SC.redLight,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: SC.redSoft)),
                                          child: Text('Wajib dipilih',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  color: SC.red,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                    ]),
                                    const SizedBox(height: 12),
                                    FadeTransition(
                                      opacity: _variantsAnimation,
                                      child: Wrap(
                                        spacing: 8, runSpacing: 8,
                                        children: _product!.variants.map((v) {
                                          final sel = _selectedVariant?.id == v.id;
                                          return GestureDetector(
                                            onTap: () => setState(() =>
                                                _selectedVariant = sel ? null : v),
                                            child: AnimatedContainer(
                                              duration:
                                                  const Duration(milliseconds: 200),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: sel ? SC.red : SC.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: sel ? SC.red : SC.redSoft,
                                                  width: 1.5,
                                                ),
                                                boxShadow: sel ? SC.redShadow : [],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(v.displayName,
                                                      style: GoogleFonts.poppins(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: sel
                                                              ? Colors.white
                                                              : SC.textPrimary)),
                                                  if (v.stock <= 5 && v.stock > 0)
                                                    Text('Sisa ${v.stock}',
                                                        style: TextStyle(
                                                            fontSize: 9,
                                                            color: sel
                                                                ? Colors.white70
                                                                : Colors.orange)),
                                                  if (v.stock <= 0)
                                                    Text('Habis',
                                                        style: TextStyle(
                                                            fontSize: 9,
                                                            color: sel
                                                                ? Colors.white54
                                                                : SC.red)),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(children: [
                                    Icon(Icons.inventory_2_outlined,
                                        size: 16,
                                        color: SC.textSecondary.withOpacity(0.7)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Stok: ${_selectedVariant?.stock ?? _product!.stock}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12, color: SC.textSecondary),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Bottom sticky CTA
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: EdgeInsets.only(
                          left: 20, right: 20, top: 16,
                          bottom: MediaQuery.of(context).padding.bottom + 16,
                        ),
                        decoration: BoxDecoration(
                          color: SC.white,
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(24)),
                          boxShadow: [
                            BoxShadow(
                                color: SC.red.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, -4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _addToCart(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: SC.white,
                                    border: Border.all(color: SC.red, width: 1.5),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: Text('+ Keranjang',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: SC.red)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _addToCart(buyNow: true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: SC.redGradient,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: SC.redShadow,
                                  ),
                                  child: Center(
                                    child: Text('Beli Sekarang',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
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
    );
  }

  Widget _imgPlaceholder() => Container(
        color: SC.redLight,
        child: const Center(
            child: Icon(Icons.qr_code_2_rounded, size: 80, color: SC.red)),
      );
}
