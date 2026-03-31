import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/asset_model.dart';
import '../../models/dashboard_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/skeleton_loader.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = false;
  String? _error;
  DashboardModel? _dashboard;

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
    final auth = context.watch<AuthProvider>();
    final stats = _dashboard?.stats;

    return Scaffold(
      backgroundColor: AppColors.bgBlue,
        body: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primaryBlue,
          child: CustomScrollView(
            slivers: [
              // ── Gradient Header ──
              SliverToBoxAdapter(child: _buildHeader(auth)),

              // ── Stats Row ──
              if (_loading)
                SliverToBoxAdapter(child: _buildStatsSkeletons())
              else if (_error == null)
                SliverToBoxAdapter(child: _buildStats(stats)),

              // ── Error ──
              if (_error != null && !_loading)
                SliverToBoxAdapter(child: _buildError()),

              // ── Primary CTA: Scan Merchandise ──
              SliverToBoxAdapter(child: _buildScanCta()),

              // ── QR Codes Quick Access ──
              SliverToBoxAdapter(
                  child: _buildSectionHeader('QR Code Milikku 📱', '/qrcodes')),
              SliverToBoxAdapter(child: _buildQrScroll()),

              // ── Recent Items ──
              SliverToBoxAdapter(
                  child: _buildSectionHeader('Barang Terbaru 📦', '/qrcodes')),
              _buildRecentItems(),

              // ── Recent Orders ──
              SliverToBoxAdapter(
                  child: _buildSectionHeader('Pesanan Terkini 🚚', '/orders')),
              _buildRecentOrders(),

              // ── Quick Links ──
              SliverToBoxAdapter(child: _buildQuickLinks()),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      );
  }

  // ────────────────────────────────────────────
  // Header
  // ────────────────────────────────────────────

  Widget _buildHeader(AuthProvider auth) {
    final name = auth.currentUser?.name ?? 'Sobat';
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.heroGradient),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Logo
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('F',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20)),
                ),
              ),
              const SizedBox(width: 8),
              const Text('FOMI',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.darkBlue)),
              const Spacer(),
              // Profile avatar
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline,
                      color: AppColors.primaryBlue, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Greeting
          Text(
            'Halo, $name! 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.darkBlue,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Semua barang dan asetmu ada di sini.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // Stats
  // ────────────────────────────────────────────

  Widget _buildStats(DashboardStats? stats) {
    if (stats == null) return const SizedBox.shrink();

    final items = [
      _StatData('Barang', '${stats.totalAssets}', Icons.inventory_2_outlined,
          AppColors.primaryBlue),
      _StatData('QR Aktif', '${stats.activeQrCodes}', Icons.qr_code_2,
          AppColors.success),
      _StatData('Pesanan', '${stats.totalOrders}',
          Icons.local_shipping_outlined, const Color(0xFFF59E0B)),
      _StatData('Kuota', '${stats.remainingBarcodeQuota}',
          Icons.confirmation_number_outlined, const Color(0xFF8B5CF6)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: items
            .map((s) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: s == items.last ? 0 : 10),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: s.color.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(s.icon, color: s.color, size: 20),
                        const SizedBox(height: 6),
                        Text(
                          s.value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: s.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildStatsSkeletons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: List.generate(
            4,
            (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 10 : 0),
                    child: const SkeletonLoader(
                        width: double.infinity, height: 76, borderRadius: 16),
                  ),
                )),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Error
  // ────────────────────────────────────────────

  Widget _buildError() {
    return GestureDetector(
      onTap: _load,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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

  // ────────────────────────────────────────────
  // Primary CTA — Scan Merchandise
  // ────────────────────────────────────────────

  Widget _buildScanCta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => context.push('/scan'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.midBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.qr_code_scanner,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Merchandise',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Daftarkan & kelola produk FOMI-mu',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Section header
  // ────────────────────────────────────────────

  Widget _buildSectionHeader(String title, String route) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          GestureDetector(
            onTap: () => context.push(route),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Lihat Semua',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // QR Codes Horizontal Scroll
  // ────────────────────────────────────────────

  Widget _buildQrScroll() {
    if (_loading) {
      return SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) =>
              const SkeletonLoader(width: 90, height: 110, borderRadius: 16),
        ),
      );
    }

    final assets = _dashboard?.recentAssets ?? [];
    if (assets.isEmpty) {
      return Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Belum ada QR Code',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: assets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _buildQrCard(assets[index]),
      ),
    );
  }

  Widget _buildQrCard(AssetModel asset) {
    return GestureDetector(
      onTap: () => context.push('/qrcodes/${asset.id}'),
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.lightBlue.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: asset.image != null && asset.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: asset.image!,
                        width: 90,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _qrPlaceholder(),
                      )
                    : _qrPlaceholder(),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Text(
                asset.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrPlaceholder() {
    return Container(
      color: AppColors.softBlue,
      child: const Center(
          child: Icon(Icons.qr_code_2, color: AppColors.primaryBlue, size: 36)),
    );
  }

  // ────────────────────────────────────────────
  // Recent Items
  // ────────────────────────────────────────────

  Widget _buildRecentItems() {
    if (_loading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: SkeletonLoader(
                  width: double.infinity, height: 68, borderRadius: 14),
            ),
            childCount: 3,
          ),
        ),
      );
    }

    final items = _dashboard?.recentAssets ?? [];
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('Belum ada barang',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildAssetRow(items[index]),
          childCount: items.take(3).length,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.lightBlue.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLost ? Colors.red.shade50 : AppColors.softBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isLost ? Icons.search : Icons.inventory_2_outlined,
                color: isLost ? Colors.red : AppColors.primaryBlue,
                size: 22,
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
                          color: AppColors.textPrimary)),
                  Text(asset.description ?? 'Tidak ada deskripsi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isLost
                    ? Colors.red.shade50
                    : AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isLost ? 'Hilang' : asset.status ?? 'Aktif',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isLost ? Colors.red : AppColors.success),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Recent Orders
  // ────────────────────────────────────────────

  Widget _buildRecentOrders() {
    if (_loading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: SkeletonLoader(
                  width: double.infinity, height: 68, borderRadius: 14),
            ),
            childCount: 2,
          ),
        ),
      );
    }

    final orders = _dashboard?.recentOrders ?? [];
    if (orders.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('Belum ada pesanan',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildOrderRow(orders[index]),
          childCount: orders.take(3).length,
        ),
      ),
    );
  }

  Widget _buildOrderRow(OrderModel order) {
    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.lightBlue.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_shipping_outlined,
                  color: Color(0xFFF59E0B), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.orderNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text(_formatPrice(order.totalAmount),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.statusLabel,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Quick Links
  // ────────────────────────────────────────────

  Widget _buildQuickLinks() {
    final links = [
      _QuickLink('Pesananku', Icons.receipt_long_outlined, '/orders',
          AppColors.primaryBlue),
      _QuickLink(
          'Langganan', Icons.stars_rounded, '/renewal', AppColors.success),
      _QuickLink(
          'QR Codes', Icons.qr_code_2, '/qrcodes', const Color(0xFF8B5CF6)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Menu Cepat',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          Row(
            children: links
                .map((l) => Expanded(
                      child: GestureDetector(
                        onTap: () => context.push(l.route),
                        child: Container(
                          margin:
                              EdgeInsets.only(right: l == links.last ? 0 : 10),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: l.color.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: l.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(l.icon, color: l.color, size: 22),
                              ),
                              const SizedBox(height: 8),
                              Text(l.label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Data classes
// ───────────────────────────────────────────────

class _StatData {
  const _StatData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _QuickLink {
  const _QuickLink(this.label, this.icon, this.route, this.color);
  final String label;
  final IconData icon;
  final String route;
  final Color color;
}
