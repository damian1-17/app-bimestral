import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/carrito/providers/carrito_provider.dart';

/// Muestra un resumen compacto del carrito dentro del formulario de pedido
class ResumenCarritoWidget extends StatelessWidget {
  const ResumenCarritoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          ...carrito.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.producto.nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppTheme.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        '\$${item.producto.precio.toStringAsFixed(2)} × ${item.cantidad}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMedium),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${item.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          )),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${carrito.totalProductos} productos',
                    style: const TextStyle(
                        color: AppTheme.textMedium, fontSize: 13)),
                Text(
                  'Subtotal: \$${carrito.totalPrecio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}