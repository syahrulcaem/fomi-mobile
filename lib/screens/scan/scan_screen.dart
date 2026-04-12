import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../core/app_theme.dart';
import '../../models/paginated_response.dart';
import '../../models/qrcode_model.dart';
import '../../services/merchandise_service.dart';
import '../../services/qrcode_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state.dart';
import 'all_chat_sessions_screen.dart';
import 'owner_chat_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  // Scanner state
  final _barcodeCtrl = TextEditingController();
  bool _scanHandled = false;
  bool _verifying = false;
  _ScanResult? _result;

  // Koleksi state
  bool _loadingItems = false;
  int _page = 1;
  PaginatedResponse<QrCodeModel> _items = PaginatedResponse<QrCodeModel>(
    items: const [],
    currentPage: 1,
    lastPage: 1,
    perPage: 12,
    total: 0,
  );

  // Scanner overlay animation
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );
    _loadItems();
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _scanLineCtrl.dispose();
    super.dispose();
  }

  //

  String _normalizeBarcode(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last.trim();
      if (last.isNotEmpty) return last;
    }
    if (value.contains('/')) {
      final last = value.split('/').last.trim();
      if (last.isNotEmpty) return last;
    }
    return value;
  }

  //

  Future<void> _loadItems({int? page}) async {
    setState(() => _loadingItems = true);
    try {
      final service = context.read<QrCodeService>();
      final nextPage = page ?? _page;
      final data = await service.getUserQrCodes(page: nextPage, perPage: 12);
      if (!mounted) return;
      setState(() {
        _page = nextPage;
        _items = data;
      });
    } catch (_) {
      // ignore, show empty state
    } finally {
      if (mounted) setState(() => _loadingItems = false);
    }
  }

  //

  void _onDetect(BarcodeCapture capture) {
    if (_scanHandled || _verifying) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _scanHandled = true;
    final normalized = _normalizeBarcode(code);
    _barcodeCtrl.text = normalized;
    Future.microtask(() => _verify(normalized));
  }

  //

  Future<void> _verify([String? override]) async {
    final barcode = _normalizeBarcode(override ?? _barcodeCtrl.text);
    if (barcode.isEmpty) return;
    _barcodeCtrl.text = barcode;
    setState(() {
      _verifying = true;
      _result = null;
    });
    try {
      final service = context.read<MerchandiseService>();
      final data = await service.verifyBarcode(barcode);
      if (!mounted) return;
      final msg = data['message']?.toString() ??
          'Barcode berhasil diverifikasi dan diaktivasi.';
      setState(() => _result = _ScanResult(success: true, message: msg));
      await _loadItems(page: _page);
    } on DioException catch (e) {
      if (!mounted) return;
      final body = e.response?.data;
      String msg = 'Verifikasi barcode gagal.';
      if (body is Map<String, dynamic>) {
        final apiMsg = body['message']?.toString();
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            msg = first.first.toString();
          } else if (apiMsg != null && apiMsg.isNotEmpty) {
            msg = apiMsg;
          }
        } else if (apiMsg != null && apiMsg.isNotEmpty) {
          msg = apiMsg;
        }
      }
      setState(() => _result = _ScanResult(success: false, message: msg));
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
        _scanHandled = false;
      }
    }
  }

  //

  Future<void> _openCamera() async {
    _scanHandled = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.72,
                child: Stack(
                  children: [
                    // Scanner
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      child: MobileScanner(
                        onDetect: (capture) {
                          if (_scanHandled || _verifying) return;
                          final code = capture.barcodes.firstOrNull?.rawValue;
                          if (code == null || code.isEmpty) return;
                          _scanHandled = true;
                          final normalized = _normalizeBarcode(code);
                          _barcodeCtrl.text = normalized;
                          Navigator.of(ctx).pop();
                          Future.microtask(() => _verify(normalized));
                        },
                      ),
                    ),
                    // Overlay frame
                    Positioned.fill(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Close
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: GestureDetector(
                                onTap: () => Navigator.of(ctx).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Scan frame
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.white54, width: 1.5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                // Corner decorations
                                ..._corners(),
                                // Scan line
                                AnimatedBuilder(
                                  animation: _scanLineAnim,
                                  builder: (_, __) => Positioned(
                                    top: 220 * _scanLineAnim.value - 2,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue,
                                        borderRadius: BorderRadius.circular(2),
                                        boxShadow: [
                                          BoxShadow(
                                              color: AppColors.primaryBlue
                                                  .withOpacity(0.5),
                                              blurRadius: 6),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Arahkan kamera ke barcode merchandise',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _corners() {
    const size = 24.0;
    const thick = 3.0;
    const color = AppColors.primaryBlue;

    Widget corner(Alignment a) {
      return Positioned(
        top: a.y < 0 ? 0 : null,
        bottom: a.y > 0 ? 0 : null,
        left: a.x < 0 ? 0 : null,
        right: a.x > 0 ? 0 : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              top: a.y < 0
                  ? const BorderSide(color: color, width: thick)
                  : BorderSide.none,
              bottom: a.y > 0
                  ? const BorderSide(color: color, width: thick)
                  : BorderSide.none,
              left: a.x < 0
                  ? const BorderSide(color: color, width: thick)
                  : BorderSide.none,
              right: a.x > 0
                  ? const BorderSide(color: color, width: thick)
                  : BorderSide.none,
            ),
          ),
        ),
      );
    }

    return [
      corner(Alignment.topLeft),
      corner(Alignment.topRight),
      corner(Alignment.bottomLeft),
      corner(Alignment.bottomRight),
    ];
  }

  //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: RefreshIndicator(
        onRefresh: () => _loadItems(),
        color: AppColors.primaryBlue,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader()),
            // Scanner Card
            SliverToBoxAdapter(child: _buildScanCard()),
            // Result
            if (_result != null) SliverToBoxAdapter(child: _buildResult()),
            // Koleksi header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Koleksiku ',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AllChatSessionsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.forum_outlined, size: 16),
                          label: const Text('Semua Sesi'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            minimumSize: const Size(10, 34),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_items.total} item',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Koleksi list
            _loadingItems
                ? SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: SkeletonLoader(
                              width: double.infinity,
                              height: 72,
                              borderRadius: 16),
                        ),
                        childCount: 4,
                      ),
                    ),
                  )
                : _items.items.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.qr_code_2_outlined,
                          title: 'Belum ada koleksi',
                          subtitle: 'Belum ada QR Code milikmu.',
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildItemCard(_items.items[index]),
                            childCount: _items.items.length,
                          ),
                        ),
                      ),
            // Pagination
            if (_items.lastPage > 1)
              SliverToBoxAdapter(child: _buildPagination()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.heroGradient),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              const Text('Scan Merchandise',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.darkBlue)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Daftarkan merchandise FOMI dan kelola koleksimu.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Camera CTA
          GestureDetector(
            onTap: _verifying ? null : _openCamera,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.midBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _verifying
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner,
                            size: 48, color: Colors.white),
                        SizedBox(height: 8),
                        Text(
                          'Ketuk untuk Scan',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Arahkan kamera ke barcode',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Divider
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('atau ketik manual',
                  style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 12)),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 12),
          // Manual input
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _barcodeCtrl,
                  onFieldSubmitted: (_) => _verify(),
                  decoration: InputDecoration(
                    hintText: 'Masukkan kode barcode...',
                    prefixIcon: const Icon(Icons.confirmation_number_outlined,
                        size: 20, color: AppColors.primaryBlue),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: AppColors.bgBlue,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.skyBlue),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.skyBlue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primaryBlue, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _verifying ? null : () => _verify(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _verifying
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: r.success
            ? AppColors.success.withOpacity(0.08)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: r.success ? AppColors.success : Colors.red.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: r.success ? AppColors.success : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              r.success ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.success ? 'Berhasil!' : 'Gagal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: r.success ? AppColors.success : Colors.red,
                  ),
                ),
                Text(r.message,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _result = null),
            child: const Icon(Icons.close,
                size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(QrCodeModel item) {
    final isLost = item.isLost;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightBlue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLost ? Colors.red.shade50 : AppColors.softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.qr_code_2,
              color: isLost ? Colors.red : AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Kode: ${item.code ?? '-'}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OwnerChatScreen(
                          assetId: item.routeAssetId,
                          assetName: item.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat Anonim'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(10, 34),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isLost
                  ? Colors.red.shade50
                  : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isLost ? 'Hilang' : (item.status ?? 'Normal'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isLost ? Colors.red : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _page > 1 && !_loadingItems
                ? () => _loadItems(page: _page - 1)
                : null,
            child: const Text('< Sebelumnya'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('${_items.currentPage}/${_items.lastPage}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
        ),
        Expanded(
          child: ElevatedButton(
            onPressed: _items.hasMore && !_loadingItems
                ? () => _loadItems(page: _page + 1)
                : null,
            child: const Text('Berikutnya'),
          ),
        ),
      ]),
    );
  }
}

class _ScanResult {
  _ScanResult({required this.success, required this.message});
  final bool success;
  final String message;
}
