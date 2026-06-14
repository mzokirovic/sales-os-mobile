import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_gate_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/customers/presentation/create_customer_screen.dart';
import '../../features/orders/create_order_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/orders_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGateScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrdersScreen(),
    ),
    GoRoute(
      path: '/orders/create',
      builder: (context, state) => const CreateOrderScreen(),
    ),
    GoRoute(
      path: '/customers/create',
      builder: (context, state) => const CreateCustomerScreen(),
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
