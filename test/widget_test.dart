import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/orders/order_status_policy.dart';

void main() {
  group('OrderStatusPolicy', () {
    test('fulfillment flow includes READY before SHIPPED', () {
      expect(OrderStatusPolicy.statusFlow, [
        'NEW',
        'CHECKED',
        'CONFIRMED',
        'PREPARING',
        'READY',
        'SHIPPED',
        'DELIVERED',
      ]);

      expect(OrderStatusPolicy.statusFlow.contains('PAID'), isFalse);
    });

    test('labels READY status', () {
      expect(OrderStatusPolicy.label('PREPARING'), 'Tayyorlanmoqda');
      expect(OrderStatusPolicy.label('READY'), 'Tayyor');
      expect(OrderStatusPolicy.actionLabel('READY'), 'Tayyor deb belgilash');
    });

    test('owner and manager can move order until READY only', () {
      for (final role in ['OWNER', 'MANAGER']) {
        expect(
          OrderStatusPolicy.nextStatusForRole(role: role, currentStatus: 'NEW'),
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
          'READY',
        );
        expect(
          OrderStatusPolicy.nextStatusForRole(
            role: role,
            currentStatus: 'READY',
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

    test('warehouse can prepare and mark ready only', () {
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
        'READY',
      );
      expect(
        OrderStatusPolicy.nextStatusForRole(
          role: 'WAREHOUSE',
          currentStatus: 'READY',
        ),
        isNull,
      );
    });

    test('delivery cannot change generic order status', () {
      for (final status in OrderStatusPolicy.statusFlow) {
        expect(
          OrderStatusPolicy.nextStatusForRole(
            role: 'DELIVERY',
            currentStatus: status,
          ),
          isNull,
        );
      }
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
  });
}
