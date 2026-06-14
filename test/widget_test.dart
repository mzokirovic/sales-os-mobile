import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/orders/order_permission_policy.dart';
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

    test('warehouse can only prepare and ship orders', () {
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
          role: 'WAREHOUSE',
          currentStatus: 'SHIPPED',
        ),
        isNull,
      );
    });

    test('delivery can only mark shipped orders as delivered', () {
      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'DELIVERY',
          currentStatus: 'SHIPPED',
        ),
        'DELIVERED',
      );

      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'DELIVERY',
          currentStatus: 'DELIVERED',
        ),
        isNull,
      );
    });

    test('sales cannot change status', () {
      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'SALES',
          currentStatus: 'NEW',
        ),
        isNull,
      );
    });

    test('paid orders have no next action', () {
      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'OWNER',
          currentStatus: 'PAID',
        ),
        isNull,
      );
    });
  });

  group('OrderPermissionPolicy', () {
    test('owner manager sales and operator can create orders', () {
      expect(OrderPermissionPolicy.canCreateOrder('OWNER'), isTrue);
      expect(OrderPermissionPolicy.canCreateOrder('MANAGER'), isTrue);
      expect(OrderPermissionPolicy.canCreateOrder('SALES'), isTrue);
      expect(OrderPermissionPolicy.canCreateOrder('OPERATOR'), isTrue);
    });

    test('warehouse and delivery cannot create orders', () {
      expect(OrderPermissionPolicy.canCreateOrder('WAREHOUSE'), isFalse);
      expect(OrderPermissionPolicy.canCreateOrder('DELIVERY'), isFalse);
    });
  });
}
