import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../services/qr_service.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _isProcessing = false;
  Map<String, dynamic>? _scanResult;
  String? _scannedCode;
  final String _sessionId = const Uuid().v4();

  Future<void> _handleScan(String code) async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _scannedCode = code;
    });

    try {
      final qrService = context.read<QrService>();
      final result = await qrService.scanCode(code);
      if (!mounted) {
        return;
      }
      setState(() {
        _scanResult = result;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan gagal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _scanResult?['status']?.toString();
    final isLost = status == 'lost';
    final contact = _scanResult?['contact_info'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code 📸')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.blue.shade300, width: 4),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcode = capture.barcodes.firstOrNull?.rawValue;
                    if (barcode != null) {
                      _handleScan(barcode);
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: _scanResult == null ? 1 : (_scanResult != null && isLost ? 2 : 1),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
              ),
              child: _scanResult == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.camera_alt, size: 64, color: Colors.blue),
                        SizedBox(height: 16),
                        Text(
                          'Arahkan kameramu ke QR code untuk mulai scan! ✨',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isLost ? Colors.red.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isLost ? 'Wah, Barang Ini Hilang! 🚨' : 'Barang Aman! ✅',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isLost ? Colors.red.shade800 : Colors.green.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _scanResult?['message']?.toString() ?? '-',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 0,
                            color: Colors.blue.shade50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: const Icon(Icons.inventory_2, color: Colors.blue),
                              title: const Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(_scanResult?['item_name'] ?? '-', style: const TextStyle(fontSize: 16)),
                            ),
                          ),
                          if (isLost && contact != null) ...[
                            const SizedBox(height: 16),
                            Card(
                              elevation: 0,
                              color: Colors.orange.shade50,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.orange.shade200)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Text('Hubungi Pemiliknya Yuk!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      leading: const Icon(Icons.person, color: Colors.orange),
                                      title: Text(contact['name'] ?? '-'),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.phone, color: Colors.green),
                                      title: Text(contact['phone'] ?? '-'),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _scannedCode == null
                                  ? null
                                  : () => context.push('/chat?code=$_scannedCode&sessionId=$_sessionId'),
                              icon: const Icon(Icons.chat_bubble),
                              label: const Text('Chat Pemilik Sekarang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
