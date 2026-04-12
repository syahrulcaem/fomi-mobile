class CheckoutResultModel {
  CheckoutResultModel({
    this.snapUrl,
    this.snapToken,
    this.orderId,
    this.orderNumber,
    this.message,
    this.manualPayment = false,
    this.status,
    this.transactionStatus,
    this.checkStatusUrl,
    this.raw,
  });

  final String? snapUrl;
  final String? snapToken;
  final String? orderId;
  final String? orderNumber;
  final String? message;
  final bool manualPayment;
  final String? status;
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

    final orderMap = data['order'] is Map<String, dynamic>
        ? data['order'] as Map<String, dynamic>
        : null;

    final rawOrderPayment = orderMap != null ? orderMap['payment'] : null;
    final orderStatusRaw = orderMap != null ? orderMap['status'] : null;
    final orderIdRaw = orderMap != null ? orderMap['id'] : null;
    final orderNumberRaw = orderMap != null ? orderMap['order_number'] : null;

    final orderPaymentMap =
        rawOrderPayment is Map<String, dynamic> ? rawOrderPayment : null;

    final status = data['status']?.toString() ?? orderStatusRaw?.toString();
    final transactionStatus = data['transaction_status']?.toString() ??
        data['transactionStatus']?.toString() ??
        orderPaymentMap?['transaction_status']?.toString() ??
        status;

    return CheckoutResultModel(
      snapUrl: data['snap_url']?.toString() ??
          orderPaymentMap?['snap_url']?.toString() ??
          data['payment_url']?.toString() ??
          data['redirect_url']?.toString() ??
          orderPaymentMap?['redirect_url']?.toString(),
      snapToken: data['snap_token']?.toString() ??
          orderPaymentMap?['snap_token']?.toString() ??
          data['token']?.toString(),
      orderId: data['order_id']?.toString() ??
          orderIdRaw?.toString() ??
          orderPaymentMap?['midtrans_order_id']?.toString() ??
          data['transaction_id']?.toString(),
      orderNumber:
          data['order_number']?.toString() ?? orderNumberRaw?.toString(),
      message: data['message']?.toString() ?? json['message']?.toString(),
      manualPayment: data['manual_payment'] == true ||
          json['manual_payment'] == true ||
          data['payment_method']?.toString() == 'bank_transfer',
      status: status,
      transactionStatus: transactionStatus,
      checkStatusUrl: data['check_status_url']?.toString() ??
          orderPaymentMap?['check_status_url']?.toString(),
      raw: data,
    );
  }
}
