import '../../core/api/api_client.dart';
import 'customer_model.dart';

class CustomersRepository {
  CustomersRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CustomerModel>> listCustomers() async {
    final result = await _apiClient.get('/customers');

    if (result is! List<dynamic>) {
      throw const CustomersException('Mijozlar noto‘g‘ri formatda keldi');
    }

    return result
        .map((item) => CustomerModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerModel> getCustomer(String customerId) async {
    final result = await _apiClient.get('/customers/$customerId');

    if (result is! Map<String, dynamic>) {
      throw const CustomersException('Mijoz detail noto‘g‘ri formatda keldi');
    }

    return CustomerModel.fromJson(result);
  }

  Future<CustomerModel> createCustomer({
    required String name,
    String? phone,
    String? address,
    String? note,
  }) async {
    final result = await _apiClient.post(
      '/customers',
      body: {
        'name': name,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );

    if (result is! Map<String, dynamic>) {
      throw const CustomersException('Mijoz yaratish javobi noto‘g‘ri formatda keldi');
    }

    return CustomerModel.fromJson(result);
  }
}

class CustomersException implements Exception {
  const CustomersException(this.message);

  final String message;

  @override
  String toString() => message;
}
