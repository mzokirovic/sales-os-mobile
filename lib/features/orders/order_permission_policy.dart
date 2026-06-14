class OrderPermissionPolicy {
  const OrderPermissionPolicy._();

  static bool canCreateOrder(String role) {
    return switch (role) {
      'OWNER' || 'MANAGER' || 'SALES' || 'OPERATOR' => true,
      _ => false,
    };
  }
}
