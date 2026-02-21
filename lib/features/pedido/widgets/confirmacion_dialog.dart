import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/carrito/models/carrito_item_model.dart';

/// Muestra el modal de confirmación antes de guardar el pedido.
/// Retorna true si el usuario confirma, false si cancela.
Future<bool> mostrarConfirmacionPedido({
  required BuildContext context,
  required String       nombreCliente,
  required String       cedula,
  required String       telefono,
  required String       email,
  required String       direccion,
  required String       formaPago,
  required List<CarritoItem> items,
  required double       descuento,
  required double?      latitud,
  required double?      longitud,
  required File?        foto,
  required String?      observaciones,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ConfirmacionDialog(
      nombreCliente: nombreCliente,
      cedula:        cedula,
      telefono:      telefono,
      email:         email,
      direccion:     direccion,
      formaPago:     formaPago,
      items:         items,
      descuento:     descuento,
      latitud:       latitud,
      longitud:      longitud,
      foto:          foto,
      observaciones: observaciones,
    ),
  );
  return result ?? false;
}

class _ConfirmacionDialog extends StatelessWidget {
  final String           nombreCliente;
  final String           cedula;
  final String           telefono;
  final String           email;
  final String           direccion;
  final String           formaPago;
  final List<CarritoItem> items;
  final double           descuento;
  final double?          latitud;
  final double?          longitud;
  final File?            foto;
  final String?          observaciones;

  const _ConfirmacionDialog({
    required this.nombreCliente,
    required this.cedula,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.formaPago,
    required this.items,
    required this.descuento,
    required this.latitud,
    required this.longitud,
    required this.foto,
    required this.observaciones,
  });

  double get subtotal  => items.fold(0, (s, i) => s + i.subtotal);
  double get total     => subtotal - descuento;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: AppTheme.primary,
              child: const Column(children: [
                Icon(Icons.receipt_long, color: Colors.white, size: 28),
                SizedBox(height: 6),
                Text('Confirmar pedido',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ]),
            ),

            // ── Contenido scrolleable ────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Cliente ──────────────────────────────────────────────
                    _Seccion(titulo: 'Cliente', children: [
                      _Fila(label: 'Nombre',    value: nombreCliente),
                      _Fila(label: 'Cédula',    value: cedula),
                      _Fila(label: 'Teléfono',  value: telefono),
                      if (email.isNotEmpty)
                        _Fila(label: 'Email',   value: email),
                      _Fila(label: 'Dirección', value: direccion),
                      _Fila(label: 'Pago',
                          value: formaPago == 'efectivo' ? '💵 Efectivo' : '🏦 Transferencia'),
                    ]),

                    const SizedBox(height: 14),

                    // ── Productos ─────────────────────────────────────────────
                    _Seccion(titulo: 'Productos', children: [
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Expanded(child: Text(item.producto.nombre,
                              style: const TextStyle(fontSize: 13,
                                  color: AppTheme.textDark),
                              maxLines: 2, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Text('×${item.cantidad}',
                              style: const TextStyle(fontSize: 12,
                                  color: AppTheme.textMedium)),
                          const SizedBox(width: 8),
                          Text('\$${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary)),
                        ]),
                      )),
                      const Divider(height: 12),
                      _Fila(label: 'Subtotal',
                          value: '\$${subtotal.toStringAsFixed(2)}'),
                      if (descuento > 0)
                        _Fila(label: 'Descuento',
                            value: '-\$${descuento.toStringAsFixed(2)}',
                            valueColor: AppTheme.success),
                      _Fila(label: 'TOTAL',
                          value: '\$${total.toStringAsFixed(2)}',
                          bold: true, valueColor: AppTheme.primary),
                    ]),

                    const SizedBox(height: 14),

                    // ── Evidencia ─────────────────────────────────────────────
                    _Seccion(titulo: 'Evidencia', children: [
                      // GPS
                      Row(children: [
                        Icon(
                          latitud != null ? Icons.gps_fixed : Icons.gps_off,
                          size: 16,
                          color: latitud != null ? AppTheme.success : AppTheme.textLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          latitud != null
                              ? 'Lat: ${latitud!.toStringAsFixed(5)}  Lon: ${longitud!.toStringAsFixed(5)}'
                              : 'Sin ubicación GPS',
                          style: TextStyle(
                            fontSize: 12,
                            color: latitud != null ? AppTheme.textDark : AppTheme.textLight,
                          ),
                        )),
                      ]),
                      const SizedBox(height: 8),

                      // Foto
                      if (foto != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(foto!, height: 120,
                              width: double.infinity, fit: BoxFit.cover),
                        ),
                      ] else
                        Row(children: const [
                          Icon(Icons.image_not_supported_outlined,
                              size: 16, color: AppTheme.textLight),
                          SizedBox(width: 8),
                          Text('Sin foto adjunta',
                              style: TextStyle(fontSize: 12,
                                  color: AppTheme.textLight)),
                        ]),
                    ]),

                    // ── Observaciones ─────────────────────────────────────────
                    if (observaciones != null && observaciones!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _Seccion(titulo: 'Observaciones', children: [
                        Text(observaciones!,
                            style: const TextStyle(fontSize: 13,
                                color: AppTheme.textMedium)),
                      ]),
                    ],

                    // ── Nota estado ───────────────────────────────────────────
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.2)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline,
                            color: AppTheme.primary, size: 16),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          'El pedido se guardará localmente y se sincronizará con el servidor cuando haya conexión.',
                          style: TextStyle(fontSize: 12,
                              color: AppTheme.primary),
                        )),
                      ]),
                    ),
                  ],
                ),
              ),
            ),

            // ── Botones ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textMedium,
                      side: const BorderSide(color: AppTheme.border),
                      minimumSize: const Size(0, 46),
                    ),
                    child: const Text('Revisar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.save_alt, size: 18),
                    label: const Text('Confirmar y guardar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _Seccion extends StatelessWidget {
  final String        titulo;
  final List<Widget>  children;
  const _Seccion({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: const TextStyle(fontSize: 12,
          fontWeight: FontWeight.w700, color: AppTheme.textMedium,
          letterSpacing: 0.5)),
      const SizedBox(height: 8),
      ...children,
    ]),
  );
}

class _Fila extends StatelessWidget {
  final String  label;
  final String  value;
  final bool    bold;
  final Color?  valueColor;
  const _Fila({required this.label, required this.value,
      this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 80,
        child: Text(label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
      ),
      Expanded(child: Text(value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppTheme.textDark,
          ))),
    ]),
  );
}