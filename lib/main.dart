import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/merchandise/merchandise_screen.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/orders/order_list_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/qr/edit_qrcode_screen.dart';
import 'screens/qr/qrcode_detail_screen.dart';
import 'screens/qr/qrcode_list_screen.dart';
import 'screens/renewal/midtrans_payment_screen.dart';
import 'screens/renewal/renewal_screen.dart';
import 'screens/shop/shop_home_screen.dart';
import 'screens/shop/product_list_screen.dart';
import 'screens/shop/product_detail_screen.dart';
import 'screens/shop/cart_screen.dart';
import 'screens/shop/checkout_screen.dart';
import 'screens/shop/subscription_screen.dart';
import 'screens/shop/order_success_screen.dart';
import 'screens/shop/shop_payment_screen.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/dashboard_service.dart';
import 'services/merchandise_service.dart';
import 'services/notification_service.dart';
import 'services/order_service.dart';
import 'services/profile_service.dart';
import 'services/qrcode_service.dart';
import 'services/renewal_service.dart';
import 'services/shop_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (_) {}
  }
  runApp(const FomiApp());
}

class FomiApp extends StatelessWidget {
  const FomiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiClient()),
        Provider(create: (ctx) => AuthService(ctx.read<ApiClient>())),
        Provider(create: (ctx) => DashboardService(ctx.read<ApiClient>())),
        Provider(create: (ctx) => QrCodeService(ctx.read<ApiClient>())),
        Provider(create: (ctx) => OrderService(ctx.read<ApiClient>())),
        Provider(create: (ctx) => ProfileService(ctx.read<ApiClient>())),
        Provider(create: (ctx) => RenewalService(ctx.read<ApiClient>())),
        Provider(create: (ctx) => NotificationService(ctx.read<ApiClient>())),
        Provider(create: (ctx) => MerchandiseService(ctx.read<ApiClient>())),
        Provider(create: (ctx) => ShopService(ctx.read<ApiClient>())),
        Provider(create: (_) => CartService()),
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(ctx.read<AuthService>(), ctx.read<NotificationService>()),
        ),
        ChangeNotifierProxyProvider<CartService, CartProvider>(
          create: (ctx) => CartProvider(ctx.read<CartService>()),
          update: (ctx, cartSvc, prev) => prev ?? CartProvider(cartSvc),
        ),
      ],
      child: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuth = authProvider.isAuthenticated;
        final isLoading = authProvider.status == AuthStatus.loading;
        final path = state.matchedLocation;
        final isAuthPath = path == '/login' || path == '/register';

        if (isLoading && path != '/splash') return '/splash';
        if (!isLoading && !isAuth && !isAuthPath) {
          // Shop routes that don't require auth
          if (path.startsWith('/shop') || path == '/cart' || path == '/shop/subscription') {
            return null;
          }
          return '/login';
        }
        if (!isLoading && isAuth && (isAuthPath || path == '/splash')) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const _SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        // Dashboard (main home)
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
        // Shop
        GoRoute(path: '/shop', builder: (_, __) => const ShopHomeScreen()),
        GoRoute(
          path: '/shop/products',
          builder: (_, state) {
            final cat = state.uri.queryParameters['category'];
            return ProductListScreen(initialCategory: cat);
          },
        ),
        GoRoute(
          path: '/shop/products/:id',
          builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
        GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
        GoRoute(path: '/shop/subscription', builder: (_, __) => const SubscriptionScreen()),
        GoRoute(
          path: '/shop/success',
          builder: (_, state) => OrderSuccessScreen(orderNumber: state.uri.queryParameters['orderNumber']),
        ),
        GoRoute(
          path: '/shop/payment',
          builder: (_, state) => ShopPaymentScreen(
            snapUrl: state.uri.queryParameters['snapUrl'] ?? '',
            orderId: state.uri.queryParameters['orderId'] ?? '',
          ),
        ),
        // QR Codes
        GoRoute(path: '/qrcodes', builder: (_, __) => const QrCodeListScreen()),
        GoRoute(
          path: '/qrcodes/:id',
          builder: (_, state) => QrCodeDetailScreen(assetId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '/qrcodes/:id/edit',
          builder: (_, state) => EditQrCodeScreen(assetId: state.pathParameters['id'] ?? ''),
        ),
        // Orders
        GoRoute(path: '/orders', builder: (_, __) => const OrderListScreen()),
        GoRoute(
          path: '/orders/:id',
          builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id'] ?? ''),
        ),
        // Profile
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        // Renewal (existing)
        GoRoute(path: '/renewal', builder: (_, __) => const RenewalScreen()),
        GoRoute(
          path: '/renewal/payment',
          builder: (_, state) => MidtransPaymentScreen(
            snapUrl: state.uri.queryParameters['snapUrl'] ?? '',
            orderId: state.uri.queryParameters['orderId'] ?? '',
          ),
        ),
        GoRoute(path: '/merchandise', builder: (_, __) => const MerchandiseScreen()),
      ],
    );

    return MaterialApp.router(
      title: 'FOMI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.heroGradient),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF3B82F6)),
              SizedBox(height: 16),
              Text('FOMI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E3A5F))),
            ],
          ),
        ),
      ),
    );
  }
}
