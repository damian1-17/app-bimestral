import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/carrito/models/carrito_item_model.dart';
import 'package:tarea_bimestre/features/carrito/providers/carrito_provider.dart';

class CarritoItemCard extends StatelessWidget {
  final CarritoItem item;
  const CarritoItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final carrito = context.read<CarritoProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Ícono ─────────────────────────────────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),

          // ── Nombre y subtotal ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.producto.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.producto.precio.toStringAsFixed(2)} × ${item.cantidad} = \$${item.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppTheme.textMedium),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Controles +/- y eliminar ──────────────────────────────────────
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ControlBtn(
                    icon: Icons.remove,
                    onTap: () => carrito.decrementar(item.producto.idProducto),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${item.cantidad}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  _ControlBtn(
                    icon: Icons.add,
                    onTap: () => carrito.incrementar(item.producto.idProducto),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => carrito.eliminar(item.producto.idProducto),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: AppTheme.primary),
    ),
  );
}