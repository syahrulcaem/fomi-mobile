import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../services/renewal_service.dart';
import '../../services/shop_service.dart';
import '../../providers/cart_provider.dart';
import '../../models/renewal_package_model.dart';
import 'package:dio/dio.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = false;
  List<RenewalPackageModel> _packages = [];

  // Fallback static plans matching website
  final _staticPlans = [
    {
      'name': 'Paket Hemat 1 QR',
      'price': 2000,
      'duration': '30 hari',
      'qr': 1,
      'benefits': ['Perlindungan optimal 30 hari', 'Notifikasi real-time & Chat', 'Support prioritas Fomi'],
      'featured': false,
    },
    {
      'name': 'Paket Starter 5 QR',
      'price': 25000,
      'duration': '30 hari',
      'qr': 5,
      'benefits': ['Perlindungan optimal 30 hari', 'Notifikasi real-time & Chat', 'Support prioritas Fomi'],
      'featured': true,
    },
    {
      'name': 'Paket Growth 10 QR',
      'price': 59000,
      'duration': '90 hari',
      'qr': 10,
      'benefits': ['Perlindungan optimal 90 hari', 'Notifikasi real-time & Chat', 'Support prioritas Fomi'],
      'featured': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = context.read<RenewalService>();
      final data = await service.getPackages();
      if (!mounted) return;
      setState(() => _packages = data);
    } catch (_) {
      // fallback to static plans
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkout(RenewalPackageModel item) async {
    setState(() => _loading = true);
    try {
      final service = context.read<RenewalService>();
      final result = await service.checkoutRenewal(productId: item.id);
      if (!mounted) return;
      final snapUrl = result.resolvedSnapUrl;
      if (snapUrl != null && snapUrl.isNotEmpty) {
        context.push('/shop/payment?snapUrl=${Uri.encodeComponent(snapUrl)}&orderId=${Uri.encodeComponent(result.orderId ?? '')}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Snap URL tidak tersedia.')));
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data as Map?)?['message']?.toString() ?? 'Checkout gagal.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
                decoration: const BoxDecoration(gradient: AppGradients.heroGradient),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20, right: 20, bottom: 28,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.canPop() ? context.pop() : context.go('/dashboard'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Subscription Plans',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.darkBlue),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aktifkan langganan sebelum Anda scan dan aktivasi merchandise FOMI.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Use API packages if available, else static plans
                          if (_packages.isNotEmpty)
                            ..._packages.asMap().entries.map((entry) => _buildApiCard(entry.value, entry.key == 1))
                          else
                            ..._staticPlans.asMap().entries.map(
                                  (entry) => _buildStaticCard(
                                    entry.value,
                                    entry.value['featured'] as bool,
                                  ),
                                ),
                        ],
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticCard(Map<String, dynamic> plan, bool featured) {
    final benefits = plan['benefits'] as List<String>;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: featured ? Border.all(color: AppColors.primaryBlue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: featured ? AppColors.primaryBlue.withOpacity(0.25) : AppColors.lightBlue.withOpacity(0.2),
            blurRadius: featured ? 20 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('PAKET LANGGANAN', style: TextStyle(fontSize: 9, color: AppColors.primaryBlue, fontWeight: FontWeight.w800)),
                ),
                if (featured) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('POPULER', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Text(plan['name'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPrice(plan['price'] as int),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('/ ${plan['duration']}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: AppColors.primaryBlue.withOpacity(0.8)),
                      const SizedBox(width: 8),
                      Text(b, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/renewal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: const Text('Pilih Paket Ini', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiCard(RenewalPackageModel pkg, bool featured) {
    final benefits = ['Perlindungan optimal', 'Notifikasi real-time & Chat', 'Support prioritas Fomi'];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: featured ? Border.all(color: AppColors.primaryBlue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: featured ? AppColors.primaryBlue.withOpacity(0.25) : AppColors.lightBlue.withOpacity(0.2),
            blurRadius: featured ? 20 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.softBlue, borderRadius: BorderRadius.circular(10)),
                  child: const Text('PAKET LANGGANAN', style: TextStyle(fontSize: 9, color: AppColors.primaryBlue, fontWeight: FontWeight.w800)),
                ),
                if (featured) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(10)),
                    child: const Text('POPULER', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Text(pkg.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(_formatPrice(pkg.price.toInt()), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.softBlue, borderRadius: BorderRadius.circular(10)),
              child: Text('${pkg.barcodeQuota} Kuota Barcode', style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            ...benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.primaryBlue.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text(b, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ]),
                )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _checkout(pkg),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: const Text('Pilih Paket Ini', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
