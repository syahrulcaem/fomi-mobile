import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as windows_webview;

import '../../core/app_theme.dart';
import '../../core/external_url_launcher.dart';
import '../../providers/cart_provider.dart';
import '../../services/shop_service.dart';

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
            debugPrint(
              '[ShopPayment][Navigation] main=${request.isMainFrame} '
              'url=${request.url}',
            );

            final uri = Uri.tryParse(request.url);
            if (uri == null) {
              return NavigationDecision.navigate;
            }

            _captureOrderIdFromNavigationUrl(request.url);

            if (!_isWebScheme(uri)) {
              final launched = await ExternalUrlLauncher.launch(request.url);
              if (!launched && mounted) {
                setState(() {
                  _statusMessage =
                      'Aplikasi pembayaran tidak ditemukan. Coba Cek Status atau buka browser eksternal.';
                });
              }
              return NavigationDecision.prevent;
            }

            // Midtrans redirect URL sometimes uses http callback placeholders
            // (e.g. example.com). Intercept before WebView tries to load it.
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
            if (!mounted) {
              return;
            }
            setState(() {
              _statusMessage =
                  'Halaman pembayaran tidak bisa dimuat. Coba Cek Status atau buka browser eksternal.';
            });
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
      setState(
          () => _statusMessage = 'WebView gagal. Buka via browser eksternal.');
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
    final uri = Uri.tryParse(widget.snapUrl);
    if (uri == null) return;
    await ExternalUrlLauncher.launch(widget.snapUrl);
  }

  String? _extractOrderIdFromUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return null;
    }

    final candidates = <String?>[
      uri.queryParameters['order_id'],
      uri.queryParameters['transaction_id'],
      uri.queryParameters['orderId'],
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    return null;
  }

  void _captureOrderIdFromNavigationUrl(String url) {
    final fromUrl = _extractOrderIdFromUrl(url);
    if (fromUrl != null && fromUrl.isNotEmpty && fromUrl != _runtimeOrderId) {
      setState(() {
        _runtimeOrderId = fromUrl;
      });
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
    final normalized = status.trim().toLowerCase();
    return normalized == 'paid' ||
        normalized == 'settlement' ||
        normalized == 'capture' ||
        normalized == 'authorize' ||
        normalized == 'success' ||
        normalized == 'completed' ||
        normalized == 'processing';
  }

  bool _isCleartextHttp(Uri uri) {
    return uri.scheme.toLowerCase() == 'http';
  }

  bool _isWebScheme(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' ||
        scheme == 'https' ||
        scheme == 'about' ||
        scheme == 'data' ||
        scheme == 'javascript';
  }

  bool _isCallbackPlaceholder(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'example.com' || host == 'localhost';
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
      setState(() {
        _runtimeOrderId = orderIdFromUrl;
      });
    }

    if (transactionStatus != null && transactionStatus.isNotEmpty) {
      setState(() {
        _statusMessage = 'Status callback: $transactionStatus';
      });

      if (_isSuccessStatus(transactionStatus)) {
        await _goToSuccess(orderIdFromUrl ?? _runtimeOrderId);
        return;
      }
    }

    // For pending/unknown callback, ask backend for final status.
    await _checkStatus();
  }

  Future<void> _goToSuccess(String? orderNumber) async {
    if (_navigatingSuccess) {
      return;
    }
    _navigatingSuccess = true;
    await context.read<CartProvider>().clearCart();
    if (!mounted) {
      return;
    }

    context.go(
        '/shop/success?orderNumber=${Uri.encodeComponent(orderNumber ?? '')}');
  }

  Future<void> _checkStatus() async {
    final orderId = _runtimeOrderId ??
        (widget.orderId.trim().isNotEmpty ? widget.orderId.trim() : null);

    if (_checking) {
      return;
    }
    if (orderId == null || orderId.isEmpty) {
      setState(() {
        _statusMessage =
            'Order ID tidak ditemukan. Tekan Cek Status lagi setelah halaman selesai memuat.';
      });
      return;
    }

    setState(() {
      _checking = true;
      _statusMessage = 'Mengecek status pembayaran...';
    });
    try {
      final service = context.read<ShopService>();
      final result = await service.checkMidtransStatus(orderId);
      if (!mounted) return;
      final status = _resolveStatus(result);
      final normalizedStatus = status.isEmpty ? 'unknown' : status;
      setState(() => _statusMessage = 'Status: $status');

      if (_isSuccessStatus(normalizedStatus)) {
        final orderNum = result['order_id']?.toString() ?? orderId;
        await _goToSuccess(orderNum);
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
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.close, color: AppColors.textPrimary),
        ),
        title: const Text('Pembayaran',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        actions: [
          TextButton.icon(
            onPressed: _checking ? null : _checkStatus,
            icon: const Icon(Icons.refresh,
                size: 16, color: AppColors.primaryBlue),
            label: const Text('Cek Status',
                style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: _statusMessage.contains('Berhasil')
                ? AppColors.success.withOpacity(0.1)
                : AppColors.softBlue,
            child: Row(
              children: [
                Icon(
                  _checking ? Icons.hourglass_empty : Icons.info_outline,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_statusMessage,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary))),
              ],
            ),
          ),
          Expanded(
            child: _supportsMobileWebView
                ? WebViewWidget(controller: _controller!)
                : _supportsWindowsWebView
                    ? (_windowsController != null
                        ? windows_webview.Webview(_windowsController!)
                        : Center(
                            child: _initializingWindowsWebView
                                ? const CircularProgressIndicator(
                                    color: AppColors.primaryBlue)
                                : ElevatedButton(
                                    onPressed: _openExternal,
                                    child:
                                        const Text('Buka Halaman Pembayaran')),
                          ))
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.payment_outlined,
                                  size: 64, color: AppColors.primaryBlue),
                              const SizedBox(height: 16),
                              const Text('Buka pembayaran di browser',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                  onPressed: _openExternal,
                                  child: const Text('Buka Browser')),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                  onPressed: _checkStatus,
                                  child: const Text('Cek Status Pembayaran')),
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
