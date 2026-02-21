import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/pedido/models/pedido_local_model.dart';

class DetallePedidoScreen extends StatelessWidget {
  final PedidoLocalModel pedido;
  const DetallePedidoScreen({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    final total = pedido.items.fold<double>(
      0, (s, i) => s + (i['precioUnitario'] as num) * (i['cantidad'] as num),
    ) - pedido.descuento;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Detalle del Pedido')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Estado ────────────────────────────────────────────────────────
          _estadoBanner(pedido.estado, pedido.errorMsg),
          const SizedBox(height: 16),

          // ── Cliente ───────────────────────────────────────────────────────
          _Seccion(titulo: 'Cliente', children: [
            _Fila(label: 'Nombre',    value: pedido.nombreCliente),
            _Fila(label: 'Cédula',    value: pedido.cedula),
            _Fila(label: 'Teléfono',  value: pedido.telefono),
            if (pedido.email != null && pedido.email!.isNotEmpty)
              _Fila(label: 'Email',   value: pedido.email!),
            _Fila(label: 'Dirección', value: pedido.direccion),
            _Fila(label: 'Pago',
                value: pedido.formaPago == 'efectivo'
                    ? '💵 Efectivo' : '🏦 Transferencia'),
          ]),
          const SizedBox(height: 12),

          // ── Productos ─────────────────────────────────────────────────────
          _Seccion(titulo: 'Productos', children: [
            ...pedido.items.map((item) {
              final subtotal = (item['precioUnitario'] as num) *
                  (item['cantidad'] as num);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['nombreProducto']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600,
                              fontSize: 13, color: AppTheme.textDark)),
                      Text('\$${(item['precioUnitario'] as num).toStringAsFixed(2)} × ${item['cantidad']}',
                          style: const TextStyle(fontSize: 12,
                              color: AppTheme.textMedium)),
                    ],
                  )),
                  Text('\$${subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700,
                          fontSize: 14, color: AppTheme.primary)),
                ]),
              );
            }),
            const Divider(height: 16),
            if (pedido.descuento > 0)
              _Fila(label: 'Descuento',
                  value: '-\$${pedido.descuento.toStringAsFixed(2)}',
                  valueColor: AppTheme.success),
            _Fila(label: 'TOTAL',
                value: '\$${total.toStringAsFixed(2)}',
                bold: true, valueColor: AppTheme.primary),
          ]),
          const SizedBox(height: 12),

          // ── Ubicación GPS ─────────────────────────────────────────────────
          _Seccion(titulo: 'Ubicación GPS', children: [
            if (pedido.latitud != null)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Fila(label: 'Latitud',  value: pedido.latitud!.toStringAsFixed(7)),
                _Fila(label: 'Longitud', value: pedido.longitud!.toStringAsFixed(7)),
              ])
            else
              const Text('Sin ubicación GPS',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
          ]),
          const SizedBox(height: 12),

          // ── Foto ──────────────────────────────────────────────────────────
          _Seccion(titulo: 'Fotografía', children: [
            if (pedido.fotoPath != null && File(pedido.fotoPath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(pedido.fotoPath!),
                    width: double.infinity, height: 200, fit: BoxFit.cover),
              )
            else
              const Row(children: [
                Icon(Icons.image_not_supported_outlined,
                    size: 18, color: AppTheme.textLight),
                SizedBox(width: 8),
                Text('Sin fotografía',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
              ]),
          ]),

          // ── Observaciones ─────────────────────────────────────────────────
          if (pedido.observaciones != null &&
              pedido.observaciones!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Seccion(titulo: 'Observaciones', children: [
              Text(pedido.observaciones!,
                  style: const TextStyle(fontSize: 13,
                      color: AppTheme.textDark)),
            ]),
          ],

          const SizedBox(height: 12),

          // ── Fechas ────────────────────────────────────────────────────────
          _Seccion(titulo: 'Fechas', children: [
            _Fila(label: 'Creado',       value: _formatFecha(pedido.createdAt)),
            if (pedido.syncedAt != null)
              _Fila(label: 'Sincronizado', value: _formatFecha(pedido.syncedAt!)),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _estadoBanner(EstadoPedido estado, String? errorMsg) {
    Color bg; Color color; String label; IconData icon;
    switch (estado) {
      case EstadoPedido.pendiente:
        bg = const Color(0xFFFFFBEB); color = const Color(0xFFF59E0B);
        label = 'Pendiente de sincronización'; icon = Icons.schedule;
        break;
      case EstadoPedido.sincronizado:
        bg = const Color(0xFFF0FDF4); color = AppTheme.success;
        label = 'Sincronizado con el servidor'; icon = Icons.check_circle_outline;
        break;
      case EstadoPedido.error:
        bg = const Color(0xFFFFF1F2); color = AppTheme.errorColor;
        label = 'Error al sincronizar'; icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600,
              color: color, fontSize: 14)),
        ]),
        if (errorMsg != null && errorMsg.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(errorMsg, style: TextStyle(fontSize: 12, color: color)),
        ],
      ]),
    );
  }

  String _formatFecha(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────
class _Seccion extends StatelessWidget {
  final String       titulo;
  final List<Widget> children;
  const _Seccion({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: const TextStyle(fontSize: 11,
          fontWeight: FontWeight.w700, color: AppTheme.textMedium,
          letterSpacing: 0.5)),
      const SizedBox(height: 10),
      ...children,
    ]),
  );
}

class _Fila extends StatelessWidget {
  final String label, value;
  final bool   bold;
  final Color? valueColor;
  const _Fila({required this.label, required this.value,
      this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 88,
          child: Text(label, style: const TextStyle(fontSize: 12,
              color: AppTheme.textMedium))),
      Expanded(child: Text(value,
          style: TextStyle(fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? AppTheme.textDark))),
    ]),
  );
}