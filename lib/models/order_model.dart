import 'package:flutter/material.dart';

class OrderItemModel {
  OrderItemModel({
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String name;
  final int quantity;
  final int price;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    String extractName() {
      if (json['name'] != null && json['name'].toString().trim().isNotEmpty && json['name'] != '-') {
        return json['name'].toString();
      }
      if (json['product_name'] != null) return json['product_name'].toString();
      if (json['product'] is Map && json['product']['name'] != null) {
        return json['product']['name'].toString();
      }
      if (json['subscription_package'] is Map && json['subscription_package']['name'] != null) {
        return json['subscription_package']['name'].toString();
      }
      if (json['package'] is Map && json['package']['name'] != null) {
        return json['package']['name'].toString();
      }
      return '-';
    }

    return OrderItemModel(
      name: extractName(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toInt() ?? 0,
    );
  }
}

class OrderModel {
  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    this.createdAt,
    this.items = const [],
    this.paymentMethod,
    this.snapUrl,
  });

  final String id;
  final String orderNumber;
  final String status;
  final int totalAmount;
  final String? createdAt;
  final List<OrderItemModel> items;
  final String? paymentMethod;
  final String? snapUrl;

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.teal;
      case 'processing':
        return Colors.indigo;
      case 'shipped':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems =
        json['items'] is List ? json['items'] as List : <dynamic>[];
        
    final payment = json['payment'] is Map ? json['payment'] : null;
    final snap = payment?['snap_url']?.toString() ?? json['snap_url']?.toString();

    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'unknown',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      snapUrl: snap,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(OrderItemModel.fromJson)
          .toList(),
    );
  }
}
