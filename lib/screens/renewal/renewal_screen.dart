import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/renewal_package_model.dart';
import '../../services/renewal_service.dart';

class RenewalScreen extends StatefulWidget {
  const RenewalScreen({super.key});

  @override
  State<RenewalScreen> createState() => _RenewalScreenState();
}

class _RenewalScreenState extends State<RenewalScreen> {
  bool _loading = false;
  List<RenewalPackageModel> _packages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = context.read<RenewalService>();
      final data = await service.getPackages();
      if (!mounted) {
        return;
      }
      setState(() => _packages = data);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat paket renewal.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _checkout(RenewalPackageModel item) async {
    setState(() => _loading = true);
    try {
      final service = context.read<RenewalService>();
      final result = await service.checkoutRenewal(productId: item.id);
      if (!mounted) {
        return;
      }

      final snapUrl = result.resolvedSnapUrl;
      if (snapUrl == null || snapUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.snapToken != null && result.snapToken!.isNotEmpty
                  ? 'Token pembayaran diterima, tapi URL tidak bisa dibentuk.'
                  : 'Snap URL/Token tidak tersedia dari API.',
            ),
          ),
        );
        return;
      }

      context.push(
        '/renewal/payment?snapUrl=$snapUrl&orderId=${result.orderId ?? ''}',
      );
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      final body = e.response?.data;
      String message = 'Checkout renewal gagal.';
      if (body is Map<String, dynamic>) {
        final apiMessage = body['message']?.toString();
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            message = first.first.toString();
          } else if (apiMessage != null && apiMessage.isNotEmpty) {
            message = apiMessage;
          }
        } else if (apiMessage != null && apiMessage.isNotEmpty) {
          message = apiMessage;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout renewal gagal.')),
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
      appBar: AppBar(title: const Text('Paket Renewal 🌟')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _packages.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Icon(Icons.inventory_2_outlined,
                            size: 100, color: Colors.grey),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Wah, belum ada paket renewal nih!',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _packages.length,
                      itemBuilder: (context, index) {
                        final item = _packages[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                                color: Colors.blue.shade200, width: 2),
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
                                      child: const Icon(Icons.star,
                                          color: Colors.orange, size: 36),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.green.shade200),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      onPressed: () => _checkout(item),
                                      icon: const Icon(
                                          Icons.shopping_cart_checkout),
                                      label: const Text('Beli'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
