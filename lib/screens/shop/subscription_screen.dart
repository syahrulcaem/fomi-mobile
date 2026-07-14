import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../core/shop_theme.dart';
import '../../services/renewal_service.dart';
import '../../models/renewal_package_model.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = false;
  List<RenewalPackageModel> _packages = [];

  final _staticPlans = [
    {
      'name': 'Paket Hemat 1 QR',
      'price': 2000,
      'duration': '30 hari',
      'qr': 1,
      'benefits': [
        'Perlindungan optimal 30 hari',
        'Notifikasi real-time & Chat',
        'Support prioritas Fomi',
      ],
      'featured': false,
    },
    {
      'name': 'Paket Starter 5 QR',
      'price': 25000,
      'duration': '30 hari',
      'qr': 5,
      'benefits': [
        'Perlindungan optimal 30 hari',
        'Notifikasi real-time & Chat',
        'Support prioritas Fomi',
      ],
      'featured': true,
    },
    {
      'name': 'Paket Growth 10 QR',
      'price': 59000,
      'duration': '90 hari',
      'qr': 10,
      'benefits': [
        'Perlindungan optimal 90 hari',
        'Notifikasi real-time & Chat',
        'Support prioritas Fomi',
      ],
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
      final data = await context.read<RenewalService>().getPackages();
      if (!mounted) return;
      setState(() => _packages = data);
    } catch (_) {
      // fallback to static
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SC.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: SC.red,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                color: SC.white,
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
                        GestureDetector(
                          onTap: () => context.canPop()
                              ? context.pop()
                              : context.go('/shop'),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Subscription Plans',
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: SC.textPrimary)),
                            Text('Aktifkan perlindungan barangmu',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: SC.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Trust bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: SC.redLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _trustItem(
                              Icons.verified_user_rounded, '1000+', 'Pengguna'),
                          Container(width: 1, height: 28, color: SC.redSoft),
                          _trustItem(Icons.star_rounded, '4.9', 'Rating'),
                          Container(width: 1, height: 28, color: SC.redSoft),
                          _trustItem(Icons.lock_rounded, '100%', 'Terproteksi'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Cards
            SliverToBoxAdapter(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                          child: CircularProgressIndicator(color: SC.red)),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        children: _packages.isNotEmpty
                            ? _packages
                                .asMap()
                                .entries
                                .map((e) => _apiCard(e.value, e.key == 1))
                                .toList()
                            : _staticPlans
                                .asMap()
                                .entries
                                .map((e) => _staticCard(
                                    e.value, e.value['featured'] as bool))
                                .toList(),
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _trustItem(IconData icon, String value, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: SC.red),
      const SizedBox(width: 4),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: SC.textPrimary)),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 9, color: SC.textSecondary)),
      ]),
    ]);
  }

  Future<void> _checkout(String? planId) async {
    if (planId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Paket ini tidak dapat dibeli karena merupakan dummy data.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final service = context.read<RenewalService>();
      final result = await service.checkoutRenewal(
        subscriptionPlanId: planId,
        quantity: 1,
        renewalAssetId: null, // Buy new package mode
      );

      if (!mounted) {
        return;
      }

      final snapUrl = result.resolvedSnapUrl;
      if (snapUrl == null || snapUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ??
                  ((result.snapToken != null && result.snapToken!.isNotEmpty)
                      ? 'Token pembayaran diterima, tapi URL tidak bisa dibentuk.'
                      : 'Snap URL/Token tidak tersedia dari API.'),
            ),
          ),
        );
        return;
      }

      context.push(
        '/renewal/payment?snapUrl=${Uri.encodeComponent(snapUrl)}&orderId=${Uri.encodeComponent(result.orderId ?? '')}',
      );
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }

      String msg = 'Checkout langganan gagal. Silakan coba lagi.';
      if (e.response?.data is Map<String, dynamic>) {
        final message = e.response?.data['message']?.toString();
        if (message != null && message.isNotEmpty) {
          msg = message;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Checkout langganan gagal. Silakan coba lagi.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _staticCard(Map<String, dynamic> plan, bool featured) {
    final benefits = plan['benefits'] as List<String>;
    return _PlanCard(
      name: plan['name'] as String,
      price: _fmt(plan['price'] as int),
      subtitle: '${plan['qr']} QR · ${plan['duration']}',
      benefits: benefits,
      featured: featured,
      onTap: () => _checkout(null),
    );
  }

  Widget _apiCard(RenewalPackageModel pkg, bool featured) {
    return _PlanCard(
      name: pkg.name,
      price: _fmt(pkg.price.toInt()),
      subtitle: '${pkg.barcodeQuota} Kuota Barcode',
      benefits: const [
        'Perlindungan optimal',
        'Notifikasi real-time & Chat',
        'Support prioritas Fomi',
      ],
      featured: featured,
      onTap: () => _checkout(pkg.id),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.subtitle,
    required this.benefits,
    required this.featured,
    required this.onTap,
  });

  final String name;
  final String price;
  final String subtitle;
  final List<String> benefits;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: featured ? SC.redGradient : null,
        color: featured ? null : SC.white,
        borderRadius: BorderRadius.circular(20),
        border: featured ? null : Border.all(color: SC.redSoft, width: 1.5),
        boxShadow: featured ? SC.redShadow : SC.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        featured ? Colors.white.withOpacity(0.22) : SC.redLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'PAKET LANGGANAN',
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: featured ? Colors.white : SC.red,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                if (featured) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('⭐ POPULER',
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: SC.red,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Text(name,
                style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: featured ? Colors.white : SC.textPrimary)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price,
                    style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: featured ? Colors.white : SC.red)),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: featured
                              ? Colors.white.withOpacity(0.8)
                              : SC.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(children: [
                    Icon(Icons.check_circle_rounded,
                        size: 15, color: featured ? Colors.white : SC.red),
                    const SizedBox(width: 8),
                    Text(b,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: featured ? Colors.white : SC.textPrimary)),
                  ]),
                )),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: featured ? Colors.white : SC.red,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: featured ? [] : SC.redShadow,
                ),
                child: Center(
                  child: Text('Pilih Paket Ini',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: featured ? SC.red : Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
