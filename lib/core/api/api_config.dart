class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'SALES_OS_API_URL',
    defaultValue: 'https://sales-os-backend-0y70.onrender.com',
  );
}
