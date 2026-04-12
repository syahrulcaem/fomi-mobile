import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/asset_provider.dart';

class AssetDetailScreen extends StatefulWidget {
  const AssetDetailScreen({super.key, required this.assetId});

  final String assetId;

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetProvider>().fetchAssetDetail(widget.assetId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssetProvider>();
    final asset = provider.selectedAsset;
    final qrCode = asset?.primaryQrCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Assetku')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : asset == null
              ? const Center(
                  child: Text('Asset tidak ditemukan',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side:
                              BorderSide(color: Colors.blue.shade200, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.blue,
                                  child: Icon(Icons.inventory_2,
                                      color: Colors.white, size: 40),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                asset.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                asset.description ?? 'Belum ada deskripsi nih!',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.blueGrey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.orange.shade200),
                                ),
                                child: Text(
                                  'Status: ${asset.status ?? '-'}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Informasi QR Code',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                              const Divider(height: 24),
                              ListTile(
                                leading: const Icon(Icons.qr_code_2,
                                    color: Colors.green),
                                title: const Text('Kode QR'),
                                subtitle: Text(qrCode?.code ?? 'Belum ada'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              if (qrCode != null)
                                ListTile(
                                  leading: Icon(
                                      qrCode.isActive
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: qrCode.isActive
                                          ? Colors.green
                                          : Colors.red),
                                  title: const Text('Status QR'),
                                  subtitle: Text(qrCode.isActive
                                      ? 'Aktif'
                                      : 'Tidak Aktif'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context
                                  .push('/assets/${widget.assetId}/edit'),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.blue, width: 2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final ok = await context
                                    .read<AssetProvider>()
                                    .toggleLostStatus(widget.assetId);
                                if (!context.mounted) {
                                  return;
                                }
                                if (ok) {
                                  await context
                                      .read<AssetProvider>()
                                      .fetchAssetDetail(widget.assetId);
                                }
                              },
                              icon: const Icon(Icons.warning_amber_rounded),
                              label: const Text('Lapor Hilang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}




