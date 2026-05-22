import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/shop_theme.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/empty_state.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  String _fmt(int p) {
    final s = p.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: SC.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: SC.white,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: SC.redLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: SC.red),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Keranjang',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: SC.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (cart.count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: SC.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${cart.count} item',
                        style: GoogleFonts.poppins(
                            color: SC.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            // Cart items
            Expanded(
              child: cart.isEmpty
                  ? EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Keranjang kosong',
                      subtitle: 'Yuk belanja dulu di FOMI Store!',
                      action: () => context.go('/shop'),
                      actionLabel: 'Ke Toko',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final item = cart.items[i];
                        return Dismissible(
                          key: Key(item.cartKey),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => cart.removeItem(item.cartKey),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: SC.redLight,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: SC.red, size: 26),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: SC.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: SC.cardShadow,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: item.imageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: item.imageUrl!,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              _imgPlaceholder(),
                                        )
                                      : _imgPlaceholder(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.baseName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: SC.textPrimary,
                                        ),
                                      ),
                                      if (item.variantLabel != null) ...[
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: SC.redLight,
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Text(item.variantLabel!,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  color: SC.red,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Text(
                                        _fmt(item.price),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: SC.red,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _qtyBtn(
                                            icon: Icons.remove,
                                            onTap: () => cart.updateQuantity(
                                                item.cartKey,
                                                item.quantity - 1),
                                          ),
                                          Container(
                                            width: 36,
                                            alignment: Alignment.center,
                                            child: Text('${item.quantity}',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: SC.textPrimary)),
                                          ),
                                          _qtyBtn(
                                            icon: Icons.add,
                                            onTap: () => cart.updateQuantity(
                                                item.cartKey,
                                                item.quantity + 1),
                                            isAdd: true,
                                          ),
                                          const Spacer(),
                                          Text(
                                            _fmt(item.subtotal),
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: SC.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => cart.removeItem(item.cartKey),
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.close,
                                        size: 18, color: SC.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Bottom total
            if (cart.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: SC.white,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                        color: SC.red.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4))
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                    20, 16, 20, MediaQuery.of(context).padding.bottom + 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: SC.textSecondary)),
                        Text(_fmt(cart.total),
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: SC.textSecondary)),
                      ],
                    ),
                    Divider(height: 16, color: Colors.grey.shade200),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: SC.textPrimary)),
                        Text(_fmt(cart.total),
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: SC.red)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ShopWidgets.primaryButton(
                      label: 'Checkout',
                      onTap: () => context.push('/checkout'),
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        width: 72,
        height: 72,
        color: SC.redLight,
        child: const Icon(Icons.image_outlined, size: 28, color: SC.red),
      );

  Widget _qtyBtn(
      {required IconData icon,
      required VoidCallback onTap,
      bool isAdd = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isAdd ? SC.red : SC.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isAdd ? SC.red : SC.redSoft, width: 1.5),
        ),
        child: Icon(icon, size: 16, color: isAdd ? SC.white : SC.red),
      ),
    );
  }
}
