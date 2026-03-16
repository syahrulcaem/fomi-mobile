import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/asset_model.dart';
import '../services/asset_service.dart';

class AssetProvider extends ChangeNotifier {
  AssetProvider(this._assetService);

  final AssetService _assetService;

  List<AssetModel> _assets = [];
  AssetModel? _selectedAsset;
  bool _isLoading = false;
  String? _errorMessage;

  List<AssetModel> get assets => _assets;
  AssetModel? get selectedAsset => _selectedAsset;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAssets() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _assets = await _assetService.getAssets();
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message']?.toString() ??
          'Gagal mengambil data asset.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAssetDetail(String id) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _selectedAsset = await _assetService.getAssetDetail(id);
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message']?.toString() ??
          'Gagal mengambil detail asset.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createAsset({
    required String name,
    String? description,
  }) async {
    _errorMessage = null;
    try {
      await _assetService.createAsset(name: name, description: description);
      await fetchAssets();
      return true;
    } on DioException catch (e) {
      _errorMessage =
          e.response?.data?['message']?.toString() ?? 'Gagal membuat asset.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAsset({
    required String id,
    required String name,
    String? description,
  }) async {
    _errorMessage = null;
    try {
      final updated = await _assetService.updateAsset(
        assetId: id,
        name: name,
        description: description,
      );
      _selectedAsset = updated;
      final index = _assets.indexWhere((a) => a.id == id);
      if (index != -1) {
        _assets[index] = updated;
      }
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message']?.toString() ??
          'Gagal memperbarui asset.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleLostStatus(String id) async {
    _errorMessage = null;
    try {
      final updated = await _assetService.toggleStatus(id);
      final index = _assets.indexWhere((a) => a.id == id);
      if (index != -1) {
        _assets[index] = updated;
      }
      if (_selectedAsset?.id == id) {
        _selectedAsset = updated;
      }
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message']?.toString() ??
          'Gagal mengubah status asset.';
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
