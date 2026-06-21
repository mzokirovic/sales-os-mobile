class OrderStatusPolicy {
  const OrderStatusPolicy._();

  static const List<String> statusFlow = [
    'NEW',
    'CHECKED',
    'CONFIRMED',
    'PREPARING',
    'READY',
    'SHIPPED',
    'DELIVERED',
  ];

  static String label(String status) {
    return switch (status) {
      'NEW' => 'Yangi',
      'CHECKED' => 'Tekshirildi',
      'CONFIRMED' => 'Tasdiqlandi',
      'PREPARING' => 'Tayyorlanmoqda',
      'READY' => 'Tayyor',
      'SHIPPED' => 'Yo‘lda',
      'DELIVERED' => 'Yetkazildi',
      'PAID' => 'Yopildi',
      _ => status,
    };
  }

  static String actionLabel(String status) {
    return switch (status) {
      'CHECKED' => 'Tekshirish',
      'CONFIRMED' => 'Tasdiqlash',
      'PREPARING' => 'Tayyorlash',
      'READY' => 'Tayyor deb belgilash',
      'SHIPPED' => 'Yo‘lga chiqarish',
      'DELIVERED' => 'Yetkazildi',
      _ => label(status),
    };
  }

  static String? nextStatusForRole({
    required String? role,
    required String currentStatus,
  }) {
    if (currentStatus == 'PAID') return null;

    final nextStatus = _getNextFulfillmentStatus(currentStatus);

    if (nextStatus == null) return null;

    // Delivery movement is controlled only by the Delivery module:
    // READY -> SHIPPED happens when driver starts a trip.
    // SHIPPED -> DELIVERED happens when driver delivers a stop.
    if (nextStatus == 'SHIPPED' || nextStatus == 'DELIVERED') {
      return null;
    }

    if (role == 'OWNER' || role == 'MANAGER') {
      return nextStatus;
    }

    if (role == 'OPERATOR') {
      return nextStatus == 'CHECKED' || nextStatus == 'CONFIRMED'
          ? nextStatus
          : null;
    }

    if (role == 'WAREHOUSE') {
      return nextStatus == 'PREPARING' || nextStatus == 'READY'
          ? nextStatus
          : null;
    }

    return null;
  }

  static String? _getNextFulfillmentStatus(String currentStatus) {
    final index = statusFlow.indexOf(currentStatus);

    if (index < 0 || index >= statusFlow.length - 1) {
      return null;
    }

    return statusFlow[index + 1];
  }
}
