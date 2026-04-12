import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../models/merchandise_item_model.dart';
import '../../models/paginated_response.dart';
import '../../services/merchandise_service.dart';

class MerchandiseScreen extends StatefulWidget {
  const MerchandiseScreen({super.key});

  @override
  State<MerchandiseScreen> createState() => _MerchandiseScreenState();
}

class _MerchandiseScreenState extends State<MerchandiseScreen> {
  final _barcodeController = TextEditingController();
  bool _loading = false;
  bool _scanHandled = false;
  String? _lastResponse;
  int _page = 1;
  PaginatedResponse<MerchandiseItemModel> _items =
      PaginatedResponse<MerchandiseItemModel>(
    items: const [],
    currentPage: 1,
    lastPage: 1,
    perPage: 10,
    total: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _loadItems({int? page}) async {
    setState(() => _loading = true);
    try {
      final service = context.read<MerchandiseService>();
      final nextPage = page ?? _page;
      final data = await service.getMyItems(page: nextPage);
      if (!mounted) {
        return;
      }
      setState(() {
        _page = nextPage;
        _items = data;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat my items.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _verify() async {
    final barcode = _normalizeBarcode(_barcodeController.text);
    if (barcode.isEmpty) {
      return;
    }
    _barcodeController.text = barcode;
    await _verifyBarcodeAndNotify(barcode);
  }

  Future<void> _openScanner() async {
    _scanHandled = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: (capture) {
                    if (_scanHandled) {
                      return;
                    }
                    final first = capture.barcodes.firstOrNull;
                    final code = first?.rawValue;
                    if (code == null || code.isEmpty) {
                      return;
                    }

                    _scanHandled = true;
                    final normalized = _normalizeBarcode(code);
                    _barcodeController.text = normalized;
                    if (!mounted) {
                      return;
                    }
                    Navigator.of(context).pop();
                    Future.microtask(() => _verifyBarcodeAndNotify(normalized));
                  },
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Arahkan kamera ke barcode merchandise',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _activate() async {
    final barcode = _normalizeBarcode(_barcodeController.text);
    if (barcode.isEmpty) {
      return;
    }
    _barcodeController.text = barcode;
    await _verifyBarcodeAndNotify(barcode);
  }

  String _normalizeBarcode(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return value;
    }

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last.trim();
      if (last.isNotEmpty) {
        return last;
      }
    }

    if (value.contains('/')) {
      final last = value.split('/').last.trim();
      if (last.isNotEmpty) {
        return last;
      }
    }

    return value;
  }

  Future<void> _verifyBarcodeAndNotify(String barcode) async {
    setState(() => _loading = true);
    try {
      final service = context.read<MerchandiseService>();
      final data = await service.verifyBarcode(barcode);
      if (!mounted) {
        return;
      }

      final message = data['message']?.toString() ??
          'Barcode berhasil diverifikasi dan diaktivasi.';
      setState(() => _lastResponse = message);
      await _loadItems(page: _page);
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Berhasil'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      final body = e.response?.data;
      String message = 'Verifikasi barcode gagal.';
      if (body is Map<String, dynamic>) {
        final apiMessage = body['message']?.toString();
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            message = first.first.toString();
          } else if (apiMessage != null && apiMessage.isNotEmpty) {
            message = apiMessage;
          }
        } else if (apiMessage != null && apiMessage.isNotEmpty) {
          message = apiMessage;
        }
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Verifikasi Gagal'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merchandise FOMI')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.blue.shade200, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner,
                      size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text('Daftarkan Merchandise Baru!',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _barcodeController,
                    onSubmitted: (_) => _verify(),
                    decoration: const InputDecoration(
                      labelText: 'Kode Barcode',
                      hintText: 'Masukkan barcode di sini',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _openScanner,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Scan Dengan Kamera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Setelah barcode terdeteksi, verifikasi dan aktivasi dilakukan otomatis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                  if (_lastResponse != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        _lastResponse!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('Koleksiku',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800)),
          const SizedBox(height: 16),
          if (_items.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Icon(Icons.category, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Belum ada koleksi merchandise nih!',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else
            ..._items.items.map(
              (item) => Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: item.isActive
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    child: Icon(Icons.shopping_bag,
                        color: item.isActive ? Colors.green : Colors.grey),
                  ),
                  title: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ID: ${item.barcode}'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.isActive
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.isActive ? 'Aktif' : 'Tidak Aktif',
                      style: TextStyle(
                        color: item.isActive
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_items.lastPage > 1) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _page > 1 && !_loading
                        ? () => _loadItems(page: _page - 1)
                        : null,
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue)),
                    child: const Text('Sebelumnya'),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Hal. ${_items.currentPage}/${_items.lastPage}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _items.hasMore && !_loading
                        ? () => _loadItems(page: _page + 1)
                        : null,
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue)),
                    child: const Text('Berikutnya'),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}




