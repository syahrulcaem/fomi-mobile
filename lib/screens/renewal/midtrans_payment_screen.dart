import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as windows_webview;
import 'package:go_router/go_router.dart';

import '../../core/external_url_launcher.dart';
import '../../services/renewal_service.dart';

class MidtransPaymentScreen extends StatefulWidget {
  const MidtransPaymentScreen({
    super.key,
    required this.snapUrl,
    required this.orderId,
  });

  final String snapUrl;
  final String orderId;

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  WebViewController? _controller;
  windows_webview.WebviewController? _windowsController;
  String _statusMessage = 'Waiting payment action...';
  bool _checking = false;
  bool _initializingWindowsWebView = false;
  bool _showDeepLinkFallback = false;
  Timer? _pollingTimer;

  bool get _supportsMobileWebView {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  bool get _supportsWindowsWebView {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  void initState() {
    super.initState();
    _startPolling();
    if (_supportsMobileWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: _handleNavigationRequest,
            onPageFinished: (url) {
              if (url.contains('finish') ||
                  url.contains('pending') ||
                  url.contains('success')) {
                _checkStatus();
              }
            },
            onWebResourceError: (error) {
              final description = error.description.toLowerCase();
              if (description.contains('err_unknown_url_scheme')) {
                setState(() {
                  _showDeepLinkFallback = true;
                  _statusMessage =
                      'Aplikasi pembayaran belum tersedia di perangkat ini. Cek status pembayaran atau buka halaman di browser eksternal.';
                });
                return;
              }

              setState(() {
                _statusMessage =
                    'Halaman pembayaran gagal dimuat. Gunakan Cek Status untuk konfirmasi.';
              });
            },
          ),
        )
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
      await controller.setPopupWindowPolicy(
        windows_webview.WebviewPopupWindowPolicy.deny,
      );
      await controller.loadUrl(widget.snapUrl);
      if (!mounted) {
        return;
      }
      setState(() {
        _windowsController = controller;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage =
            'WebView Windows gagal diinisialisasi. Gunakan browser eksternal.';
      });
    } finally {
      if (mounted) {
        setState(() => _initializingWindowsWebView = false);
      }
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.snapUrl);
    if (uri == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL pembayaran tidak valid.')),
      );
      return;
    }

    final ok = await ExternalUrlLauncher.launch(widget.snapUrl);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka browser eksternal.')),
      );
    }
  }

  bool _isWebScheme(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' ||
        scheme == 'https' ||
        scheme == 'about' ||
        scheme == 'data' ||
        scheme == 'javascript';
  }

  Future<NavigationDecision> _handleNavigationRequest(
    NavigationRequest request,
  ) async {
    debugPrint(
      '[MidtransPayment][Navigation] main=${request.isMainFrame} '
      'url=${request.url}',
    );

    final uri = Uri.tryParse(request.url);
    if (uri == null || _isWebScheme(uri)) {
      return NavigationDecision.navigate;
    }

    final launched = await ExternalUrlLauncher.launch(request.url);
    if (!launched && mounted) {
      setState(() {
        _showDeepLinkFallback = true;
        _statusMessage =
            'Aplikasi pembayaran tidak ditemukan. Silakan cek status pembayaran atau lanjutkan via browser eksternal.';
      });
    }
    return NavigationDecision.prevent;
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && !_checking && !_navigatingSuccess) {
        _checkStatus(isPolling: true);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _windowsController?.dispose();
    super.dispose();
  }

  bool _navigatingSuccess = false;

  bool _isSuccessStatus(String status) {
    final n = status.trim().toLowerCase();
    return n == 'paid' || n == 'settlement' || n == 'capture' ||
        n == 'authorize' || n == 'success' || n == 'completed' || n == 'processing';
  }

  Future<void> _showSuccessPopupAndNavigate() async {
    if (_navigatingSuccess) return;
    _navigatingSuccess = true;
    if (!mounted) return;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pembayaran Berhasil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Terima kasih, pembayaran Anda telah berhasil dikonfirmasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    if (!mounted) return;
    context.go('/orders');
  }

  Future<void> _checkStatus({bool isPolling = false}) async {
    if (_checking || widget.orderId.isEmpty) {
      return;
    }

    setState(() {
      _checking = true;
      if (!isPolling) {
        _statusMessage = 'Checking payment status...';
      }
    });

    try {
      final service = context.read<RenewalService>();
      final result = await service.checkMidtransStatus(orderId: widget.orderId);
      if (!mounted) {
        return;
      }
      final status = result.transactionStatus ?? 'unknown';
      if (!isPolling || _isSuccessStatus(status)) {
        setState(() {
          _statusMessage = 'Status: $status';
        });
      }
      
      if (_isSuccessStatus(status)) {
        _pollingTimer?.cancel();
        await _showSuccessPopupAndNavigate();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      if (!isPolling) {
        setState(() {
          _statusMessage = 'Gagal cek status pembayaran.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Midtrans Payment'),
        actions: [
          IconButton(
            onPressed: _checking ? null : _checkStatus,
            icon: const Icon(Icons.refresh),
            tooltip: 'Check Status',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(_statusMessage),
          ),
          Expanded(
            child: _showDeepLinkFallback
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.open_in_new_off,
                            size: 52,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Aplikasi pembayaran tidak tersedia di perangkat ini.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _checking ? null : _checkStatus,
                            child: const Text('Cek Status Pembayaran'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _openExternal,
                            child: const Text('Buka di Browser Eksternal'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _supportsMobileWebView
                    ? WebViewWidget(controller: _controller!)
                    : _supportsWindowsWebView
                        ? (_windowsController != null
                            ? windows_webview.Webview(
                                _windowsController!,
                              )
                            : Center(
                                child: _initializingWindowsWebView
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton(
                                        onPressed: _openExternal,
                                        child: const Text('Open Payment Page'),
                                      ),
                              ))
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'WebView tidak tersedia di platform ini. Buka pembayaran di browser eksternal.',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _openExternal,
                                    child: const Text('Open Payment Page'),
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
}
