import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/shop_theme.dart';
import '../../providers/cart_provider.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, this.orderNumber});
  final String? orderNumber;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _checkAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _fadeCtrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _checkAnim = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 200), () {
      _checkCtrl.forward();
      _fadeCtrl.forward();
    });
    context.read<CartProvider>().clearCart();
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SC.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _checkAnim,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: SC.redGradient,
                        shape: BoxShape.circle,
                        boxShadow: SC.redShadow,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 64, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Pembayaran Berhasil!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: SC.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Terima kasih! Pesananmu sedang diproses.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: SC.textSecondary),
                  ),
                  if (widget.orderNumber != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: SC.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: SC.redSoft, width: 1.5),
                        boxShadow: SC.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Text('Order Number',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: SC.textSecondary)),
                          const SizedBox(height: 4),
                          Text(widget.orderNumber!,
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: SC.red)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ShopWidgets.primaryButton(
                    label: 'Kembali ke Toko',
                    onTap: () => context.go('/shop'),
                    icon: Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 12),
                  ShopWidgets.outlinedButton(
                    label: 'Lihat Pesanan',
                    onTap: () => context.go('/orders'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
