class OrderStatusPolicy {
  const OrderStatusPolicy._();

  static const List<String> statusFlow = [
    'NEW',
    'CHECKED',
    'CONFIRMED',
    'PREPARING',
    'SHIPPED',
    'DELIVERED',
  ];

  static String label(String status) {
    return switch (status) {
      'NEW' => 'Yangi',
      'CHECKED' => 'Tekshirildi',
      'CONFIRMED' => 'Tasdiqlandi',
      'PREPARING' => 'Tayyorlanmoqda',
      'SHIPPED' => 'Yo‘lda',
      'DELIVERED' => 'Yetkazildi',
      'PAID' => 'To‘langan',
      _ => status,
    };
  }

  static String actionLabel(String status) {
    return switch (status) {
      'CHECKED' => 'Tekshirish',
      'CONFIRMED' => 'Tasdiqlash',
      'PREPARING' => 'Tayyorlash',
      'SHIPPED' => 'Yo‘lga chiqarish',
      'DELIVERED' => 'Yetkazildi',
      _ => 'Statusni yangilash',
    };
  }

  static String? nextStatusForRole({
    required String role,
    required String currentStatus,
  }) {
    if (currentStatus == 'PAID') return null;

    final nextStatus = _nextStatus(currentStatus);

    if (nextStatus == null) return null;

    if (role == 'OWNER' || role == 'MANAGER') {
      return nextStatus;
    }

    final allowedByRole = <String, List<String>>{
      'OPERATOR': ['CHECKED', 'CONFIRMED'],
      'WAREHOUSE': ['PREPARING', 'SHIPPED'],
      'DELIVERY': ['DELIVERED'],
    };

    final allowedStatuses = allowedByRole[role] ?? [];

    if (!allowedStatuses.contains(nextStatus)) {
      return null;
    }

    return nextStatus;
  }

  static String? _nextStatus(String currentStatus) {
    final index = statusFlow.indexOf(currentStatus);

    if (index < 0 || index >= statusFlow.length - 1) {
      return null;
    }

    return statusFlow[index + 1];
  }
}
