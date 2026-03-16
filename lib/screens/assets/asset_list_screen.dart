import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/asset_provider.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetProvider>().fetchAssets();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _showCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Asset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Asset'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final desc = _descController.text.trim();
                if (name.isEmpty) {
                  return;
                }
                final ok = await context.read<AssetProvider>().createAsset(
                      name: name,
                      description: desc.isEmpty ? null : desc,
                    );
                _nameController.clear();
                _descController.clear();
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
                if (!ok) {
                  final error = context.read<AssetProvider>().errorMessage;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? 'Gagal membuat asset')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssetProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Assetku 🎒')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, size: 30),
      ),
      body: RefreshIndicator(
        onRefresh: provider.fetchAssets,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.assets.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Icon(Icons.category_outlined,
                          size: 100, color: Colors.blueGrey),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Kamu belum punya asset nih!',
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
                    itemCount: provider.assets.length,
                    itemBuilder: (context, index) {
                      final asset = provider.assets[index];
                      final qrCode = asset.primaryQrCode?.code;
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side:
                              BorderSide(color: Colors.blue.shade100, width: 2),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            radius: 28,
                            child: const Icon(Icons.inventory,
                                color: Colors.blue, size: 32),
                          ),
                          title: Text(
                            asset.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Status: ${asset.status ?? '-'}',
                                    style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('QR: ${qrCode ?? '-'}',
                                    style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              color: Colors.blue),
                          onTap: () => context.push('/assets/${asset.id}'),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
