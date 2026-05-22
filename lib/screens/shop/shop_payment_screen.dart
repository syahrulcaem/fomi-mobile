import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/shop_theme.dart';
import '../../core/external_url_launcher.dart';
import '../../providers/cart_provider.dart';
import '../../services/shop_service.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as windows_webview;

class ShopPaymentScreen extends StatefulWidget {
  const ShopPaymentScreen(
      {super.key, required this.snapUrl, required this.orderId});

  final String snapUrl;
  final String orderId;

  @override
  State<ShopPaymentScreen> createState() => _ShopPaymentScreenState();
}

class _ShopPaymentScreenState extends State<ShopPaymentScreen> {
  WebViewController? _controller;
  windows_webview.WebviewController? _windowsController;
  String _statusMessage = 'Menunggu pembayaran...';
  bool _checking = false;
  bool _initializingWindowsWebView = false;
  String? _runtimeOrderId;
  bool _navigatingSuccess = false;

  bool get _supportsMobileWebView {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  bool get _supportsWindowsWebView {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  void initState() {
    super.initState();
    _runtimeOrderId = _extractOrderIdFromUrl(widget.snapUrl) ??
        (widget.orderId.trim().isNotEmpty ? widget.orderId.trim() : null);

    if (_supportsMobileWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: (request) async {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.navigate;
            _captureOrderIdFromNavigationUrl(request.url);
            if (!_isWebScheme(uri)) {
              final launched = await ExternalUrlLauncher.launch(request.url);
              if (!launched && mounted) {
                setState(() => _statusMessage =
                    'Aplikasi pembayaran tidak ditemukan. Coba Cek Status atau buka browser eksternal.');
              }
              return NavigationDecision.prevent;
            }
            if (_isMidtransCallback(uri)) {
              await _handleMidtransCallback(uri);
              if (_isCleartextHttp(uri) || _isCallbackPlaceholder(uri)) {
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) {
            _captureOrderIdFromNavigationUrl(url);
            if (url.contains('finish') ||
                url.contains('pending') ||
                url.contains('success')) {
              _checkStatus();
            }
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() => _statusMessage =
                'Halaman pembayaran tidak bisa dimuat. Coba Cek Status atau buka browser eksternal.');
          },
        ))
        ..loadRequest(Uri.parse(widget.snapUrl));
    } else if (_supportsWindowsWebView) {
      _initWindowsWebView();
    }
  }

  Future<void> _initWindowsWebView() async {
    final controller = windows_webview.WebviewController();
    setState(() => _initializingWindowsWebView = true);
    try {
      await controller.initialize();
      await controller
          .setPopupWindowPolicy(windows_webview.WebviewPopupWindowPolicy.deny);
      await controller.loadUrl(widget.snapUrl);
      if (!mounted) return;
      setState(() => _windowsController = controller);
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusMessage = 'WebView gagal. Buka via browser eksternal.');
    } finally {
      if (mounted) setState(() => _initializingWindowsWebView = false);
    }
  }

  @override
  void dispose() {
    _windowsController?.dispose();
    super.dispose();
  }

  Future<void> _openExternal() async {
    await ExternalUrlLauncher.launch(widget.snapUrl);
  }

  String? _extractOrderIdFromUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return null;
    for (final c in [
      uri.queryParameters['order_id'],
      uri.queryParameters['transaction_id'],
      uri.queryParameters['orderId'],
    ]) {
      if (c != null && c.trim().isNotEmpty) return c.trim();
    }
    return null;
  }

  void _captureOrderIdFromNavigationUrl(String url) {
    final fromUrl = _extractOrderIdFromUrl(url);
    if (fromUrl != null && fromUrl.isNotEmpty && fromUrl != _runtimeOrderId) {
      setState(() => _runtimeOrderId = fromUrl);
    }
  }

  String _resolveStatus(Map<String, dynamic> result) {
    final data = result['data'];
    final dataMap = data is Map ? Map<String, dynamic>.from(data) : null;
    return result['status']?.toString() ??
        result['transaction_status']?.toString() ??
        dataMap?['status']?.toString() ??
        dataMap?['transaction_status']?.toString() ??
        '';
  }

  bool _isSuccessStatus(String status) {
    final n = status.trim().toLowerCase();
    return n == 'paid' || n == 'settlement' || n == 'capture' ||
        n == 'authorize' || n == 'success' || n == 'completed' || n == 'processing';
  }

  bool _isCleartextHttp(Uri uri) => uri.scheme.toLowerCase() == 'http';

  bool _isWebScheme(Uri uri) {
    final s = uri.scheme.toLowerCase();
    return s == 'http' || s == 'https' || s == 'about' || s == 'data' || s == 'javascript';
  }

  bool _isCallbackPlaceholder(Uri uri) {
    final h = uri.host.toLowerCase();
    return h == 'example.com' || h == 'localhost';
  }

  bool _isMidtransCallback(Uri uri) {
    final qp = uri.queryParameters;
    return qp.containsKey('transaction_status') ||
        qp.containsKey('status_code') ||
        qp.containsKey('order_id');
  }

  Future<void> _handleMidtransCallback(Uri uri) async {
    final orderIdFromUrl = uri.queryParameters['order_id']?.trim();
    final transactionStatus = uri.queryParameters['transaction_status']?.trim();
    if (orderIdFromUrl != null && orderIdFromUrl.isNotEmpty) {
      setState(() => _runtimeOrderId = orderIdFromUrl);
    }
    if (transactionStatus != null && transactionStatus.isNotEmpty) {
      setState(() => _statusMessage = 'Status callback: $transactionStatus');
      if (_isSuccessStatus(transactionStatus)) {
        await _goToSuccess(orderIdFromUrl ?? _runtimeOrderId);
        return;
      }
    }
    await _checkStatus();
  }

  Future<void> _goToSuccess(String? orderNumber) async {
    if (_navigatingSuccess) return;
    _navigatingSuccess = true;
    await context.read<CartProvider>().clearCart();
    if (!mounted) return;
    context.go('/shop/success?orderNumber=${Uri.encodeComponent(orderNumber ?? '')}');
  }

  Future<void> _checkStatus() async {
    final orderId = _runtimeOrderId ??
        (widget.orderId.trim().isNotEmpty ? widget.orderId.trim() : null);
    if (_checking) return;
    if (orderId == null || orderId.isEmpty) {
      setState(() => _statusMessage =
          'Order ID tidak ditemukan. Tekan Cek Status lagi setelah halaman selesai memuat.');
      return;
    }
    setState(() {
      _checking = true;
      _statusMessage = 'Mengecek status pembayaran...';
    });
    try {
      final result = await context.read<ShopService>().checkMidtransStatus(orderId);
      if (!mounted) return;
      final status = _resolveStatus(result);
      setState(() => _statusMessage = 'Status: $status');
      if (_isSuccessStatus(status.isEmpty ? 'unknown' : status)) {
        await _goToSuccess(result['order_id']?.toString() ?? orderId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Gagal cek status pembayaran.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = _statusMessage.toLowerCase().contains('berhasil') ||
        _statusMessage.toLowerCase().contains('success');

    return Scaffold(
      backgroundColor: SC.bg,
      appBar: AppBar(
        backgroundColor: SC.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: SC.redLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: SC.red, size: 18),
            ),
          ),
        ),
        title: Text(
          'Pembayaran',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: SC.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _checking ? null : _checkStatus,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _checking ? Colors.grey.shade100 : SC.redLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        size: 14, color: _checking ? SC.textSecondary : SC.red),
                    const SizedBox(width: 4),
                    Text(
                      'Cek Status',
                      style: GoogleFonts.poppins(
                        color: _checking ? SC.textSecondary : SC.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isSuccess
                ? SC.successLight
                : _checking
                    ? const Color(0xFFFFF8E1)
                    : SC.redLight,
            child: Row(
              children: [
                Icon(
                  _checking
                      ? Icons.hourglass_empty_rounded
                      : isSuccess
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                  size: 16,
                  color: isSuccess ? SC.success : _checking ? Colors.orange : SC.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isSuccess ? SC.success : SC.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // WebView or fallback
          Expanded(
            child: _supportsMobileWebView
                ? WebViewWidget(controller: _controller!)
                : _supportsWindowsWebView
                    ? (_windowsController != null
                        ? windows_webview.Webview(_windowsController!)
                        : Center(
                            child: _initializingWindowsWebView
                                ? const CircularProgressIndicator(color: SC.red)
                                : _buildFallbackButton(),
                          ))
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: SC.redGradient,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(Icons.payment_outlined,
                                    size: 40, color: Colors.white),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Buka pembayaran di browser',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: SC.textPrimary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Platform ini tidak mendukung WebView pembayaran inline.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: SC.textSecondary),
                              ),
                              const SizedBox(height: 24),
                              ShopWidgets.primaryButton(
                                label: 'Buka Browser',
                                onTap: _openExternal,
                                icon: Icons.open_in_browser_rounded,
                              ),
                              const SizedBox(height: 12),
                              ShopWidgets.outlinedButton(
                                label: 'Cek Status Pembayaran',
                                onTap: _checking ? null : _checkStatus,
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackButton() {
    return ShopWidgets.primaryButton(
      label: 'Buka Halaman Pembayaran',
      onTap: _openExternal,
      icon: Icons.open_in_browser_rounded,
    );
  }
}
