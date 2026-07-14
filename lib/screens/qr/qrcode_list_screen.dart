import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/paginated_response.dart';
import '../../models/qrcode_model.dart';
import '../../services/qrcode_service.dart';
import '../../widgets/skeleton_loader.dart';

class QrCodeListScreen extends StatefulWidget {
  const QrCodeListScreen({super.key});

  @override
  State<QrCodeListScreen> createState() => _QrCodeListScreenState();
}

class _QrCodeListScreenState extends State<QrCodeListScreen> {
  static const Color _accent = Color(0xFFB00000);

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'QR Code Milikku',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(page: _page),
              color: _accent,
              child: _loading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: 5,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: SkeletonLoader(
                          width: double.infinity,
                          height: 74,
                          borderRadius: 14,
                        ),
                      ),
                    )
                  : _result.items.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5F5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.qr_code_scanner, size: 60, color: _accent),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada QR Code nih!',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _result.items.length,
                          itemBuilder: (context, index) {
                            final qr = _result.items[index];
                            final isLost = qr.status == 'lost';
                            
                            return GestureDetector(
                              onTap: () => context.push('/qrcodes/${qr.routeAssetId}'),
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
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        color: const Color(0xFFFFE9E9),
                                        child: const Icon(Icons.qr_code_2, color: _accent, size: 24),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            qr.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          if (qr.scanLogsCount != null)
                                            Text(
                                              '${qr.scanLogsCount} Scan',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: _accent,
                                              ),
                                            ),
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
                                        isLost ? 'Hilang' : (qr.status ?? 'Aktif'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isLost ? Colors.red : _accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
          if (!_loading && _result.total > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _page > 1 && !_loading ? () => _load(page: _page - 1) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Sebelumnya',
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Hal. ${_result.currentPage}/${_result.lastPage}',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _result.hasMore && !_loading ? () => _load(page: _page + 1) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Berikutnya',
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                      ),
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
