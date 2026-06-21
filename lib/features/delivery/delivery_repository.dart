import '../../core/api/api_client.dart';
import 'delivery_models.dart';

class DeliveryRepository {
  DeliveryRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<DeliveryTrip>> listMyTrips() async {
    final data = await _apiClient.get('/delivery/trips/my');

    if (data is! List<dynamic>) {
      throw const DeliveryException('Reyslar formati noto‘g‘ri');
    }

    return data
        .map((item) => DeliveryTrip.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DeliveryTrip> startTrip(String tripId) async {
    final data = await _apiClient.post(
      '/delivery/trips/$tripId/start',
      body: const {},
    );

    return DeliveryTrip.fromJson(data as Map<String, dynamic>);
  }

  Future<DeliveryTrip> deliverStop(String stopId) async {
    final data = await _apiClient.post(
      '/delivery/stops/$stopId/deliver',
      body: const {},
    );

    return DeliveryTrip.fromJson(data as Map<String, dynamic>);
  }
}

class DeliveryException implements Exception {
  const DeliveryException(this.message);

  final String message;

  @override
  String toString() => message;
}
