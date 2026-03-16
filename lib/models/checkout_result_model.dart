class CheckoutResultModel {
  CheckoutResultModel({
    this.snapUrl,
    this.snapToken,
    this.orderId,
    this.transactionStatus,
    this.checkStatusUrl,
    this.raw,
  });

  final String? snapUrl;
  final String? snapToken;
  final String? orderId;
  final String? transactionStatus;
  final String? checkStatusUrl;
  final Map<String, dynamic>? raw;

  String? get resolvedSnapUrl {
    final direct = snapUrl;
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final token = snapToken;
    if (token != null && token.isNotEmpty) {
      // Midtrans VTWeb URL from snap token (default to sandbox).
      return 'https://app.sandbox.midtrans.com/snap/v2/vtweb/$token';
    }

    return null;
  }

  factory CheckoutResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return CheckoutResultModel(
      snapUrl: data['snap_url']?.toString() ??
          data['payment_url']?.toString() ??
          data['redirect_url']?.toString(),
      snapToken: data['snap_token']?.toString() ?? data['token']?.toString(),
      orderId:
          data['order_id']?.toString() ?? data['transaction_id']?.toString(),
      transactionStatus: data['transaction_status']?.toString(),
      checkStatusUrl: data['check_status_url']?.toString(),
      raw: data,
    );
  }
}
