import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/clientes/models/cliente_model.dart';
import 'package:tarea_bimestre/features/clientes/providers/clientes_provider.dart';

/// Muestra un bottom sheet para buscar y seleccionar un cliente existente
Future<ClienteModel?> mostrarSelectorCliente(BuildContext context) async {
  return showModalBottomSheet<ClienteModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider(
      create: (_) => ClientesProvider()..buscarClientes(),
      child: const _SelectorClienteSheet(),
    ),
  );
}

class _SelectorClienteSheet extends StatefulWidget {
  const _SelectorClienteSheet();

  @override
  State<_SelectorClienteSheet> createState() => _SelectorClienteSheetState();
}

class _SelectorClienteSheetState extends State<_SelectorClienteSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize:     0.95,
      minChildSize:     0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Seleccionar cliente',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 12),

            // Buscador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => context
                    .read<ClientesProvider>()
                    .buscarClientes(search: v),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o cédula...',
                  prefixIcon: Icon(Icons.search,
                      color: AppTheme.textMedium, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Lista
            Expanded(
              child: Consumer<ClientesProvider>(
                builder: (_, prov, __) {
                  if (prov.isLoading) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary));
                  }
                  if (prov.error.isNotEmpty) {
                    return Center(child: Text(prov.error,
                        style: const TextStyle(color: AppTheme.errorColor)));
                  }
                  if (prov.clientes.isEmpty) {
                    return const Center(
                        child: Text('No se encontraron clientes',
                            style: TextStyle(color: AppTheme.textMedium)));
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    itemCount: prov.clientes.length,
                    itemBuilder: (_, i) {
                      final c = prov.clientes[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Text(
                            c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(c.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark)),
                        subtitle: Text('${c.cedula} · ${c.email}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textMedium)),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}