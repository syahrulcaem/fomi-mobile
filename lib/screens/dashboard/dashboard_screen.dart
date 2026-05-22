import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/asset_model.dart';
import '../../models/dashboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/skeleton_loader.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color _accent = Color(0xFFB00000);

  bool _loading = false;
  String? _error;
  DashboardModel? _dashboard;
  int _activeBanner = 0;

  final List<String> _bannerAssets = const [
    'assets/images/banner1.png',
    'assets/images/banner2.png',
    'assets/images/banner3.png',
    'assets/images/banner4.png',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<DashboardService>().getDashboard();
      if (!mounted) return;
      setState(() => _dashboard = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat dashboard. Ketuk untuk coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stats = _dashboard?.stats;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _load,
        color: _accent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(auth)),
            SliverToBoxAdapter(child: _buildBannerCarousel()),
            if (_loading)
              SliverToBoxAdapter(child: _buildSummarySkeleton())
            else if (_error == null)
              SliverToBoxAdapter(child: _buildSummaryCard(stats)),
            if (_error != null && !_loading)
              SliverToBoxAdapter(child: _buildError()),
            SliverToBoxAdapter(
              child: _buildSectionHeader('Daftar Barang', '/qrcodes'),
            ),
            _buildAssetList(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    final fullName = auth.currentUser?.name.trim();
    final shortName = (fullName == null || fullName.isEmpty)
        ? 'Sobat'
        : fullName.split(' ').first;

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: 36,
                  height: 36,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Home',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.person_outline, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hi $shortName!',
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'semoga barangmu aman ya hari ini',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.push('/scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Scan QR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CarouselSlider.builder(
              itemCount: _bannerAssets.length,
              itemBuilder: (context, index, realIndex) {
                return Image.asset(
                  _bannerAssets[index],
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
              },
              options: CarouselOptions(
                height: 190,
                viewportFraction: 1,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                onPageChanged: (index, _) {
                  setState(() => _activeBanner = index);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _bannerAssets.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 7,
                width: _activeBanner == index ? 20 : 7,
                decoration: BoxDecoration(
                  color: _activeBanner == index ? _accent : Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(DashboardStats? stats) {
    if (stats == null) {
      return const SizedBox.shrink();
    }

    final summaryItems = [
      _SummaryItem('Total Barang', '${stats.totalAssets}',
          Icons.inventory_2_outlined, '/qrcodes'),
      _SummaryItem(
          'QR Aktif', '${stats.activeQrCodes}', Icons.qr_code_2, '/qrcodes'),
      _SummaryItem('Total Pesanan', '${stats.totalOrders}',
          Icons.local_shipping_outlined, '/shop'),
      _SummaryItem('Sisa Kuota', '${stats.remainingBarcodeQuota}',
          Icons.confirmation_number_outlined, '/shop'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFFA30000), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Dashboard',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Snapshot data terbaru akun kamu.',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: summaryItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (context, index) {
                final item = summaryItems[index];
                final isPrimary = index == 0;

                return GestureDetector(
                  onTap: () {
                    if (item.route != null) {
                      context.push(item.route!);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isPrimary
                            ? const [Color(0xFFBF0000), Color(0xFF940000)]
                            : const [Color(0x3BBF0000), Color(0x3B940000)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 16,
                          color: isPrimary
                              ? Colors.white
                              : const Color(0xFF7A0000),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isPrimary
                                ? Colors.white
                                : const Color(0xFF7A0000),
                          ),
                        ),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPrimary
                                ? Colors.white.withOpacity(0.95)
                                : const Color(0xFF7A0000),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: const [
          SkeletonLoader(width: double.infinity, height: 90, borderRadius: 19),
          SizedBox(height: 10),
          SkeletonLoader(width: double.infinity, height: 160, borderRadius: 12),
        ],
      ),
    );
  }

  Widget _buildError() {
    return GestureDetector(
      onTap: _load,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_error!,
                  style: const TextStyle(fontSize: 13, color: Colors.red)),
            ),
            const Icon(Icons.refresh, color: Colors.red, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String route) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black)),
          GestureDetector(
            onTap: () => context.push(route),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE6E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  color: _accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetList() {
    if (_loading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: SkeletonLoader(
                width: double.infinity,
                height: 74,
                borderRadius: 14,
              ),
            ),
            childCount: 5,
          ),
        ),
      );
    }

    final assets = _dashboard?.recentAssets ?? [];
    if (assets.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Belum ada barang terdaftar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildAssetRow(assets[index]),
          childCount: assets.length,
        ),
      ),
    );
  }

  Widget _buildAssetRow(AssetModel asset) {
    final isLost = asset.status == 'lost';
    return GestureDetector(
      onTap: () => context.push('/qrcodes/${asset.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFE3E3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 48,
                child: asset.image != null && asset.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: asset.image!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _assetPlaceholder(),
                      )
                    : _assetPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87)),
                  Text(asset.description ?? 'Tidak ada deskripsi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isLost ? Colors.red.shade50 : const Color(0x1AA30000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isLost ? 'Hilang' : asset.status ?? 'Aktif',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isLost ? Colors.red : _accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assetPlaceholder() {
    return Container(
      color: const Color(0xFFFFE9E9),
      child: const Icon(Icons.inventory_2_outlined, color: _accent, size: 24),
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.value, this.icon, [this.route]);
  final String label;
  final String value;
  final IconData icon;
  final String? route;
}
