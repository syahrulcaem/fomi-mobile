import 'package:flutter_test/flutter_test.dart';

import 'package:fomi/services/order_service.dart';

void main() {
  group('OrderService.extractPaginatedOrders', () {
    test('parses paginated payload from api envelope', () {
      final raw = {
        'data': {
          'data': [
            {
              'id': 10,
              'order_number': 'INV-001',
              'status': 'pending',
              'total_amount': 25000,
            },
          ],
          'current_page': 2,
          'last_page': 4,
          'per_page': 10,
          'total': 32,
        },
      };

      final result = OrderService.extractPaginatedOrders(raw);

      expect(result.items.length, 1);
      expect(result.items.first.orderNumber, 'INV-001');
      expect(result.currentPage, 2);
      expect(result.lastPage, 4);
      expect(result.total, 32);
    });
  });
}
