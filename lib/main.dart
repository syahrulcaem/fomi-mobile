import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'providers/auth_provider.dart';
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
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';
import 'services/merchandise_service.dart';
import 'services/order_service.dart';
import 'services/notification_service.dart';
import 'services/profile_service.dart';
import 'services/qrcode_service.dart';
import 'services/renewal_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) {
    return;
  }
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Ignore duplicate/init failures in background isolate.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } catch (_) {
      // Firebase config may be unavailable on current platform.
    }
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
        Provider(create: (context) => AuthService(context.read<ApiClient>())),
        Provider(
          create: (context) => DashboardService(context.read<ApiClient>()),
        ),
        Provider(create: (context) => QrCodeService(context.read<ApiClient>())),
        Provider(create: (context) => OrderService(context.read<ApiClient>())),
        Provider(
            create: (context) => ProfileService(context.read<ApiClient>())),
        Provider(
            create: (context) => RenewalService(context.read<ApiClient>())),
        Provider(
          create: (context) => NotificationService(context.read<ApiClient>()),
        ),
        Provider(
          create: (context) => MerchandiseService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            context.read<AuthService>(),
            context.read<NotificationService>(),
          ),
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

        if (isLoading && path != '/splash') {
          return '/splash';
        }

        if (!isLoading && !isAuth && !isAuthPath) {
          return '/login';
        }

        if (!isLoading && isAuth && (isAuthPath || path == '/splash')) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const _SplashScreen(),
        ),
        GoRoute(
            path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/qrcodes',
          builder: (context, state) => const QrCodeListScreen(),
        ),
        GoRoute(
          path: '/qrcodes/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return QrCodeDetailScreen(assetId: id);
          },
        ),
        GoRoute(
          path: '/qrcodes/:id/edit',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return EditQrCodeScreen(assetId: id);
          },
        ),
        GoRoute(
            path: '/orders',
            builder: (context, state) => const OrderListScreen()),
        GoRoute(
          path: '/orders/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return OrderDetailScreen(orderId: id);
          },
        ),
        GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen()),
        GoRoute(
          path: '/renewal',
          builder: (context, state) => const RenewalScreen(),
        ),
        GoRoute(
          path: '/renewal/payment',
          builder: (context, state) {
            final snapUrl = state.uri.queryParameters['snapUrl'] ?? '';
            final orderId = state.uri.queryParameters['orderId'] ?? '';
            return MidtransPaymentScreen(snapUrl: snapUrl, orderId: orderId);
          },
        ),
        GoRoute(
          path: '/merchandise',
          builder: (context, state) => const MerchandiseScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'FOMI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor:
            const Color(0xFFF0F8FF), // Alice blue background
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange, // Orange accent for buttons
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            elevation: 4,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Colors.blue, width: 3),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      routerConfig: router,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
