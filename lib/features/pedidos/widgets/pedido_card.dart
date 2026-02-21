import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/pedido/models/pedido_local_model.dart';

class PedidoCard extends StatelessWidget {
  final PedidoLocalModel pedido;
  final VoidCallback     onTap;

  const PedidoCard({super.key, required this.pedido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chip   = _estadoChip(pedido.estado);
    final total  = pedido.items.fold<double>(
      0, (s, i) => s + (i['precioUnitario'] as num) * (i['cantidad'] as num),
    ) - pedido.descuento;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: chip.borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 6, offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Fila superior: nombre + chip estado ──────────────────────────
            Row(children: [
              Expanded(
                child: Text(pedido.nombreCliente,
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 15, color: AppTheme.textDark),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              _EstadoChipWidget(chip: chip),
            ]),

            const SizedBox(height: 6),

            // ── Cédula y teléfono ─────────────────────────────────────────────
            Text('${pedido.cedula} · ${pedido.telefono}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),

            const SizedBox(height: 4),

            // ── Dirección ─────────────────────────────────────────────────────
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Expanded(child: Text(pedido.direccion,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Fila inferior: items, total, fecha ────────────────────────────
            Row(children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 13, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Text('${pedido.items.length} ${pedido.items.length == 1 ? "producto" : "productos"}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
              const Spacer(),
              Text('\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 15, color: AppTheme.primary)),
            ]),

            const SizedBox(height: 4),

            // Fecha
            Text(
              _formatFecha(pedido.createdAt),
              style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
            ),

            // Mensaje de error si aplica
            if (pedido.estado == EstadoPedido.error &&
                pedido.errorMsg != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(pedido.errorMsg!,
                    style: const TextStyle(fontSize: 11,
                        color: AppTheme.errorColor)),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  String _formatFecha(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  _ChipData _estadoChip(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return _ChipData(label: 'Pendiente', color: const Color(0xFFF59E0B),
            borderColor: const Color(0xFFFDE68A),
            bgColor: const Color(0xFFFFFBEB));
      case EstadoPedido.sincronizado:
        return _ChipData(label: 'Sincronizado', color: AppTheme.success,
            borderColor: const Color(0xFFBBF7D0),
            bgColor: const Color(0xFFF0FDF4));
      case EstadoPedido.error:
        return _ChipData(label: 'Error', color: AppTheme.errorColor,
            borderColor: const Color(0xFFFECACA),
            bgColor: const Color(0xFFFFF1F2));
    }
  }
}

class _ChipData {
  final String label;
  final Color  color;
  final Color  borderColor;
  final Color  bgColor;
  const _ChipData({required this.label, required this.color,
      required this.borderColor, required this.bgColor});
}

class _EstadoChipWidget extends StatelessWidget {
  final _ChipData chip;
  const _EstadoChipWidget({required this.chip});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color:        chip.bgColor,
      borderRadius: BorderRadius.circular(20),
      border:       Border.all(color: chip.borderColor),
    ),
    child: Text(chip.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: chip.color)),
  );
}