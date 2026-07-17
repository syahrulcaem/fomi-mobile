import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/shop_theme.dart';
import '../../core/png_file_saver.dart';
import '../../models/digital_product_model.dart';
import '../../services/shop_service.dart';

class DigitalProductsScreen extends StatefulWidget {
  const DigitalProductsScreen({super.key});

  @override
  State<DigitalProductsScreen> createState() => _DigitalProductsScreenState();
}

class _DigitalProductsScreenState extends State<DigitalProductsScreen> {
  static UserDigitalProductsResponse? _sessionPayload;
  static String? _sessionSelectedAssetId;
  static final Map<String, Uint8List> _sessionPreviewBytesByKey =
      <String, Uint8List>{};
  static final Set<String> _sessionPreviewFailedKeys = <String>{};

  bool _loading = false;
  String? _error;
  UserDigitalProductsResponse? _payload;
  String? _selectedAssetId;
  String? _activeActionKey;
  final Set<String> _previewLoadingKeys = <String>{};

  @override
  void initState() {
    super.initState();
    if (_sessionPayload != null) {
      _hydrateFromSessionCache(notify: false);
      _prefetchPreviews(_sessionPayload!.items);
      return;
    }
    _load();
  }

  void _hydrateFromSessionCache({bool notify = true}) {
    final payload = _sessionPayload;
    final assets = payload?.activeQrAssets ?? const <UserDigitalProductAsset>[];
    final cachedSelected = _sessionSelectedAssetId;
    final hasCached = cachedSelected != null &&
        assets.any((asset) => asset.id == cachedSelected);

    final nextSelected = hasCached
        ? cachedSelected
        : (assets.isNotEmpty ? assets.first.id : null);

    if (!notify) {
      _payload = payload;
      _selectedAssetId = nextSelected;
      _error = null;
      _loading = false;
      return;
    }

    setState(() {
      _payload = payload;
      _selectedAssetId = nextSelected;
      _error = null;
      _loading = false;
    });
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!forceRefresh && _sessionPayload != null) {
      _hydrateFromSessionCache();
      _prefetchPreviews(_sessionPayload!.items);
      return;
    }

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

      _sessionPayload = response;
      _sessionSelectedAssetId = _selectedAssetId;
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
    final bytes = _sessionPreviewBytesByKey[key];
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
        (_sessionPreviewBytesByKey.containsKey(cacheKey) ||
            _sessionPreviewFailedKeys.contains(cacheKey))) {
      return;
    }

    if (mounted) {
      setState(() {
        _previewLoadingKeys.add(cacheKey);
        _sessionPreviewFailedKeys.remove(cacheKey);
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
          _sessionPreviewBytesByKey[cacheKey] = bytes;
          _sessionPreviewFailedKeys.remove(cacheKey);
        } else {
          _sessionPreviewFailedKeys.add(cacheKey);
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sessionPreviewFailedKeys.add(cacheKey);
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
      final previewKey = _previewCacheKey(item.id);
      _sessionPreviewBytesByKey[previewKey] = bytes;
      _sessionPreviewFailedKeys.remove(previewKey);

      if (!mounted) {
        return;
      }

      if (savedPath != null && savedPath.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedPath == 'gallery'
                  ? 'Berhasil disimpan ke Gallery.'
                  : 'Berhasil disimpan di $savedPath',
            ),
          ),
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
      backgroundColor: SC.bg,
      appBar: AppBar(
        backgroundColor: SC.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              decoration: BoxDecoration(
                color: SC.redLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: SC.red),
            ),
          ),
        ),
        title: Text('Produk Digital Saya',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: SC.textPrimary)),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        color: SC.red,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: SC.red))
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: SC.redLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SC.redSoft),
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
                              onPressed: () => _load(forceRefresh: true),
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
          color: SC.redLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SC.redSoft),
        ),
        child: Text(
          'Belum ada QR aktif. Preview/download tetap bisa dicoba dengan default asset dari backend jika tersedia.',
          style: GoogleFonts.poppins(fontSize: 12, color: SC.red),
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
                      asset.name,
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
                        asset.name,
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
              _sessionSelectedAssetId = value;
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
    final previewBytes = _sessionPreviewBytesByKey[previewKey];
    final previewLoading = _previewLoadingKeys.contains(previewKey);
    final previewFailed = _sessionPreviewFailedKeys.contains(previewKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SC.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: SC.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            item.description?.trim().isNotEmpty == true
                ? item.description!
                : 'Tanpa deskripsi',
            style: GoogleFonts.poppins(fontSize: 12, color: SC.textSecondary),
          ),
          const SizedBox(height: 8),
          Text('Order: ${item.orderNumber ?? '-'}',
              style: GoogleFonts.poppins(fontSize: 11, color: SC.textSecondary)),
          Text('Dibeli: ${_formatDate(item.purchasedAt)}',
              style: GoogleFonts.poppins(fontSize: 11, color: SC.textSecondary)),
          Text('Template: ${item.templateName ?? '-'}',
              style: GoogleFonts.poppins(fontSize: 11, color: SC.textSecondary)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: (previewBytes != null && previewBytes.isNotEmpty)
                ? () => _preview(item)
                : null,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: SC.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SC.redSoft),
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
                                color: SC.textSecondary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                previewFailed
                                    ? 'Preview gagal dimuat'
                                    : 'Preview belum tersedia',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: SC.textSecondary,
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
            child: GestureDetector(
              onTap: downloadLoading ? null : () => _download(item),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: downloadLoading ? null : SC.redGradient,
                  color: downloadLoading ? Colors.grey.shade200 : null,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: downloadLoading ? [] : SC.redShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    downloadLoading
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_rounded,
                            size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Download',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: downloadLoading ? SC.textSecondary : Colors.white)),
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
