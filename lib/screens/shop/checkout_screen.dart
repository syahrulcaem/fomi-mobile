import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../core/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../services/shop_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  bool _loading = false;
  bool _orderSummaryExpanded = true;

  bool get _hasPhysical {
    final cart = context.read<CartProvider>();
    return cart.items.any((e) => e.type == 'physical');
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
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartProvider>();

    setState(() => _loading = true);
    try {
      final service = context.read<ShopService>();
      final data = <String, dynamic>{
        'items': cart.items.map((e) => {
              'product_id': e.productId,
              'variant_id': e.variantId,
              'quantity': e.quantity,
            }).toList(),
        'customer_name': _nameCtrl.text.trim(),
        'customer_email': _emailCtrl.text.trim(),
        'customer_phone': _phoneCtrl.text.trim(),
      };

      if (_hasPhysical) {
        data['shipping_address'] = _addressCtrl.text.trim();
        data['shipping_city'] = _cityCtrl.text.trim();
        data['shipping_province'] = _provinceCtrl.text.trim();
        data['shipping_postal_code'] = _postalCtrl.text.trim();
      }

      final result = await service.checkout(data);
      if (!mounted) return;

      final snapToken = result['snap_token']?.toString() ?? '';
      final redirectUrl = result['redirect_url']?.toString() ?? '';
      final orderId = (result['order'] as Map?)?['payment']?['midtrans_order_id']?.toString() ?? '';

      if (redirectUrl.isNotEmpty) {
        context.push('/shop/payment?snapUrl=${Uri.encodeComponent(redirectUrl)}&orderId=${Uri.encodeComponent(orderId)}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan link pembayaran.'), backgroundColor: Colors.red),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final body = e.response?.data;
      String msg = 'Checkout gagal.';
      if (body is Map<String, dynamic>) {
        final apiMsg = body['message']?.toString();
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) msg = first.first.toString();
        } else if (apiMsg != null) {
          msg = apiMsg;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(gradient: AppGradients.heroGradient),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Checkout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Summary
                      _buildOrderSummary(cart),
                      const SizedBox(height: 16),
                      // Form
                      _sectionTitle('Informasi Penerima'),
                      const SizedBox(height: 12),
                      _field(ctrl: _nameCtrl, label: 'Nama Lengkap', icon: Icons.person_outline, required: true),
                      const SizedBox(height: 12),
                      _field(ctrl: _emailCtrl, label: 'Email', icon: Icons.email_outlined, required: true, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _field(ctrl: _phoneCtrl, label: 'Nomor HP', icon: Icons.phone_outlined, required: true, keyboardType: TextInputType.phone),
                      if (_hasPhysical) ...[
                        const SizedBox(height: 20),
                        _sectionTitle('Alamat Pengiriman'),
                        const SizedBox(height: 12),
                        _field(ctrl: _addressCtrl, label: 'Alamat Lengkap', icon: Icons.location_on_outlined, required: true, maxLines: 2),
                        const SizedBox(height: 12),
                        _field(ctrl: _cityCtrl, label: 'Kota', icon: Icons.location_city_outlined, required: true),
                        const SizedBox(height: 12),
                        _field(ctrl: _provinceCtrl, label: 'Provinsi', icon: Icons.map_outlined, required: true),
                        const SizedBox(height: 12),
                        _field(ctrl: _postalCtrl, label: 'Kode Pos', icon: Icons.markunread_mailbox_outlined, required: true, keyboardType: TextInputType.number),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
            // Pay button
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      Text(_formatPrice(cart.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _pay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Bayar Sekarang 💳', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.lightBlue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _orderSummaryExpanded = !_orderSummaryExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, color: AppColors.primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  const Text('Ringkasan Pesanan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const Spacer(),
                  Icon(_orderSummaryExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (_orderSummaryExpanded)
            ...cart.items.map((item) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.baseName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            if (item.variantLabel != null)
                              Text(item.variantLabel!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Text('x${item.quantity}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(width: 12),
                      Text(_formatPrice(item.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryBlue)),
                    ],
                  ),
                )),
          Divider(color: AppColors.skyBlue.withOpacity(0.5), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(_formatPrice(cart.total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primaryBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.skyBlue)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.skyBlue)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
      ),
    );
  }
}
