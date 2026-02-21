import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/services/sync_service.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/auth/providers/auth_provider.dart';
import 'package:tarea_bimestre/features/auth/screens/login_screen.dart';
import 'package:tarea_bimestre/features/carrito/providers/carrito_provider.dart';
import 'package:tarea_bimestre/features/home/screens/home_screen.dart';
import 'package:tarea_bimestre/features/pedidos/providers/pedidos_list_provider.dart';
import 'package:tarea_bimestre/features/productos/providers/productos_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductosProvider()),
        ChangeNotifierProvider(create: (_) => CarritoProvider()),
        ChangeNotifierProvider(create: (_) => SyncService()),
        ChangeNotifierProvider(create: (_) => PedidosListProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Pedidos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home':  (_) => const HomeScreen(),
      },
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    if (status == AuthStatus.authenticated) {
      return const HomeScreen();
    } else if (status == AuthStatus.unauthenticated) {
      return const LoginScreen();
    } else {
      return const _SplashScreen();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.primary,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Registro de Pedidos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ],
      ),
    ),
  );
}