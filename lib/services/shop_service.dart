import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/checkout_address_model.dart';
import '../models/checkout_context_model.dart';
import '../models/checkout_result_model.dart';
import '../models/checkout_unified_request_model.dart';
import '../models/digital_product_model.dart';
import '../models/shop_dashboard_model.dart';
import '../models/shop_product_model.dart';

class ShopService {
  ShopService(this._apiClient);

  final ApiClient _apiClient;

  Future<ShopDashboardModel> getShopDashboard() async {
    final response = await _apiClient.dio.get('/dashboard');
    return ShopDashboardModel.fromJson(
      response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }

  Future<List<ShopProduct>> getProducts({String? category}) async {
    final response = await _apiClient.dio.get(
      '/products',
      queryParameters: category != null && category.isNotEmpty
          ? {'category': category}
          : null,
    );
    final raw = response.data;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(ShopProduct.fromJson)
          .toList();
    }
    return [];
  }

  Future<ShopProduct> getProductDetail(String id) async {
    final response = await _apiClient.dio.get('/products/$id');
    return ShopProduct.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Fetch checkout context: customer info, active_qr_assets, saved_addresses,
  /// available_shipping_couriers, renewal_targets, midtrans config.
  Future<Map<String, dynamic>> getCheckoutContext() async {
    final response = await _apiClient.dio.get('/user/shop/checkout/context');
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  Future<CheckoutContextModel> getCheckoutContextModel() async {
    final raw = await getCheckoutContext();
    return CheckoutContextModel.fromJson(raw);
  }

  Future<List<CheckoutAddressModel>> getCheckoutAddresses() async {
    final response = await _apiClient.dio.get('/user/shop/checkout/addresses');
    final data = response.data;

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(CheckoutAddressModel.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final list = data['data'] is List
          ? data['data'] as List
          : data['addresses'] is List
              ? data['addresses'] as List
              : const <dynamic>[];

      return list
          .whereType<Map<String, dynamic>>()
          .map(CheckoutAddressModel.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList();
    }

    return const [];
  }

  Future<CheckoutAddressModel?> createCheckoutAddress(
    CheckoutAddressCreateRequest request,
  ) async {
    final response = await _apiClient.dio.post(
      '/user/shop/checkout/addresses',
      data: request.toJson(),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['address'] is Map<String, dynamic>
              ? data['address'] as Map<String, dynamic>
              : data;
      return CheckoutAddressModel.fromJson(payload);
    }

    return null;
  }

  Future<void> deleteCheckoutAddress(String addressId) async {
    await _apiClient.dio.delete('/user/shop/checkout/addresses/$addressId');
  }

  /// Calculate shipping cost via backend (RajaOngkir proxy).
  /// [regencyId] destination regency id, [courier] e.g. 'jne', 'j&t'.
  Future<dynamic> getShippingCosts({
    required int regencyId,
    required String courier,
    required int totalWeight,
  }) async {
    final response = await _apiClient.dio.post('/shipping/cost', data: {
      'destination': regencyId,
      'weight': totalWeight,
      'courier': courier,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> checkout(Map<String, dynamic> data) async {
    final response =
        await _apiClient.dio.post('/user/shop/checkout', data: data);
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  Future<CheckoutResultModel> checkoutUnified(
    CheckoutUnifiedRequest request,
  ) async {
    final payload = request.isBankTransfer
        ? request.toMultipartFormData()
        : request.toJson();

    final response = await _apiClient.dio.post(
      '/user/shop/checkout',
      data: payload,
      options: request.isBankTransfer
          ? Options(contentType: 'multipart/form-data')
          : null,
    );

    if (response.data is Map<String, dynamic>) {
      return CheckoutResultModel.fromJson(
          response.data as Map<String, dynamic>);
    }
    return CheckoutResultModel.fromJson(const {});
  }

  Future<UserDigitalProductsResponse> getUserDigitalProducts() async {
    final response = await _apiClient.dio.get('/user/digital-products');
    if (response.data is Map<String, dynamic>) {
      return UserDigitalProductsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return UserDigitalProductsResponse.fromJson(const {});
  }

  Future<Uint8List> getUserDigitalProductPreview({
    required String productId,
    String? assetId,
  }) async {
    return _getDigitalProductImageBytes(
      path: '/user/digital-products/$productId/preview',
      assetId: assetId,
    );
  }

  Future<Uint8List> getUserDigitalProductDownload({
    required String productId,
    String? assetId,
  }) async {
    return _getDigitalProductImageBytes(
      path: '/user/digital-products/$productId/download',
      assetId: assetId,
    );
  }

  Future<Uint8List> _getDigitalProductImageBytes({
    required String path,
    String? assetId,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      path,
      queryParameters: {
        if (assetId != null && assetId.trim().isNotEmpty) 'asset_id': assetId,
      },
      options: Options(responseType: ResponseType.bytes),
    );

    final body = response.data;
    if (body is Uint8List) {
      return body;
    }
    if (body is List<int>) {
      return Uint8List.fromList(body);
    }
    if (body is List) {
      return Uint8List.fromList(body.cast<int>());
    }

    return Uint8List(0);
  }

  Future<Map<String, dynamic>> checkMidtransStatus(String orderId) async {
    final response = await _apiClient.dio.post(
      '/midtrans/check-status',
      data: {'order_id': orderId},
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }
}
