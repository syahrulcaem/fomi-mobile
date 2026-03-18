import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../models/paginated_response.dart';
import '../../services/order_service.dart';
import '../../widgets/main_shell.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  bool _loading = false;
  int _page = 1;
  PaginatedResponse<OrderModel> _result = PaginatedResponse<OrderModel>(
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
      final service = context.read<OrderService>();
      final nextPage = page ?? _page;
      final data = await service.getOrders(page: nextPage);
      if (!mounted) {
        return;
      }
      setState(() {
        _page = nextPage;
        _result = data;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat order.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentIndex: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('Kiriman Pesananku 📦')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _load(page: _page),
                    child: _result.items.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Icon(Icons.inbox, size: 100, color: Colors.grey),
                              SizedBox(height: 16),
                              Center(
                                child: Text(
                                  'Belum ada pesanan nih!',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _result.items.length,
                            itemBuilder: (context, index) {
                              final order = _result.items[index];
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                      color: Colors.blue.shade100, width: 2),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.purple.shade100,
                                    radius: 24,
                                    child: const Icon(Icons.local_shipping,
                                        color: Colors.purple),
                                  ),
                                  title: Text(
                                    order.orderNumber,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('Status: ${order.statusLabel}',
                                          style: TextStyle(
                                              color: Colors.orange.shade800,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total: Rp${order.totalAmount}',
                                        style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right,
                                      color: Colors.blue, size: 30),
                                  onTap: () =>
                                      context.push('/orders/${order.id}'),
                                ),
                              );
                            },
                          ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _page > 1 && !_loading
                        ? () => _load(page: _page - 1)
                        : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400),
                    child: const Text('Sebelumnya'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Hal. ${_result.currentPage}/${_result.lastPage}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _result.hasMore && !_loading
                        ? () => _load(page: _page + 1)
                        : null,
                    child: const Text('Berikutnya'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
