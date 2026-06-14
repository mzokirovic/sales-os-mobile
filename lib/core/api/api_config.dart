class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'SALES_OS_API_URL',
    defaultValue: 'http://localhost:3000',
  );
}
