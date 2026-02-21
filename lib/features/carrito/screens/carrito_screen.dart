import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/carrito/providers/carrito_provider.dart';
import 'package:tarea_bimestre/features/carrito/widgets/carrito_item_card.dart';

class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          Consumer<CarritoProvider>(
            builder: (_, carrito, __) {
              if (carrito.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _confirmarLimpiar(context, carrito),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.white, size: 18),
                label: const Text('Vaciar',
                    style: TextStyle(color: Colors.white)),
              );
            },
          ),
        ],
      ),
      body: Consumer<CarritoProvider>(
        builder: (_, carrito, __) {
          // ── Carrito vacío ─────────────────────────────────────────────────
          if (carrito.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 72, color: AppTheme.textLight),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu carrito está vacío',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Agrega productos desde el catálogo',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver al catálogo'),
                  ),
                ],
              ),
            );
          }

          // ── Lista de items ────────────────────────────────────────────────
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: carrito.items.length,
                  itemBuilder: (_, i) =>
                      CarritoItemCard(item: carrito.items[i]),
                ),
              ),

              // ── Resumen total ─────────────────────────────────────────────
              _ResumenTotal(carrito: carrito),
            ],
          );
        },
      ),
    );
  }

  void _confirmarLimpiar(BuildContext context, CarritoProvider carrito) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Eliminar todos los productos del carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () {
              carrito.limpiar();
              Navigator.pop(context);
            },
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }
}

// ── Widget de resumen y botón continuar ───────────────────────────────────────
class _ResumenTotal extends StatelessWidget {
  final CarritoProvider carrito;
  const _ResumenTotal({required this.carrito});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Línea resumen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${carrito.totalProductos} ${carrito.totalProductos == 1 ? "producto" : "productos"}',
                style: const TextStyle(
                    color: AppTheme.textMedium, fontSize: 14),
              ),
              Text(
                'Total: \$${carrito.totalPrecio.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Botón continuar (próximamente = crear pedido)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: navegar a pantalla de crear pedido
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Próximamente: completar pedido'),
                    backgroundColor: AppTheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Continuar con el pedido'),
            ),
          ),
        ],
      ),
    );
  }
}