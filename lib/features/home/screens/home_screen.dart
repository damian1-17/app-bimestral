import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/auth/providers/auth_provider.dart';
import 'package:tarea_bimestre/features/carrito/providers/carrito_provider.dart';
import 'package:tarea_bimestre/features/pedidos/providers/pedidos_list_provider.dart';
import 'package:tarea_bimestre/features/pedidos/screens/mis_pedidos_screen.dart';
import 'package:tarea_bimestre/features/productos/screens/productos_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              context.read<CarritoProvider>().limpiar();
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tarjeta bienvenida ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Bienvenido,\n${user?.nombre ?? "Usuario"}!',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w700, height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(user?.email ?? '',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75), fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(user?.roles.join(', ') ?? '',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text('Módulos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
            const SizedBox(height: 16),

            // ── Nuevo pedido ────────────────────────────────────────────────
            _ModuleCard(
              icon: Icons.add_shopping_cart,
              title: 'Nuevo pedido',
              subtitle: 'Seleccionar productos y registrar pedido',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductosScreen()),
              ),
            ),
            const SizedBox(height: 12),

            // ── Mis pedidos ─────────────────────────────────────────────────
            Consumer<PedidosListProvider>(
              builder: (_, prov, __) {
                // Cargar al mostrar si está vacío
                if (prov.pedidos.isEmpty && !prov.isLoading) {
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => prov.cargarPedidos());
                }
                return _ModuleCard(
                  icon: Icons.list_alt,
                  title: 'Mis pedidos',
                  subtitle: 'Ver historial y sincronizar con el servidor',
                  badge: prov.totalPendientes > 0
                      ? '${prov.totalPendientes} pendiente${prov.totalPendientes > 1 ? "s" : ""}'
                      : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MisPedidosScreen()),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData     icon;
  final String       title;
  final String       subtitle;
  final String?      badge;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600,
                        fontSize: 15, color: AppTheme.textDark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12.5,
                        color: AppTheme.textMedium)),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9C4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Text(badge!,
                        style: const TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E0B))),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textLight),
        ]),
      ),
    ),
  );
}