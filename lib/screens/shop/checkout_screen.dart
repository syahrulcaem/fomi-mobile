import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../core/shop_theme.dart';
import '../../core/product_type.dart';
import '../../models/checkout_address_model.dart';
import '../../models/checkout_region_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/shop_service.dart';

//

class _QrAsset {
  _QrAsset({
    required this.id,
    required this.name,
    this.expiresAt,
  });
  final String id;
  final String name;
  final String? expiresAt;

  factory _QrAsset.fromJson(Map<String, dynamic> j) => _QrAsset(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? 'Asset',
        expiresAt: j['active_subscription']?['expires_at']?.toString() ??
            j['expires_at']?.toString(),
      );
}

class _SavedAddress {
  _SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.province,
    required this.city,
    required this.postalCode,
    this.provinceId,
    required this.regencyId,
    this.districtId,
    this.districtName,
  });
  final String id;
  final String label;
  final String address;
  final String province;
  final String city;
  final String postalCode;
  final int? provinceId;
  final int regencyId;
  final int? districtId;
  final String? districtName;

  factory _SavedAddress.fromJson(Map<String, dynamic> j) => _SavedAddress(
        id: j['id']?.toString() ?? '',
        label: j['label']?.toString() ?? 'Alamat',
        address: j['shipping_address']?.toString() ?? '',
        province: j['province_name']?.toString() ??
            j['shipping_province']?.toString() ??
            '',
        city: j['regency_name']?.toString() ??
            j['shipping_city']?.toString() ??
            '',
        postalCode: j['shipping_postal_code']?.toString() ?? '',
        provinceId: (j['province_id'] as num?)?.toInt(),
        regencyId: (j['regency_id'] as num?)?.toInt() ?? 0,
        districtId: (j['district_id'] as num?)?.toInt(),
        districtName: j['district_name']?.toString(),
      );

  factory _SavedAddress.fromModel(CheckoutAddressModel model) => _SavedAddress(
        id: model.id,
        label: model.label,
        address: model.shippingAddress,
        province: model.provinceName,
        city: model.regencyName,
        postalCode: model.shippingPostalCode,
        provinceId: model.provinceId,
        regencyId: model.regencyId ?? 0,
        districtId: model.districtId,
        districtName: model.districtName,
      );

  String get fullDisplay => '$address, $city, $province $postalCode';
}

class _ShippingService {
  _ShippingService({
    required this.service,
    required this.description,
    required this.cost,
    this.etd,
  });
  final String service;
  final String description;
  final int cost;
  final String? etd;
}

//

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  //
  int _step = 0; // 0=Penerima, 1=Alamat+QR, 2=Ongkir, 3=Review
  static const int _totalSteps = 4;

  //
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();

  //
  bool _ctxLoading = true;
  String? _ctxError;
  List<_QrAsset> _qrAssets = [];
  List<_SavedAddress> _savedAddresses = [];
  List<String> _availableCouriers = [];
  int? _regencyId;
  int? _districtId;
  List<CheckoutProvinceModel> _provinces = [];
  List<CheckoutCityModel> _cities = [];
  List<CheckoutDistrictModel> _districts = [];
  int? _selectedProvinceId;
  int? _selectedCityId;
  bool _regionLoading = false;
  String? _regionError;

  //
  _QrAsset? _selectedQr;
  _SavedAddress? _selectedSavedAddress;
  String? _selectedCourier;
  _ShippingService? _selectedService;

  //
  bool _shippingLoading = false;
  List<_ShippingService> _shippingServices = [];
  String? _shippingError;

  //
  bool _paying = false;

  //
  String _fmt(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  bool _isPhysicalType(String type) {
    return isPhysicalProductType(type);
  }

  bool _isDigitalType(String type) {
    return isDigitalProductType(type);
  }

  bool _hasPhysicalProducts(CartProvider cart) {
    return cart.items.any((item) => _isPhysicalType(item.type));
  }

  bool _hasDigitalProducts(CartProvider cart) {
    return cart.items.any((item) => _isDigitalType(item.type));
  }

  List<dynamic> _extractShippingRows(dynamic raw) {
    if (raw is List) {
      return raw;
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return (map['data'] is Map
              ? (Map<String, dynamic>.from(map['data'] as Map)['costs']
                  as List?)
              : null) ??
          (map['costs'] as List?) ??
          (map['data'] as List?) ??
          const [];
    }
    return const [];
  }

  _ShippingService? _parseShippingServiceEntry(dynamic raw) {
    if (raw is! Map) return null;

    final entry = Map<String, dynamic>.from(raw);
    final service = entry['service']?.toString() ?? '';
    if (service.isEmpty) return null;

    int cost = 0;
    String? etd = entry['etd']?.toString();
    final rawCost = entry['cost'];

    if (rawCost is List && rawCost.isNotEmpty && rawCost.first is Map) {
      final firstCost = Map<String, dynamic>.from(rawCost.first as Map);
      cost = (firstCost['value'] as num?)?.toInt() ?? 0;
      etd ??= firstCost['etd']?.toString();
    } else {
      cost = (rawCost as num?)?.toInt() ?? 0;
    }

    return _ShippingService(
      service: service,
      description: entry['description']?.toString() ?? '',
      cost: cost,
      etd: etd,
    );
  }

  List<_ShippingService> _parseShippingServices(dynamic raw) {
    final rows = _extractShippingRows(raw);
    final services = <_ShippingService>[];

    for (final row in rows) {
      if (row is! Map) continue;

      final entry = Map<String, dynamic>.from(row);
      final nestedCosts = entry['costs'];
      if (nestedCosts is List) {
        for (final costEntry in nestedCosts) {
          final parsed = _parseShippingServiceEntry(costEntry);
          if (parsed != null) services.add(parsed);
        }
        continue;
      }

      final parsed = _parseShippingServiceEntry(entry);
      if (parsed != null) services.add(parsed);
    }

    return services;
  }

  //

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  //

  Future<void> _loadContext() async {
    setState(() {
      _ctxLoading = true;
      _ctxError = null;
    });
    try {
      final svc = context.read<ShopService>();
      final ctx = await svc.getCheckoutContext();

      // Pre-fill customer info
      final customer = ctx['customer'] as Map?;
      if (customer != null) {
        _nameCtrl.text = customer['name']?.toString() ?? '';
        _emailCtrl.text = customer['email']?.toString() ?? '';
        _phoneCtrl.text = customer['phone']?.toString() ?? '';
      }

      // Active QR assets
      final qrRaw = ctx['active_qr_assets'];
      if (qrRaw is List) {
        _qrAssets = qrRaw
            .whereType<Map<String, dynamic>>()
            .map(_QrAsset.fromJson)
            .where((a) => a.id.isNotEmpty)
            .toList();
        if (_qrAssets.length == 1) _selectedQr = _qrAssets.first;
      }

      // Saved addresses (new endpoint first, then context fallback)
      final addressList = await svc.getCheckoutAddresses();
      if (addressList.isNotEmpty) {
        _savedAddresses = addressList.map(_SavedAddress.fromModel).toList();
      } else {
        final addrRaw = ctx['saved_addresses'];
        if (addrRaw is List) {
          _savedAddresses = addrRaw
              .whereType<Map<String, dynamic>>()
              .map(_SavedAddress.fromJson)
              .toList();
        }
      }

      // Auto-apply if exactly one saved address
      if (_savedAddresses.length == 1) {
        final a = _savedAddresses.first;
        _selectedSavedAddress = a;
        _addressCtrl.text = a.address;
        _postalCtrl.text = a.postalCode;
      }

      await _loadProvinces();

      if (_savedAddresses.length == 1) {
        await _applySavedAddress(_savedAddresses.first);
      }

      // Available couriers
      final courierRaw = ctx['available_shipping_couriers'];
      if (courierRaw is List) {
        _availableCouriers = courierRaw.map((e) => e.toString()).toList();
      }
      if (_availableCouriers.isEmpty) {
        _availableCouriers = ['jne', 'j&t', 'sicepat'];
      }
      _selectedCourier = _availableCouriers.first;

      setState(() => _ctxLoading = false);
    } catch (e) {
      setState(() {
        _ctxLoading = false;
        _ctxError = 'Gagal memuat data checkout.';
      });
    }
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _regionLoading = true;
      _regionError = null;
    });

    try {
      final svc = context.read<ShopService>();
      final provinces = await svc.getCheckoutProvinces();
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _regionLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _regionLoading = false;
        _regionError = 'Gagal memuat data wilayah. Coba lagi.';
      });
    }
  }

  Future<void> _loadCities(int provinceId, {int? selectedCityId}) async {
    setState(() {
      _regionLoading = true;
      _regionError = null;
      _cities = [];
      _districts = [];
      _selectedCityId = null;
      _selectedProvinceId = provinceId;
      _selectedSavedAddress = null;
      _cityCtrl.clear();
      _provinceCtrl.text = _provinces
              .where((item) => item.id == provinceId)
              .map((e) => e.name)
              .firstOrNull ??
          '';
      _regencyId = null;
      _districtId = null;
    });

    try {
      final svc = context.read<ShopService>();
      final cities = await svc.getCheckoutCities(provinceId: provinceId);
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _selectedCityId = selectedCityId != null &&
                cities.any((item) => item.id == selectedCityId)
            ? selectedCityId
            : null;
        _regencyId = _selectedCityId;
        if (_selectedCityId != null) {
          final selected =
              cities.where((item) => item.id == _selectedCityId).first;
          _cityCtrl.text = selected.name;
        }
        _regionLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _regionLoading = false;
        _regionError = 'Gagal memuat data kota/kabupaten.';
      });
    }
  }

  Future<void> _loadDistricts(int regencyId, {int? selectedDistrictId}) async {
    setState(() {
      _regionLoading = true;
      _regionError = null;
      _districts = [];
      _districtId = null;
    });

    try {
      final svc = context.read<ShopService>();
      final districts = await svc.getCheckoutDistricts(regencyId: regencyId);
      if (!mounted) return;
      setState(() {
        _districts = districts;
        _districtId = selectedDistrictId != null &&
                districts.any((item) => item.id == selectedDistrictId)
            ? selectedDistrictId
            : null;
        _regionLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _regionLoading = false;
        _regionError = 'Gagal memuat data kecamatan.';
      });
    }
  }

  Future<void> _fetchShipping() async {
    if (_regencyId == null) return;
    setState(() {
      _shippingLoading = true;
      _shippingError = null;
      _shippingServices = [];
      _selectedService = null;
    });
    try {
      final svc = context.read<ShopService>();
      final raw = await svc.getShippingCosts(
        regencyId: _regencyId!,
        courier: _selectedCourier ?? 'jne',
        totalWeight: 500, // default weight; ideally sum from products
      );
      final services = _parseShippingServices(raw);
      setState(() {
        _shippingServices = services;
        _shippingLoading = false;
      });
    } catch (_) {
      setState(() {
        _shippingLoading = false;
        _shippingError = 'Gagal menghitung ongkir. Coba lagi.';
      });
    }
  }

  Future<void> _pay() async {
    final cart = context.read<CartProvider>();
    final hasPhysical = _hasPhysicalProducts(cart);
    final hasDigital = _hasDigitalProducts(cart);
    final needsQrSelection = hasPhysical || hasDigital;

    if (needsQrSelection && _selectedQr == null) {
      _showError('Pilih QR asset terlebih dahulu untuk checkout.');
      return;
    }

    setState(() => _paying = true);
    try {
      final data = <String, dynamic>{
        'items': cart.items
            .map((e) => {
                  'product_id': e.productId,
                  if (e.variantId != null) 'variant_id': e.variantId,
                  'quantity': e.quantity,
                })
            .toList(),
        'customer_name': _nameCtrl.text.trim(),
        'customer_email': _emailCtrl.text.trim(),
        'customer_phone': _phoneCtrl.text.trim(),
        if (needsQrSelection) 'selected_asset_id': _selectedQr!.id,
      };

      if (hasPhysical) {
        data['shipping_address'] = _addressCtrl.text.trim();
        data['shipping_city'] = _cityCtrl.text.trim();
        data['shipping_province'] = _provinceCtrl.text.trim();
        data['shipping_postal_code'] = _postalCtrl.text.trim();
        data['regency_id'] = _regencyId;
        if (_districtId != null) data['district_id'] = _districtId;
        data['shipping_cost'] = _selectedService?.cost ?? 0;
        data['shipping_courier'] = _selectedCourier;
        data['shipping_service'] = _selectedService?.service;
      }

      final svc = context.read<ShopService>();
      final result = await svc.checkout(data);
      if (!mounted) return;

      final redirectUrl = _extractCheckoutRedirectUrl(result);
      final orderId = _extractCheckoutOrderId(result);

      if (redirectUrl.isNotEmpty) {
        context.push(
            '/shop/payment?snapUrl=${Uri.encodeComponent(redirectUrl)}&orderId=${Uri.encodeComponent(orderId)}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal mendapatkan link pembayaran.'),
              backgroundColor: Colors.red),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final body = e.response?.data;
      String msg = 'Checkout gagal.';
      if (body is Map<String, dynamic>) {
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) msg = first.first.toString();
        } else {
          msg = body['message']?.toString() ?? msg;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  String _extractCheckoutRedirectUrl(Map<String, dynamic> result) {
    final order = result['order'];
    final orderMap = order is Map ? Map<String, dynamic>.from(order) : null;
    final payment = orderMap?['payment'];
    final paymentMap =
        payment is Map ? Map<String, dynamic>.from(payment) : null;

    return result['redirect_url']?.toString() ??
        result['snap_url']?.toString() ??
        paymentMap?['redirect_url']?.toString() ??
        paymentMap?['snap_url']?.toString() ??
        '';
  }

  String _extractCheckoutOrderId(Map<String, dynamic> result) {
    final order = result['order'];
    final orderMap = order is Map ? Map<String, dynamic>.from(order) : null;
    final payment = orderMap?['payment'];
    final paymentMap =
        payment is Map ? Map<String, dynamic>.from(payment) : null;

    return paymentMap?['midtrans_order_id']?.toString() ??
        result['order_id']?.toString() ??
        result['transaction_id']?.toString() ??
        orderMap?['order_id']?.toString() ??
        orderMap?['id']?.toString() ??
        '';
  }

  //

  void _next() {
    final cart = context.read<CartProvider>();
    final hasPhysical = _hasPhysicalProducts(cart);
    final hasDigital = _hasDigitalProducts(cart);
    final needsQrSelection = hasPhysical || hasDigital;

    if (_step == 0) {
      if (!_formKey.currentState!.validate()) return;

      // Digital-only checkout: user must choose QR first.
      if (!hasPhysical) {
        setState(() => _step = 1);
        return;
      }
    }

    if (_step == 1) {
      // Validate QR
      if (needsQrSelection && _selectedQr == null) {
        _showError('Pilih QR asset yang ingin ditampilkan.');
        return;
      }

      if (!hasPhysical) {
        setState(() => _step = 3);
        return;
      }

      // Validate address fields
      if (_addressCtrl.text.trim().isEmpty ||
          _provinceCtrl.text.trim().isEmpty ||
          _cityCtrl.text.trim().isEmpty ||
          _postalCtrl.text.trim().isEmpty) {
        _showError('Lengkapi semua field alamat pengiriman terlebih dahulu.');
        return;
      }
      // regency_id is required by API for shipping cost & checkout
      if (_regencyId == null || _regencyId == 0) {
        _showError('Pilih kota/kabupaten terlebih dahulu.');
        return;
      }
      // district_id: use regency_id as fallback if district not available
      _districtId ??= _regencyId;
      // trigger shipping calc
      _fetchShipping();
    }

    if (_step == 2) {
      if (_selectedService == null) {
        _showError('Pilih layanan pengiriman terlebih dahulu.');
        return;
      }
    }

    setState(() => _step = (_step + 1).clamp(0, _totalSteps - 1));
  }

  void _back() {
    final hasPhysical = _hasPhysicalProducts(context.read<CartProvider>());
    if (_step == 3 && !hasPhysical) {
      setState(() => _step = 1);
      return;
    }
    setState(() => _step = (_step - 1).clamp(0, _totalSteps - 1));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  //

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final hasPhysical = _hasPhysicalProducts(cart);

    return Scaffold(
      backgroundColor: SC.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(hasPhysical),
            _buildStepIndicator(hasPhysical),
            Expanded(
              child: _ctxLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: SC.red))
                  : _ctxError != null
                      ? _buildError()
                      : _buildStepBody(cart, hasPhysical),
            ),
            _buildBottomBar(cart, hasPhysical),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool hasPhysical) {
    const physicalStepLabels = [
      'Penerima',
      'Alamat',
      'Pengiriman',
      'Konfirmasi'
    ];
    const digitalStepLabels = ['Penerima', 'Pilih QR', 'Konfirmasi'];

    final displayStepIndex = hasPhysical
        ? _step
        : (_step == 0
            ? 0
            : _step == 1
                ? 1
                : 2);
    final stepLabel = hasPhysical
        ? physicalStepLabels[_step]
        : digitalStepLabels[displayStepIndex];

    return Container(
      color: SC.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _step == 0 ? context.pop() : _back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: SC.redLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: SC.red),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Checkout',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: SC.textPrimary)),
              Text('Langkah ${displayStepIndex + 1}: $stepLabel',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: SC.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(bool hasPhysical) {
    // Digital-only flow: step 0 (Penerima), step 1 (Pilih QR), step 3 (Konfirmasi)
    final activeSteps = hasPhysical ? 4 : 3;
    final currentIdx = hasPhysical
        ? _step
        : (_step == 0
            ? 0
            : _step == 1
                ? 1
                : 2);

    return Container(
      color: SC.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: List.generate(activeSteps * 2 - 1, (i) {
          if (i.isOdd) {
            final idx = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: idx < currentIdx ? SC.red : SC.redSoft,
              ),
            );
          }
          final idx = i ~/ 2;
          return _stepDot(idx + 1,
              done: idx < currentIdx, active: idx == currentIdx);
        }),
      ),
    );
  }

  Widget _stepDot(int num, {required bool done, required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done || active ? SC.red : SC.white,
        border: Border.all(
            color: done || active ? SC.red : SC.redSoft, width: 2),
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : Text('$num',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : SC.textSecondary)),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: SC.textSecondary),
            const SizedBox(height: 12),
            Text(_ctxError ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: SC.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadContext, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody(CartProvider cart, bool hasPhysical) {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1(hasPhysical: hasPhysical);
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3(cart, hasPhysical);
      default:
        return const SizedBox();
    }
  }

  //

  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Informasi Penerima', Icons.person_rounded),
            const SizedBox(height: 4),
            const Text('Data akan digunakan sebagai info kontak order.',
                style: TextStyle(fontSize: 12, color: SC.textSecondary)),
            const SizedBox(height: 16),
            _field(
                ctrl: _nameCtrl,
                label: 'Nama Lengkap',
                icon: Icons.person_outline,
                required: true),
            const SizedBox(height: 12),
            _field(
                ctrl: _emailCtrl,
                label: 'Email',
                icon: Icons.email_outlined,
                required: true,
                keyboardType: TextInputType.emailAddress,
                emailValidator: true),
            const SizedBox(height: 12),
            _field(
                ctrl: _phoneCtrl,
                label: 'Nomor HP',
                icon: Icons.phone_outlined,
                required: true,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  //

  Widget _buildStep1({required bool hasPhysical}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR selector
          _sectionTitle('Pilih QR Asset', Icons.qr_code_2_rounded),
          const SizedBox(height: 4),
          const Text(
            'Satu QR bisa dipakai banyak produk, tetapi QR harus dalam status subscription aktif.',
            style: TextStyle(fontSize: 12, color: SC.textSecondary),
          ),
          const SizedBox(height: 12),
          if (_qrAssets.isEmpty)
            _infoTile(Icons.warning_amber_rounded,
                'Tidak ada QR aktif. Pastikan kamu punya subscription aktif.',
                isWarning: true)
          else
            ..._qrAssets.map((asset) {
              final selected = _selectedQr?.id == asset.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedQr = asset),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected ? SC.redLight : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          selected ? SC.red : SC.redSoft,
                      width: selected ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected
                              ? SC.red
                              : SC.redLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.qr_code_rounded,
                            size: 20,
                            color: selected
                                ? Colors.white
                                : SC.red),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(asset.name,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? SC.red
                                        : SC.textPrimary)),
                            if (asset.expiresAt != null)
                              Text(
                                  'Aktif hingga: ${_formatDate(asset.expiresAt!)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: SC.textSecondary)),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle_rounded,
                            color: SC.red, size: 20),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 20),

          if (!hasPhysical) ...[
            _infoTile(
              Icons.info_outline,
              'QR terpilih akan ditempelkan ke produk digital yang kamu beli.',
            ),
            const SizedBox(height: 80),
          ] else ...[
            // Saved addresses
            _sectionTitle('Alamat Tersimpan', Icons.bookmark_rounded),
            const SizedBox(height: 4),
            const Text(
              'Pilih alamat tersimpan atau isi alamat manual dengan dropdown wilayah.',
              style: TextStyle(fontSize: 11, color: SC.textSecondary),
            ),
            const SizedBox(height: 10),
            if (_savedAddresses.isEmpty)
              _infoTile(
                Icons.warning_amber_rounded,
                'Belum ada alamat tersimpan. Kamu tetap bisa isi alamat manual di bawah.',
                isWarning: true,
              )
            else
              ..._savedAddresses.map((addr) {
                final active = _selectedSavedAddress?.id == addr.id;
                return GestureDetector(
                  onTap: () => _applySavedAddress(addr),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: active ? SC.redLight : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            active ? SC.red : SC.redSoft,
                        width: active ? 2 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.home_rounded,
                            color: active
                                ? SC.red
                                : SC.textSecondary,
                            size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(addr.label,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: active
                                          ? SC.red
                                          : SC.textPrimary)),
                              Text(addr.fullDisplay,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: SC.textSecondary)),
                            ],
                          ),
                        ),
                        if (active)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: SC.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Dipakai',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                );
              }),

            // Regency resolved indicator
            if (_regencyId != null && _regencyId != 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Color(0xFF43A047), size: 14),
                  const SizedBox(width: 6),
                  Text('Data wilayah tersedia (ID: $_regencyId)',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF2E7D32))),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Manual address fields
            _sectionTitle('Alamat Pengiriman', Icons.location_on_rounded),
            const SizedBox(height: 12),
            _field(
                ctrl: _addressCtrl,
                label: 'Alamat Lengkap',
                icon: Icons.location_on_outlined,
                required: true,
                maxLines: 2),
            const SizedBox(height: 12),
            _dropdownField<int>(
              label: 'Provinsi',
              icon: Icons.map_outlined,
              value: _selectedProvinceId,
              hint: _regionLoading ? 'Memuat provinsi...' : 'Pilih provinsi',
              items: _provinces
                  .map((p) => DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(p.name),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                _loadCities(value);
              },
            ),
            const SizedBox(height: 12),
            _dropdownField<int>(
              label: 'Kota / Kabupaten',
              icon: Icons.location_city_outlined,
              value: _selectedCityId,
              hint: _selectedProvinceId == null
                  ? 'Pilih provinsi dulu'
                  : _regionLoading
                      ? 'Memuat kota/kabupaten...'
                      : 'Pilih kota/kabupaten',
              items: _cities
                  .map((c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(
                          c.type != null && c.type!.trim().isNotEmpty
                              ? '${c.type} ${c.name}'
                              : c.name,
                        ),
                      ))
                  .toList(),
              onChanged: _selectedProvinceId == null
                  ? null
                  : (value) {
                      if (value == null) return;
                      final selected =
                          _cities.where((item) => item.id == value).first;
                      setState(() {
                        _selectedCityId = value;
                        _regencyId = value;
                        _cityCtrl.text = selected.name;
                        _selectedSavedAddress = null;
                        _districts = [];
                        _districtId = null;
                      });
                      _loadDistricts(value);
                    },
            ),
            const SizedBox(height: 12),
            _dropdownField<int>(
              label: 'Kecamatan',
              icon: Icons.apartment_outlined,
              value: _districtId,
              hint: _selectedCityId == null
                  ? 'Pilih kota/kabupaten dulu'
                  : _regionLoading
                      ? 'Memuat kecamatan...'
                      : (_districts.isEmpty
                          ? 'Tidak ada data kecamatan (otomatis pakai kota)'
                          : 'Pilih kecamatan'),
              items: _districts
                  .map((d) => DropdownMenuItem<int>(
                        value: d.id,
                        child: Text(d.name),
                      ))
                  .toList(),
              onChanged: _selectedCityId == null || _districts.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        _districtId = value;
                        _selectedSavedAddress = null;
                      });
                    },
            ),
            const SizedBox(height: 12),
            _field(
                ctrl: _postalCtrl,
                label: 'Kode Pos',
                icon: Icons.markunread_mailbox_outlined,
                required: true,
                keyboardType: TextInputType.number),
            if (_regionError != null) ...[
              const SizedBox(height: 10),
              _infoTile(Icons.warning_amber_rounded, _regionError!,
                  isWarning: true),
            ],
            const SizedBox(height: 80),
          ],
        ],
      ),
    );
  }

  Future<void> _applySavedAddress(_SavedAddress addr) async {
    setState(() {
      _selectedSavedAddress = addr;
      _addressCtrl.text = addr.address;
      _postalCtrl.text = addr.postalCode;
      _regencyId = addr.regencyId;
      _districtId = addr.districtId;
    });

    if (addr.provinceId != null &&
        _provinces.any((item) => item.id == addr.provinceId)) {
      await _loadCities(
        addr.provinceId!,
        selectedCityId: addr.regencyId > 0 ? addr.regencyId : null,
      );
      if (addr.regencyId > 0) {
        await _loadDistricts(
          addr.regencyId,
          selectedDistrictId: addr.districtId,
        );
      }
      if (!mounted) return;
      setState(() {
        _selectedProvinceId = addr.provinceId;
        _selectedCityId = addr.regencyId > 0 ? addr.regencyId : null;
        _districtId = addr.districtId;
      });
      return;
    }

    final matchedProvince = _provinces.where((item) {
      return item.name.trim().toLowerCase() ==
          addr.province.trim().toLowerCase();
    }).toList();

    if (matchedProvince.isNotEmpty) {
      final province = matchedProvince.first;
      await _loadCities(
        province.id,
        selectedCityId: addr.regencyId > 0 ? addr.regencyId : null,
      );
      if (addr.regencyId > 0) {
        await _loadDistricts(
          addr.regencyId,
          selectedDistrictId: addr.districtId,
        );
      }
      if (!mounted) return;
      setState(() {
        _selectedProvinceId = province.id;
        _selectedCityId = addr.regencyId > 0 ? addr.regencyId : null;
        _districtId = addr.districtId;
      });
    }
  }

  //

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Pilih Pengiriman', Icons.local_shipping_rounded),
          const SizedBox(height: 4),
          const Text('Pilih kurir dan layanan pengiriman ke alamatmu.',
              style: TextStyle(fontSize: 12, color: SC.textSecondary)),
          const SizedBox(height: 16),

          // Courier selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SC.redSoft),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car_outlined,
                    color: SC.red, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCourier,
                      isExpanded: true,
                      style: const TextStyle(
                          fontSize: 14,
                          color: SC.textPrimary,
                          fontWeight: FontWeight.w600),
                      items: _availableCouriers
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c.toUpperCase())))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedCourier = v;
                          _shippingServices = [];
                          _selectedService = null;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _shippingLoading ? null : _fetchShipping,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SC.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _shippingLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Cek Ongkir',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_shippingError != null)
            _infoTile(Icons.error_outline, _shippingError!, isWarning: true),

          if (_shippingLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: SC.red),
              ),
            )
          else if (_shippingServices.isEmpty && _shippingError == null)
            _infoTile(Icons.info_outline,
                'Pilih kurir lalu tekan "Cek Ongkir" untuk melihat layanan.')
          else
            ..._shippingServices.map((svc) {
              final selected = _selectedService?.service == svc.service;
              return GestureDetector(
                onTap: () => setState(() => _selectedService = svc),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected ? SC.redLight : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          selected ? SC.red : SC.redSoft,
                      width: selected ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_selectedCourier?.toUpperCase()}',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? SC.red
                                        : SC.textPrimary)),
                            Text(svc.description,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: SC.textSecondary)),
                            if (svc.etd != null && svc.etd!.isNotEmpty)
                              Text('Estimasi ${svc.etd} hari',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: SC.textSecondary)),
                          ],
                        ),
                      ),
                      Text(_fmt(svc.cost),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? SC.red
                                  : SC.textPrimary)),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  //

  Widget _buildStep3(CartProvider cart, bool hasPhysical) {
    final shippingCost = _selectedService?.cost ?? 0;
    final total = cart.total + shippingCost;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order items
          _sectionTitle('Ringkasan Pesanan', Icons.receipt_long_outlined),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: SC.redSoft.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Column(
              children: [
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.baseName,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                if (item.variantLabel != null)
                                  Text(item.variantLabel!,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: SC.textSecondary)),
                                const SizedBox(height: 4),
                                _typeBadge(item.type),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('x${item.quantity}',
                                  style: const TextStyle(
                                      color: SC.textSecondary,
                                      fontSize: 12)),
                              Text(_fmt(item.subtotal),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: SC.red)),
                            ],
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 14),
                Divider(color: SC.redSoft.withOpacity(0.5), height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _summaryRow('Subtotal produk', _fmt(cart.total)),
                      if (hasPhysical && shippingCost > 0) ...[
                        const SizedBox(height: 6),
                        _summaryRow(
                            'Ongkos kirim (${_selectedCourier?.toUpperCase()} ${_selectedService?.service ?? ''})',
                            _fmt(shippingCost)),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: SC.textPrimary)),
                          Text(_fmt(total),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: SC.red)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_selectedQr != null) ...[
            const SizedBox(height: 20),

            // QR info
            _sectionTitle(
                hasPhysical ? 'QR yang Ditampilkan' : 'QR untuk Produk Digital',
                Icons.qr_code_2_rounded),
            const SizedBox(height: 10),
            _reviewTile(
                Icons.qr_code_rounded,
                _selectedQr!.name,
                _selectedQr!.expiresAt != null
                    ? 'Aktif hingga ${_formatDate(_selectedQr!.expiresAt!)}'
                    : ''),

            if (hasPhysical) ...[
              const SizedBox(height: 20),

              // Shipping info
              _sectionTitle('Pengiriman', Icons.local_shipping_rounded),
              const SizedBox(height: 10),
              _reviewTile(Icons.location_on_rounded, _addressCtrl.text,
                  '${_cityCtrl.text}, ${_provinceCtrl.text} ${_postalCtrl.text}'),
              const SizedBox(height: 10),
              if (_selectedService != null)
                _reviewTile(
                    Icons.directions_car_outlined,
                    '${_selectedCourier?.toUpperCase()}',
                    '${_selectedService!.description} '),
            ],
          ],

          const SizedBox(height: 20),

          // Recipient info
          _sectionTitle('Penerima', Icons.person_rounded),
          const SizedBox(height: 10),
          _reviewTile(
              Icons.person_outline, _nameCtrl.text, '${_emailCtrl.text} '),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  //

  Widget _buildBottomBar(CartProvider cart, bool hasPhysical) {
    final shippingCost = _selectedService?.cost ?? 0;
    final total = cart.total + (_step >= 2 && hasPhysical ? shippingCost : 0);
    final isLastStep = _step == _totalSteps - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: SC.red.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style:
                      TextStyle(fontSize: 14, color: SC.textSecondary)),
              Text(_fmt(total),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: SC.red)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_step > 0) ...[
                OutlinedButton(
                  onPressed: _back,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: SC.red, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Kembali',
                      style: TextStyle(
                          color: SC.red,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _paying
                      ? null
                      : isLastStep
                          ? _pay
                          : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SC.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _paying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          isLastStep ? 'Bayar Sekarang' : 'Lanjut',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: SC.red, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: SC.textPrimary)),
      ],
    );
  }

  Widget _infoTile(IconData icon, String msg, {bool isWarning = false}) {
    final bg = isWarning ? const Color(0xFFFFF8E1) : SC.redLight;
    final border = isWarning ? const Color(0xFFFFD54F) : SC.redSoft;
    final color = isWarning ? const Color(0xFFE65100) : SC.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg, style: TextStyle(fontSize: 12, color: color))),
        ],
      ),
    );
  }

  Widget _reviewTile(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: SC.redSoft.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SC.redLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: SC.red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                if (sub.isNotEmpty)
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: SC.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: SC.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SC.textPrimary)),
      ],
    );
  }

  Widget _typeBadge(String type) {
    final isPhysical = _isPhysicalType(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPhysical ? SC.redLight : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPhysical ? Icons.local_shipping_outlined : Icons.bolt_rounded,
              size: 9,
              color:
                  isPhysical ? SC.red : const Color(0xFF2E7D32)),
          const SizedBox(width: 3),
          Text(isPhysical ? 'Fisik' : 'Digital',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isPhysical
                      ? SC.red
                      : const Color(0xFF2E7D32))),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool required = false,
    bool emailValidator = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return '$label wajib diisi';
        }
        if (emailValidator && v != null && v.trim().isNotEmpty) {
          final emailRx = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
          if (!emailRx.hasMatch(v.trim())) return 'Format email tidak valid';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: SC.red),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: SC.redSoft)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: SC.redSoft)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: SC.red, width: 2)),
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? hint,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: SC.red),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: SC.redSoft)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: SC.redSoft)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: SC.red, width: 2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: hint != null
              ? Text(
                  hint,
                  style: const TextStyle(
                      fontSize: 14, color: SC.textSecondary),
                )
              : null,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
