import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/qrcode_model.dart';
import '../../services/qrcode_service.dart';

class QrCodeDetailScreen extends StatefulWidget {
  const QrCodeDetailScreen({super.key, required this.assetId});

  final String assetId;

  @override
  State<QrCodeDetailScreen> createState() => _QrCodeDetailScreenState();
}

class _QrCodeDetailScreenState extends State<QrCodeDetailScreen> {
  bool _loading = false;
  QrCodeModel? _qrcode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = context.read<QrCodeService>();
      final item = await service.getQrCodeDetail(widget.assetId);
      if (!mounted) {
        return;
      }
      setState(() => _qrcode = item);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat detail QR.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleLost() async {
    setState(() => _loading = true);
    try {
      final service = context.read<QrCodeService>();
      await service.toggleLostStatus(widget.assetId);
      await _load();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal toggle status.')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qr = _qrcode;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail QR Code')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : qr == null
              ? const Center(
                  child: Text('Yah, data QR tidak ditemukan',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side:
                              BorderSide(color: Colors.blue.shade300, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              if (qr.imageUrl != null &&
                                  qr.imageUrl!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    qr.imageUrl!,
                                    height: 250,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 200,
                                      width: double.infinity,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image,
                                          size: 80, color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.qr_code_2,
                                      size: 100, color: Colors.blue),
                                ),
                              const SizedBox(height: 20),
                              Text(qr.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade800),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              Text(qr.description ?? 'Belum ada deskripsi nih!',
                                  style: const TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: qr.isLost
                                      ? Colors.red.shade100
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Status: ${qr.status ?? '-'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: qr.isLost
                                        ? Colors.red.shade800
                                        : Colors.green.shade800,
                                  ),
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
                              Row(
                                children: [
                                  const Icon(Icons.contact_mail,
                                      color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text('Kontak Pemilik',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.orange.shade800)),
                                ],
                              ),
                              const Divider(height: 24),
                              ListTile(
                                leading: const Icon(Icons.person,
                                    color: Colors.blue),
                                title: const Text('Nama'),
                                subtitle: Text(qr.contactInfo?['name'] ?? '-'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              ListTile(
                                leading: const Icon(Icons.phone,
                                    color: Colors.green),
                                title: const Text('Telepon'),
                                subtitle: Text(qr.contactInfo?['phone'] ?? '-'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              ListTile(
                                leading:
                                    const Icon(Icons.email, color: Colors.red),
                                title: const Text('Email'),
                                subtitle: Text(qr.contactInfo?['email'] ?? '-'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              if (qr.scanLogsCount != null) ...[
                                const Divider(height: 24),
                                ListTile(
                                  leading: const Icon(Icons.history,
                                      color: Colors.purple),
                                  title: const Text('Jumlah Scan'),
                                  subtitle:
                                      Text('${qr.scanLogsCount} kali discan'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
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
                                  .push('/qrcodes/${widget.assetId}/edit'),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit QR'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(
                                    color: Colors.blue, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _toggleLost,
                              icon: Icon(qr.isLost
                                  ? Icons.check_circle
                                  : Icons.warning),
                              label: Text(qr.isLost
                                  ? 'Barang Ketemu!'
                                  : 'Barang Hilang!'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    qr.isLost ? Colors.green : Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}




