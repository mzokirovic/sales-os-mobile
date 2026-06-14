import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/orders/order_status_policy.dart';

void main() {
  group('OrderStatusPolicy', () {
    test('owner and manager can move through the full flow', () {
      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'OWNER',
          currentStatus: 'NEW',
        ),
        'CHECKED',
      );

      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'MANAGER',
          currentStatus: 'DELIVERED',
        ),
        'PAID',
      );
    });

    test('operator can only check and confirm orders', () {
      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'OPERATOR',
          currentStatus: 'NEW',
        ),
        'CHECKED',
      );

      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'OPERATOR',
          currentStatus: 'CHECKED',
        ),
        'CONFIRMED',
      );

      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'OPERATOR',
          currentStatus: 'CONFIRMED',
        ),
        isNull,
      );
    });

    test('warehouse and delivery have limited actions', () {
      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'WAREHOUSE',
          currentStatus: 'CONFIRMED',
        ),
        'PREPARING',
      );

      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'WAREHOUSE',
          currentStatus: 'PREPARING',
        ),
        'SHIPPED',
      );

      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'DELIVERY',
          currentStatus: 'SHIPPED',
        ),
        'DELIVERED',
      );
    });

    test('sales cannot change order status', () {
      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'SALES',
          currentStatus: 'NEW',
        ),
        isNull,
      );
    });

    test('paid orders do not have next action', () {
      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'OWNER',
          currentStatus: 'PAID',
        ),
        isNull,
      );
    });
  });
}
