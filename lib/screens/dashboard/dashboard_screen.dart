import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/dashboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/main_shell.dart';
import '../../core/app_theme.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = false;
  DashboardModel? _dashboard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = context.read<DashboardService>();
      final data = await service.getDashboard();
      if (!mounted) {
        return;
      }
      setState(() => _dashboard = data);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat dashboard.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stats = _dashboard?.stats;

    return MainShell(
      currentIndex: 0,
      child: Scaffold(
        backgroundColor: AppColors.bgBlue,
        appBar: AppBar(
          title: const Text('Hai, Teman FOMI! 🌟'),
          backgroundColor: Colors.transparent,
          actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.face),
            tooltip: 'Profilku',
          ),
          IconButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) {
                return;
              }
              context.go('/login');
            },
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Halo, ${auth.currentUser?.name ?? 'Sobat'}! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _StatCard(
                title: 'Total Barangku',
                value: stats?.totalAssets ?? 0,
                icon: Icons.inventory_2,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Barang Hilang',
                value: stats?.lostAssets ?? 0,
                icon: Icons.search,
                color: Colors.orange,
              ),
              _StatCard(
                title: 'QR Code Aktif',
                value: stats?.activeQrCodes ?? 0,
                icon: Icons.qr_code_scanner,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Total Pesanan',
                value: stats?.totalOrders ?? 0,
                icon: Icons.local_shipping,
                color: Colors.purple,
              ),
              _StatCard(
                title: 'Sisa Barcode',
                value: stats?.remainingBarcodeQuota ?? 0,
                icon: Icons.confirmation_number,
                color: Colors.teal,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/qrcodes'),
              icon: const Icon(Icons.qr_code_2, size: 28),
              label: const Text('QR Code Milikku'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.push('/orders'),
              icon: const Icon(Icons.receipt_long, size: 28),
              label: const Text('Lihat Pesananku'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade500),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.push('/renewal'),
              icon: const Icon(Icons.stars, size: 28),
              label: const Text('Langganan & Bayar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade500),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.push('/merchandise'),
              icon: const Icon(Icons.shopping_bag, size: 28),
              label: const Text('Toko FOMI'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade400),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'Barang Terbaru 📦',
              items: _dashboard?.recentAssets.map((e) => e.name).toList() ??
                  const [],
              color: Colors.blue,
            ),
            _SectionCard(
              title: 'Barang Kadaluarsa ⚠️',
              items: _dashboard?.expiredAssets.map((e) => e.name).toList() ??
                  const [],
              color: Colors.red,
            ),
            _SectionCard(
              title: 'Status Pesanan 🚚',
              items: _dashboard?.recentOrders
                      .map((e) => '${e.orderNumber} (${e.statusLabel})')
                      .toList() ??
                  const [],
              color: Colors.orange,
            ),
            _SectionCard(
              title: 'Paket Langganan ✨',
              items: _dashboard?.renewalPackages
                      .map((e) => '${e.name} - Rp${e.price}')
                      .toList() ??
                  const [],
              color: Colors.green,
            ),
          ],
        ),
      ),
    ), // end MainShell child Scaffold
    ); // end MainShell
  }
}


class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.5), width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          radius: 24,
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
        trailing: Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.items, required this.color});

  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.3), width: 2),
      ),
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.label_important_outline, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('Wah, masih kosong nih! 🎈',
                  style: TextStyle(fontStyle: FontStyle.italic))
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.star,
                            size: 16, color: Colors.orange.shade300),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
