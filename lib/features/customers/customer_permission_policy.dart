class CustomerPermissionPolicy {
  const CustomerPermissionPolicy._();

  static bool canCreateCustomer(String role) {
    return switch (role) {
      'OWNER' || 'MANAGER' || 'SALES' => true,
      _ => false,
    };
  }
}
