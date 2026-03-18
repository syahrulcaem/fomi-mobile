import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as windows_webview;

import '../../core/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../services/shop_service.dart';

class ShopPaymentScreen extends StatefulWidget {
  const ShopPaymentScreen({super.key, required this.snapUrl, required this.orderId});

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
    if (_supportsMobileWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (url) {
            if (url.contains('finish') || url.contains('pending') || url.contains('success')) {
              _checkStatus();
            }
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
      await controller.setPopupWindowPolicy(windows_webview.WebviewPopupWindowPolicy.deny);
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
    final uri = Uri.tryParse(widget.snapUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _checkStatus() async {
    if (_checking || widget.orderId.isEmpty) return;
    setState(() { _checking = true; _statusMessage = 'Mengecek status pembayaran...'; });
    try {
      final service = context.read<ShopService>();
      final result = await service.checkMidtransStatus(widget.orderId);
      if (!mounted) return;
      final status = result['status']?.toString() ?? 'unknown';
      setState(() => _statusMessage = 'Status: $status');
      if (status == 'paid' || status == 'settlement') {
        await context.read<CartProvider>().clearCart();
        if (!mounted) return;
        final orderNum = result['order_id']?.toString();
        context.go('/shop/success?orderNumber=${Uri.encodeComponent(orderNum ?? '')}');
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
        title: const Text('Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          TextButton.icon(
            onPressed: _checking ? null : _checkStatus,
            icon: const Icon(Icons.refresh, size: 16, color: AppColors.primaryBlue),
            label: const Text('Cek Status', style: TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: _statusMessage.contains('Berhasil') ? AppColors.success.withOpacity(0.1) : AppColors.softBlue,
            child: Row(
              children: [
                Icon(
                  _checking ? Icons.hourglass_empty : Icons.info_outline,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_statusMessage, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
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
                                ? const CircularProgressIndicator(color: AppColors.primaryBlue)
                                : ElevatedButton(onPressed: _openExternal, child: const Text('Buka Halaman Pembayaran')),
                          ))
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.payment_outlined, size: 64, color: AppColors.primaryBlue),
                              const SizedBox(height: 16),
                              const Text('Buka pembayaran di browser', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _openExternal, child: const Text('Buka Browser')),
                              const SizedBox(height: 12),
                              OutlinedButton(onPressed: _checkStatus, child: const Text('Cek Status Pembayaran')),
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
