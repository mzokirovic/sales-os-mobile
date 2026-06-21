import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_gate_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/customers/presentation/create_customer_screen.dart';
import '../../features/customers/presentation/customer_detail_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/delivery/presentation/my_delivery_trips_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/orders/create_order_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/products/presentation/products_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGateScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomersScreen(),
    ),
    GoRoute(
      path: '/customers/create',
      builder: (context, state) {
        final next = state.uri.queryParameters['next'];

        return CreateCustomerScreen(next: next);
      },
    ),
    GoRoute(
      path: '/customers/:id',
      builder: (context, state) {
        final customerId = state.pathParameters['id']!;

        return CustomerDetailScreen(customerId: customerId);
      },
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductsScreen(),
    ),
    GoRoute(
      path: '/delivery/my-trips',
      builder: (context, state) => const MyDeliveryTripsScreen(),
    ),
    GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
    GoRoute(
      path: '/orders/create',
      builder: (context, state) {
        final customerId = state.uri.queryParameters['customerId'];

        return CreateOrderScreen(initialCustomerId: customerId);
      },
    ),
    GoRoute(
      path: '/orders/:id',
      builder: (context, state) {
        final orderId = state.pathParameters['id']!;

        return OrderDetailScreen(orderId: orderId);
      },
    ),
  ],
);
