class OrderStatusPolicy {
  const OrderStatusPolicy._();

  static const labels = <String, String>{
    'NEW': 'Yangi',
    'CHECKED': 'Tekshirildi',
    'CONFIRMED': 'Tasdiqlandi',
    'PREPARING': 'Tayyorlanmoqda',
    'SHIPPED': 'Yo‘lda',
    'DELIVERED': 'Yetkazildi',
    'PAID': 'Yopildi',
  };

  static const actionLabels = <String, String>{
    'CHECKED': 'Tekshirish',
    'CONFIRMED': 'Tasdiqlash',
    'PREPARING': 'Skladga berish',
    'SHIPPED': 'Yo‘lga chiqarish',
    'DELIVERED': 'Yetkazildi',
    'PAID': 'Yopish',
  };

  static String label(String status) {
    return labels[status] ?? status;
  }

  static String actionLabel(String nextStatus) {
    return actionLabels[nextStatus] ?? 'Statusni o‘zgartirish';
  }

  static String? nextStatusForRole({
    required String role,
    required String currentStatus,
  }) {
    if (currentStatus == 'PAID') return null;

    if (role == 'OWNER' || role == 'MANAGER') {
      return _nextStatus(currentStatus);
    }

    if (role == 'OPERATOR') {
      return switch (currentStatus) {
        'NEW' => 'CHECKED',
        'CHECKED' => 'CONFIRMED',
        _ => null,
      };
    }

    if (role == 'WAREHOUSE') {
      return switch (currentStatus) {
        'CONFIRMED' => 'PREPARING',
        'PREPARING' => 'SHIPPED',
        _ => null,
      };
    }

    if (role == 'DELIVERY') {
      return switch (currentStatus) {
        'SHIPPED' => 'DELIVERED',
        _ => null,
      };
    }

    return null;
  }

  static String? _nextStatus(String currentStatus) {
    return switch (currentStatus) {
      'NEW' => 'CHECKED',
      'CHECKED' => 'CONFIRMED',
      'CONFIRMED' => 'PREPARING',
      'PREPARING' => 'SHIPPED',
      'SHIPPED' => 'DELIVERED',
      'DELIVERED' => 'PAID',
      _ => null,
    };
  }
}
