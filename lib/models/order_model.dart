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
    return OrderItemModel(
      name: json['name']?.toString() ?? '-',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
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
  });

  final String id;
  final String orderNumber;
  final String status;
  final int totalAmount;
  final String? createdAt;
  final List<OrderItemModel> items;
  final String? paymentMethod;

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

    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'unknown',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(OrderItemModel.fromJson)
          .toList(),
    );
  }
}
