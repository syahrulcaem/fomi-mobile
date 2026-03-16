import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/qr_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._qrService);

  final QrService _qrService;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _dashboard = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get dashboard => _dashboard;

  int get totalAssets => _readStat('total_assets');
  int get lostAssets => _readStat('lost_assets');
  int get activeQrCodes => _readStat('active_qr_codes');
  int get totalOrders => _readStat('total_orders');

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await _qrService.getDashboard();
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message']?.toString() ??
          'Gagal mengambil dashboard.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _readStat(String key) {
    final stats = _dashboard['stats'];
    if (stats is Map<String, dynamic>) {
      return (stats[key] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}
