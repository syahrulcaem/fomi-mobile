import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/png_file_saver.dart';
import '../../models/digital_product_model.dart';
import '../../services/shop_service.dart';

class DigitalProductsScreen extends StatefulWidget {
  const DigitalProductsScreen({super.key});

  @override
  State<DigitalProductsScreen> createState() => _DigitalProductsScreenState();
}

class _DigitalProductsScreenState extends State<DigitalProductsScreen> {
  bool _loading = false;
  String? _error;
  UserDigitalProductsResponse? _payload;
  String? _selectedAssetId;
  String? _activeActionKey;
  final Map<String, Uint8List> _previewBytesByKey = <String, Uint8List>{};
  final Set<String> _previewLoadingKeys = <String>{};
  final Set<String> _previewFailedKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response =
          await context.read<ShopService>().getUserDigitalProducts();
      if (!mounted) {
        return;
      }

      final assets = response.activeQrAssets;
      final currentAsset = _selectedAssetId;
      final hasCurrent = currentAsset != null &&
          assets.any((asset) => asset.id == currentAsset);

      setState(() {
        _payload = response;
        _selectedAssetId = hasCurrent
            ? currentAsset
            : (assets.isNotEmpty ? assets.first.id : null);
      });

      _resetPreviewCache();
      _prefetchPreviews(response.items);
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _extractApiMessage(
          e.response?.data,
          fallback: 'Gagal memuat produk digital.',
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Gagal memuat produk digital.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _extractApiMessage(dynamic body, {required String fallback}) {
    if (body is Map<String, dynamic>) {
      final message = body['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }

      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
        final single = first?.toString();
        if (single != null && single.trim().isNotEmpty) {
          return single;
        }
      }
    }

    return fallback;
  }

  Future<void> _preview(UserDigitalProductItem item) async {
    final key = _previewCacheKey(item.id);
    final bytes = _previewBytesByKey[key];
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preview belum tersedia.')),
      );
      return;
    }

    await _showImageDialog(
      title: 'Preview ${item.name}',
      bytes: bytes,
    );
  }

  String _previewCacheKey(String productId) {
    return '$productId::${_selectedAssetId ?? 'default'}';
  }

  void _resetPreviewCache() {
    _previewBytesByKey.clear();
    _previewLoadingKeys.clear();
    _previewFailedKeys.clear();
  }

  void _prefetchPreviews(List<UserDigitalProductItem> items) {
    for (final item in items) {
      _fetchPreviewForItem(item);
    }
  }

  Future<void> _fetchPreviewForItem(
    UserDigitalProductItem item, {
    bool force = false,
  }) async {
    final cacheKey = _previewCacheKey(item.id);
    if (_previewLoadingKeys.contains(cacheKey)) {
      return;
    }

    if (!force &&
        (_previewBytesByKey.containsKey(cacheKey) ||
            _previewFailedKeys.contains(cacheKey))) {
      return;
    }

    if (mounted) {
      setState(() {
        _previewLoadingKeys.add(cacheKey);
        _previewFailedKeys.remove(cacheKey);
      });
    }

    try {
      final bytes =
          await context.read<ShopService>().getUserDigitalProductPreview(
                productId: item.id,
                assetId: _selectedAssetId,
              );

      if (!mounted) {
        return;
      }

      setState(() {
        if (bytes.isNotEmpty) {
          _previewBytesByKey[cacheKey] = bytes;
        } else {
          _previewFailedKeys.add(cacheKey);
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _previewFailedKeys.add(cacheKey);
      });
    } finally {
      if (mounted) {
        setState(() {
          _previewLoadingKeys.remove(cacheKey);
        });
      }
    }
  }

  Future<void> _download(UserDigitalProductItem item) async {
    final actionKey = 'download:${item.id}';
    setState(() => _activeActionKey = actionKey);

    try {
      final bytes =
          await context.read<ShopService>().getUserDigitalProductDownload(
                productId: item.id,
                assetId: _selectedAssetId,
              );

      if (!mounted) {
        return;
      }

      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File download kosong.')),
        );
        return;
      }

      final fileName =
          'sticker-${item.id}-${DateTime.now().millisecondsSinceEpoch}.png';
      final savedPath = await savePngToLocal(bytes: bytes, fileName: fileName);

      if (!mounted) {
        return;
      }

      if (savedPath != null && savedPath.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil disimpan di $savedPath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File diterima (${bytes.lengthInBytes} bytes), tapi penyimpanan lokal belum tersedia di platform ini.',
            ),
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _extractApiMessage(
              e.response?.data,
              fallback: 'Gagal download stiker.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal download stiker.')),
      );
    } finally {
      if (mounted) {
        setState(() => _activeActionKey = null);
      }
    }
  }

  Future<void> _showImageDialog({
    required String title,
    required Uint8List bytes,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: InteractiveViewer(
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return '-';
    }

    try {
      final parsed = DateTime.parse(rawDate).toLocal();
      return '${parsed.day}/${parsed.month}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
    final items = payload?.items ?? const <UserDigitalProductItem>[];
    final assets = payload?.activeQrAssets ?? const <UserDigitalProductAsset>[];

    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        title: const Text('Produk Digital Saya'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _load,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildQrSelector(assets),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Belum ada produk digital yang bisa didownload.',
                            style: TextStyle(fontSize: 13),
                          ),
                        )
                      else
                        ...items.map(_buildItemCard),
                    ],
                  ),
      ),
    );
  }

  Widget _buildQrSelector(List<UserDigitalProductAsset> assets) {
    if (assets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: const Text(
          'Belum ada QR aktif. Preview/download tetap bisa dicoba dengan default asset dari backend jika tersedia.',
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih QR Aktif Untuk Preview',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedAssetId,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: assets
                .map(
                  (asset) => DropdownMenuItem<String>(
                    value: asset.id,
                    child: Text(
                      '${asset.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            selectedItemBuilder: (context) {
              return assets
                  .map(
                    (asset) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${asset.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList();
            },
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _selectedAssetId = value);
              _resetPreviewCache();
              _prefetchPreviews(
                  _payload?.items ?? const <UserDigitalProductItem>[]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(UserDigitalProductItem item) {
    final downloadActionKey = 'download:${item.id}';
    final downloadLoading = _activeActionKey == downloadActionKey;
    final previewKey = _previewCacheKey(item.id);
    final previewBytes = _previewBytesByKey[previewKey];
    final previewLoading = _previewLoadingKeys.contains(previewKey);
    final previewFailed = _previewFailedKeys.contains(previewKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightBlue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            item.description?.trim().isNotEmpty == true
                ? item.description!
                : 'Tanpa deskripsi',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Order: ${item.orderNumber ?? '-'}',
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          Text(
            'Dibeli: ${_formatDate(item.purchasedAt)}',
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          Text(
            'Template: ${item.templateName ?? '-'}',
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: (previewBytes != null && previewBytes.isNotEmpty)
                ? () => _preview(item)
                : null,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.bgBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.skyBlue),
              ),
              child: previewLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : (previewBytes != null && previewBytes.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            previewBytes,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                previewFailed
                                    ? 'Preview gagal dimuat'
                                    : 'Preview belum tersedia',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: downloadLoading ? null : () => _download(item),
              icon: downloadLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download'),
            ),
          ),
        ],
      ),
    );
  }
}




