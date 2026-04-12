import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/paginated_response.dart';
import '../../models/qrcode_model.dart';
import '../../services/qrcode_service.dart';

class QrCodeListScreen extends StatefulWidget {
  const QrCodeListScreen({super.key});

  @override
  State<QrCodeListScreen> createState() => _QrCodeListScreenState();
}

class _QrCodeListScreenState extends State<QrCodeListScreen> {
  bool _loading = false;
  int _page = 1;
  PaginatedResponse<QrCodeModel> _result = PaginatedResponse<QrCodeModel>(
    items: const [],
    currentPage: 1,
    lastPage: 1,
    perPage: 10,
    total: 0,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int? page}) async {
    setState(() => _loading = true);
    try {
      final service = context.read<QrCodeService>();
      final nextPage = page ?? _page;
      final response = await service.getUserQrCodes(page: nextPage);
      if (!mounted) {
        return;
      }
      setState(() {
        _page = nextPage;
        _result = response;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat QR Codes.')),
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
      appBar: AppBar(title: const Text('QR Code Milikku')),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(page: _page),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _result.items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Icon(Icons.qr_code_scanner,
                                size: 100, color: Colors.grey),
                            SizedBox(height: 16),
                            Center(
                              child: Text(
                                'Belum ada QR Code nih!',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _result.items.length,
                          itemBuilder: (context, index) {
                            final qr = _result.items[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                    color: Colors.blue.shade200, width: 2),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  radius: 24,
                                  child: const Icon(Icons.qr_code_2,
                                      color: Colors.blue, size: 28),
                                ),
                                title: Text(qr.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                subtitle: Text('Status: ${qr.status ?? '-'}',
                                    style: const TextStyle(
                                        color: Colors.blueGrey)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (qr.scanLogsCount != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          '${qr.scanLogsCount} Scan',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade800),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right,
                                        color: Colors.blue, size: 30),
                                  ],
                                ),
                                onTap: () =>
                                    context.push('/qrcodes/${qr.routeAssetId}'),
                              ),
                            );
                          },
                        ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _page > 1 && !_loading
                        ? () => _load(page: _page - 1)
                        : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400),
                    child: const Text('Sebelumnya'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Hal. ${_result.currentPage}/${_result.lastPage}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _result.hasMore && !_loading
                        ? () => _load(page: _page + 1)
                        : null,
                    child: const Text('Berikutnya'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



