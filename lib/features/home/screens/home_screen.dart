import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/services/sync_service.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/auth/providers/auth_provider.dart';
import 'package:tarea_bimestre/features/carrito/providers/carrito_provider.dart';
import 'package:tarea_bimestre/features/pedidos/screens/mis_pedidos_screen.dart';
import 'package:tarea_bimestre/features/productos/providers/productos_provider.dart';
import 'package:tarea_bimestre/features/productos/screens/productos_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final sync = context.watch<SyncService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Pedidos'),
        actions: [
          // ── Botón sincronizar ─────────────────────────────────────────────
          IconButton(
            icon: sync.isSyncing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.sync),
            tooltip: 'Sincronizar productos',
            onPressed: sync.isSyncing ? null : () => _sincronizar(context),
          ),
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
            // ── Banner de estado de sync ──────────────────────────────────
            if (sync.status == SyncStatus.success || sync.status == SyncStatus.error)
              _SyncBanner(sync: sync),

            // ── Tarjeta de bienvenida ─────────────────────────────────────
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
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.roles.join(', ') ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'Módulos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),

            _ModuleCard(
              icon:     Icons.add_shopping_cart,
              title:    'Nuevo pedido',
              subtitle: 'Seleccionar productos y registrar pedido',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductosScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              icon:     Icons.list_alt,
              title:    'Mis pedidos',
              subtitle: 'Ver y sincronizar pedidos guardados',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MisPedidosScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sincronizar(BuildContext context) async {
    final sync     = context.read<SyncService>();
    final productos = context.read<ProductosProvider>();

    final ok = await sync.sincronizarProductos();
    if (ok) {
      await productos.recargar();
    }
  }
}

// ── Banner de resultado de sync ───────────────────────────────────────────────
class _SyncBanner extends StatelessWidget {
  final SyncService sync;
  const _SyncBanner({required this.sync});

  @override
  Widget build(BuildContext context) {
    final isOk = sync.status == SyncStatus.success;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOk ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOk ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle_outline : Icons.error_outline,
            color: isOk ? Colors.green : AppTheme.errorColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sync.message,
              style: TextStyle(
                fontSize: 13,
                color: isOk ? Colors.green.shade800 : AppTheme.errorColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: sync.resetStatus,
            child: Icon(Icons.close,
                size: 16,
                color: isOk ? Colors.green : AppTheme.errorColor),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de módulo ─────────────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
        child: Row(
          children: [
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
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppTheme.textMedium)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textLight),
          ],
        ),
      ),
    ),
  );
}