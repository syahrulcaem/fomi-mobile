import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/asset_provider.dart';

class EditAssetScreen extends StatefulWidget {
  const EditAssetScreen({super.key, required this.assetId});

  final String assetId;

  @override
  State<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AssetProvider>();
      await provider.fetchAssetDetail(widget.assetId);
      final asset = provider.selectedAsset;
      if (!mounted || asset == null) {
        return;
      }
      _nameController.text = asset.name;
      _descController.text = asset.description ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final ok = await context.read<AssetProvider>().updateAsset(
          id: widget.assetId,
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
        );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    if (ok) {
      context.pop();
    } else {
      final message = context.read<AssetProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Gagal menyimpan perubahan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Asset ✏️')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.blue.shade200, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.edit_document, size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Asset',
                    prefixIcon: Icon(Icons.abc),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Tambahan',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(_loading ? 'Menyimpan...' : 'Simpan Perubahan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
