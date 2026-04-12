import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/checkout_context_model.dart';
import '../../models/renewal_package_model.dart';
import '../../services/renewal_service.dart';
import '../../services/shop_service.dart';

enum _SubscriptionCheckoutMode {
  buyNew,
  renew,
}

class RenewalScreen extends StatefulWidget {
  const RenewalScreen({super.key});

  @override
  State<RenewalScreen> createState() => _RenewalScreenState();
}

class _RenewalScreenState extends State<RenewalScreen> {
  bool _loading = false;
  bool _checkingOut = false;
  String? _loadError;
  List<RenewalPackageModel> _packages = [];
  List<CheckoutRenewalTargetModel> _renewalTargets = [];
  _SubscriptionCheckoutMode _mode = _SubscriptionCheckoutMode.buyNew;
  CheckoutRenewalTargetModel? _selectedRenewalTarget;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final renewalService = context.read<RenewalService>();
      final shopService = context.read<ShopService>();

      final results = await Future.wait<dynamic>([
        renewalService.getPackages(),
        shopService.getCheckoutContextModel(),
      ]);

      final packages = results[0] as List<RenewalPackageModel>;
      final checkoutContext = results[1] as CheckoutContextModel;

      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = null;
        _packages = packages;
        _renewalTargets = checkoutContext.renewalTargets;
        if (_renewalTargets.isNotEmpty &&
            (_selectedRenewalTarget == null ||
                !_renewalTargets
                    .any((t) => t.id == _selectedRenewalTarget!.id))) {
          _selectedRenewalTarget = _renewalTargets.first;
        }
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = _resolveApiMessage(
          e.response?.data,
          fallback: 'Gagal memuat data checkout langganan.',
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = 'Gagal memuat data checkout langganan.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _checkout(RenewalPackageModel item) async {
    if (_mode == _SubscriptionCheckoutMode.renew &&
        _selectedRenewalTarget == null) {
      _showSnack(
        'Pilih target asset yang ingin diperpanjang terlebih dahulu.',
      );
      return;
    }

    setState(() => _checkingOut = true);
    try {
      final service = context.read<RenewalService>();
      final result = await service.checkoutRenewal(
        productId: item.id,
        quantity: 1,
        renewalAssetId: _mode == _SubscriptionCheckoutMode.renew
            ? _selectedRenewalTarget?.id
            : null,
      );

      if (!mounted) {
        return;
      }

      final snapUrl = result.resolvedSnapUrl;
      if (snapUrl == null || snapUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ??
                  ((result.snapToken != null && result.snapToken!.isNotEmpty)
                      ? 'Token pembayaran diterima, tapi URL tidak bisa dibentuk.'
                      : 'Snap URL/Token tidak tersedia dari API.'),
            ),
          ),
        );
        return;
      }

      context.push(
        '/renewal/payment?snapUrl=${Uri.encodeComponent(snapUrl)}&orderId=${Uri.encodeComponent(result.orderId ?? '')}',
      );
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }

      final fallback = (e.response?.statusCode ?? 0) >= 400 &&
              (e.response?.statusCode ?? 0) < 500
          ? 'Permintaan checkout tidak valid. Periksa data lalu coba lagi.'
          : 'Checkout langganan gagal. Silakan coba lagi.';

      _showSnack(
        _resolveApiMessage(e.response?.data, fallback: fallback),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnack('Checkout langganan gagal. Silakan coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _checkingOut = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _resolveApiMessage(dynamic body, {required String fallback}) {
    if (body is Map<String, dynamic>) {
      final message = body['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }

      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first.toString().trim();
            if (first.isNotEmpty) {
              return first;
            }
          }
          final single = value?.toString().trim();
          if (single != null && single.isNotEmpty) {
            return single;
          }
        }
      }
    }

    return fallback;
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.trim().isEmpty) {
      return '-';
    }
    try {
      final parsed = DateTime.parse(isoDate).toLocal();
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Langganan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_loadError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_loadError!)),
                          TextButton(
                              onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  _buildModeSwitch(),
                  if (_mode == _SubscriptionCheckoutMode.renew) ...[
                    const SizedBox(height: 12),
                    _buildRenewalTargetSelector(),
                  ],
                  const SizedBox(height: 16),
                  if (_packages.isEmpty)
                    const _EmptyPackagesState()
                  else
                    ..._packages.map(_buildPackageCard),
                ],
              ),
            ),
    );
  }

  Widget _buildModeSwitch() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mode Checkout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Beli paket baru')),
                    selected: _mode == _SubscriptionCheckoutMode.buyNew,
                    onSelected: (_) {
                      setState(() {
                        _mode = _SubscriptionCheckoutMode.buyNew;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Perpanjang paket')),
                    selected: _mode == _SubscriptionCheckoutMode.renew,
                    onSelected: (_) {
                      setState(() {
                        _mode = _SubscriptionCheckoutMode.renew;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenewalTargetSelector() {
    if (_renewalTargets.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.orange.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Tidak ada target renewal yang aktif. Pilih mode "Beli paket baru" atau aktifkan QR lebih dulu.',
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Perpanjangan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRenewalTarget?.id,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _renewalTargets
                  .map(
                    (target) => DropdownMenuItem<String>(
                      value: target.id,
                      child: Text(
                        '${target.name} • Exp: ${_formatDate(target.expiresAt)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedRenewalTarget =
                      _renewalTargets.where((item) => item.id == value).first;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(RenewalPackageModel item) {
    final checkoutLabel =
        _mode == _SubscriptionCheckoutMode.renew ? 'Perpanjang' : 'Beli Baru';
    final canCheckout = _mode == _SubscriptionCheckoutMode.buyNew ||
        _selectedRenewalTarget != null;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.blue.shade200, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.star, color: Colors.orange, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          '${item.barcodeQuota} Kuota Barcode',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1.5),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rp${item.price}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.orange.shade800,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _checkingOut || !canCheckout
                      ? null
                      : () => _checkout(item),
                  icon: _checkingOut
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shopping_cart_checkout),
                  label: Text(checkoutLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPackagesState extends StatelessWidget {
  const _EmptyPackagesState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 80),
        Icon(Icons.inventory_2_outlined, size: 92, color: Colors.grey),
        SizedBox(height: 12),
        Text(
          'Belum ada paket langganan tersedia.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }
}
