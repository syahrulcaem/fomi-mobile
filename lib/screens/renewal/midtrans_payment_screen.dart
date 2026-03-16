import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as windows_webview;

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
    if (_supportsMobileWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) {
              if (url.contains('finish') ||
                  url.contains('pending') ||
                  url.contains('success')) {
                _checkStatus();
              }
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

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka browser eksternal.')),
      );
    }
  }

  @override
  void dispose() {
    _windowsController?.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_checking || widget.orderId.isEmpty) {
      return;
    }

    setState(() {
      _checking = true;
      _statusMessage = 'Checking payment status...';
    });

    try {
      final service = context.read<RenewalService>();
      final result = await service.checkMidtransStatus(orderId: widget.orderId);
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Status: ${result.transactionStatus ?? 'unknown'}';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Gagal cek status pembayaran.';
      });
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
            child: _supportsMobileWebView
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
