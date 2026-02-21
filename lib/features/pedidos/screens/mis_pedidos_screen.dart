import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/pedido/models/pedido_local_model.dart';
import 'package:tarea_bimestre/features/pedidos/providers/pedidos_list_provider.dart';
import 'package:tarea_bimestre/features/pedidos/screens/detalle_pedido_screen.dart';
import 'package:tarea_bimestre/features/pedidos/widgets/pedido_card.dart';

class MisPedidosScreen extends StatefulWidget {
  const MisPedidosScreen({super.key});

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PedidosListProvider>().cargarPedidos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        actions: [
          // ── Botón Sincronizar ─────────────────────────────────────────────
          Consumer<PedidosListProvider>(
            builder: (_, prov, __) {
              if (prov.isSyncing) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5)),
                );
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.sync),
                    tooltip: 'Sincronizar pedidos pendientes',
                    onPressed: () => _sincronizar(context, prov),
                  ),
                  // Badge con cantidad de pendientes
                  if (prov.totalPendientes > 0)
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B), shape: BoxShape.circle),
                        constraints: const BoxConstraints(
                            minWidth: 18, minHeight: 18),
                        child: Text('${prov.totalPendientes}',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 10, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      body: Consumer<PedidosListProvider>(
        builder: (_, prov, __) {
          // Mensaje de resultado de sincronización
          if (prov.syncMsg.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(prov.syncMsg),
                  backgroundColor: prov.syncMsg.startsWith('✅')
                      ? AppTheme.success
                      : prov.syncMsg.startsWith('⚠️')
                          ? const Color(0xFFF59E0B)
                          : AppTheme.errorColor,
                  behavior:        SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  duration: const Duration(seconds: 4),
                ),
              );
              prov.limpiarMensaje();
            });
          }

          if (prov.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (prov.pedidos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 72, color: AppTheme.textLight),
                  const SizedBox(height: 16),
                  const Text('No hay pedidos registrados',
                      style: TextStyle(fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMedium)),
                  const SizedBox(height: 8),
                  const Text('Los pedidos que crees aparecerán aquí',
                      style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
                ],
              ),
            );
          }

          // ── Resumen de estados ──────────────────────────────────────────────
          return Column(
            children: [
              _ResumenEstados(pedidos: prov.pedidos),

              // ── Lista ───────────────────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: prov.cargarPedidos,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    itemCount: prov.pedidos.length,
                    itemBuilder: (_, i) => PedidoCard(
                      pedido: prov.pedidos[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetallePedidoScreen(
                              pedido: prov.pedidos[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sincronizar(
      BuildContext context, PedidosListProvider prov) async {
    if (prov.totalPendientes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay pedidos pendientes.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Confirmar antes de sincronizar
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sincronizar pedidos'),
        content: Text(
          'Se enviarán ${prov.totalPendientes} '
          '${prov.totalPendientes == 1 ? "pedido pendiente" : "pedidos pendientes"} '
          'al servidor. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.sync, size: 18),
            label: const Text('Sincronizar'),
          ),
        ],
      ),
    );

    if (confirmar == true) await prov.sincronizar();
  }
}

// ── Widget resumen de estados ─────────────────────────────────────────────────
class _ResumenEstados extends StatelessWidget {
  final List<PedidoLocalModel> pedidos;
  const _ResumenEstados({required this.pedidos});

  @override
  Widget build(BuildContext context) {
    final pendientes    = pedidos.where((p) => p.estado == EstadoPedido.pendiente).length;
    final sincronizados = pedidos.where((p) => p.estado == EstadoPedido.sincronizado).length;
    final errores       = pedidos.where((p) => p.estado == EstadoPedido.error).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(valor: pedidos.length, label: 'Total',
              color: AppTheme.primary),
          _Separador(),
          _StatItem(valor: pendientes, label: 'Pendientes',
              color: const Color(0xFFF59E0B)),
          _Separador(),
          _StatItem(valor: sincronizados, label: 'Sincronizados',
              color: AppTheme.success),
          _Separador(),
          _StatItem(valor: errores, label: 'Con error',
              color: AppTheme.errorColor),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int    valor;
  final String label;
  final Color  color;
  const _StatItem({required this.valor, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('$valor', style: TextStyle(fontSize: 20,
          fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10,
          color: AppTheme.textMedium)),
    ],
  );
}

class _Separador extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: AppTheme.border);
}