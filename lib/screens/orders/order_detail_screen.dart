import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../services/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _loading = false;
  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = context.read<OrderService>();
      final detail = await service.getOrderDetail(widget.orderId);
      if (!mounted) {
        return;
      }
      setState(() => _order = detail);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat detail order.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan 🧾')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? const Center(
                  child: Text('Pesanan tidak ditemukan 😢',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side:
                              BorderSide(color: Colors.blue.shade200, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Icon(Icons.shopping_bag,
                                  size: 80, color: Colors.blue),
                              const SizedBox(height: 16),
                              Text(
                                order.orderNumber,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: order.statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.statusLabel,
                                  style: TextStyle(
                                      color: order.statusColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(thickness: 1.5),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Dipesan pada:',
                                      style: TextStyle(color: Colors.blueGrey)),
                                  Text(order.createdAt ?? '-',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Pembayaran:',
                                      style: TextStyle(color: Colors.blueGrey)),
                                  Text(order.paymentMethod ?? '-',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Akhir:',
                                      style: TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 18)),
                                  Text('Rp${order.totalAmount}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.green)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Barang yang Dipesan 🎁',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800)),
                      const SizedBox(height: 12),
                      ...order.items.map(
                        (item) => Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              child:
                                  const Icon(Icons.star, color: Colors.orange),
                            ),
                            title: Text(item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text('Jumlah: ${item.quantity}'),
                            trailing: Text('Rp${item.price}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
