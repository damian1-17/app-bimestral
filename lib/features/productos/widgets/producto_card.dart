import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/carrito/providers/carrito_provider.dart';
import 'package:tarea_bimestre/features/productos/models/producto_model.dart';

class ProductoCard extends StatelessWidget {
  final ProductoModel producto;
  const ProductoCard({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final carrito  = context.watch<CarritoProvider>();
    final cantidad = carrito.cantidadEn(producto.idProducto);
    final enCarrito = cantidad > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enCarrito ? AppTheme.accent : AppTheme.border,
          width: enCarrito ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // ── Ícono del producto ──────────────────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),

            // ── Info ────────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    producto.descripcion,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMedium),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${producto.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Botón agregar / contador ────────────────────────────────────
            enCarrito
                ? _ContadorMini(
                    cantidad: cantidad,
                    onIncrement: () =>
                        context.read<CarritoProvider>().incrementar(producto.idProducto),
                    onDecrement: () =>
                        context.read<CarritoProvider>().decrementar(producto.idProducto),
                  )
                : _BtnAgregar(
                    onTap: () {
                      context.read<CarritoProvider>().agregar(producto);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${producto.nombre} agregado'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: AppTheme.accent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
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

// ── Botón "+" inicial ─────────────────────────────────────────────────────────
class _BtnAgregar extends StatelessWidget {
  final VoidCallback onTap;
  const _BtnAgregar({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 20),
    ),
  );
}

// ── Contador +/- cuando ya está en el carrito ─────────────────────────────────
class _ContadorMini extends StatelessWidget {
  final int cantidad;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  const _ContadorMini({
    required this.cantidad,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: AppTheme.accent),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(icon: Icons.remove, onTap: onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$cantidad',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.textDark,
            ),
          ),
        ),
        _Btn(icon: Icons.add, onTap: onIncrement),
      ],
    ),
  );
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Icon(icon, size: 16, color: AppTheme.accent),
    ),
  );
}