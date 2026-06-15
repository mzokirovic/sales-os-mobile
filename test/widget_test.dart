import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/customers/customer_permission_policy.dart';
import 'package:mobile/features/orders/order_permission_policy.dart';
import 'package:mobile/features/orders/order_status_policy.dart';

void main() {
  group('OrderStatusPolicy', () {
    test('owner and manager can move through fulfillment flow only', () {
      for (final role in ['OWNER', 'MANAGER']) {
        expect(
          OrderStatusPolicy.nextStatusForRole(
            role: role,
            currentStatus: 'NEW',
          ),
          'CHECKED',
        );

        expect(
          OrderStatusPolicy.nextStatusForRole(
            role: role,
            currentStatus: 'CHECKED',
          ),
          'CONFIRMED',
        );

        expect(
          OrderStatusPolicy.nextStatusForRole(
            role: role,
            currentStatus: 'CONFIRMED',
          ),
          'PREPARING',
        );

        expect(
          OrderStatusPolicy.nextStatusForRole(
            role: role,
            currentStatus: 'PREPARING',
          ),
          'SHIPPED',
        );

        expect(
          OrderStatusPolicy.nextStatusForRole(
            role: role,
            currentStatus: 'SHIPPED',
          ),
          'DELIVERED',
        );

        expect(
          OrderStatusPolicy.nextStatusForRole(
            role: role,
            currentStatus: 'DELIVERED',
          ),
          isNull,
        );
      }
    });

    test('operator can check and confirm only', () {
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

    test('warehouse can prepare and ship only', () {
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

    test('delivery can deliver only', () {
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

    test('sales cannot move order status', () {
      for (final status in OrderStatusPolicy.statusFlow) {
        expect(
          OrderStatusPolicy.nextStatusForRole(
            role: 'SALES',
            currentStatus: status,
          ),
          isNull,
        );
      }
    });

    test('paid is not a fulfillment status anymore', () {
      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'OWNER',
          currentStatus: 'PAID',
        ),
        isNull,
      );

      expect(OrderStatusPolicy.statusFlow.contains('PAID'), isFalse);
    });
  });

  group('OrderPermissionPolicy', () {
    test('allowed roles can create order', () {
      for (final role in ['OWNER', 'MANAGER', 'SALES', 'OPERATOR']) {
        expect(OrderPermissionPolicy.canCreateOrder(role), isTrue);
      }
    });

    test('warehouse and delivery cannot create order', () {
      for (final role in ['WAREHOUSE', 'DELIVERY']) {
        expect(OrderPermissionPolicy.canCreateOrder(role), isFalse);
      }
    });
  });

  group('CustomerPermissionPolicy', () {
    test('allowed roles can create customer', () {
      for (final role in ['OWNER', 'MANAGER', 'SALES']) {
        expect(CustomerPermissionPolicy.canCreateCustomer(role), isTrue);
      }
    });

    test('operator warehouse delivery cannot create customer', () {
      for (final role in ['OPERATOR', 'WAREHOUSE', 'DELIVERY']) {
        expect(CustomerPermissionPolicy.canCreateCustomer(role), isFalse);
      }
    });
  });
}
