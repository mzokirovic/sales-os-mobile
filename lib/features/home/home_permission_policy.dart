class HomePermissionPolicy {
  const HomePermissionPolicy._();

  static bool canSeeOrders(String role) {
    return switch (role) {
      'OWNER' || 'MANAGER' || 'SALES' || 'OPERATOR' || 'WAREHOUSE' => true,
      _ => false,
    };
  }

  static bool canSeeDeliveryTrips(String role) {
    return role == 'DELIVERY';
  }

  static bool canSeeCustomers(String role) {
    return switch (role) {
      'OWNER' || 'MANAGER' || 'SALES' || 'OPERATOR' => true,
      _ => false,
    };
  }

  static bool canSeeProducts(String role) {
    return switch (role) {
      'OWNER' || 'MANAGER' || 'SALES' || 'OPERATOR' || 'WAREHOUSE' => true,
      _ => false,
    };
  }
}
