import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/carrito/providers/carrito_provider.dart';
import 'package:tarea_bimestre/features/carrito/screens/carrito_screen.dart';
import 'package:tarea_bimestre/features/productos/providers/productos_provider.dart';
import 'package:tarea_bimestre/features/productos/widgets/producto_card.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _searchCtrl  = TextEditingController();
  final _scrollCtrl  = ScrollController();

  @override
  void initState() {
    super.initState();
    // Carga inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductosProvider>().cargarProductos();
    });

    // Listener de scroll para "cargar más" automático al llegar al fondo
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 100) {
        context.read<ProductosProvider>().cargarMas();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _buscar(String value) {
    context.read<ProductosProvider>().cargarProductos(search: value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Seleccionar Productos'),
        actions: [
          // ── Ícono carrito con badge ─────────────────────────────────────
          Consumer<CarritoProvider>(
            builder: (_, carrito, __) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  tooltip: 'Ver carrito',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CarritoScreen()),
                  ),
                ),
                if (carrito.totalProductos > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 18, minHeight: 18),
                      child: Text(
                        '${carrito.totalProductos}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de búsqueda ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: _buscar,
              onChanged: (v) {
                if (v.isEmpty) _buscar('');
              },
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.textMedium, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppTheme.textMedium, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _buscar('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ── Lista de productos ──────────────────────────────────────────
          Expanded(
            child: Consumer<ProductosProvider>(
              builder: (_, prov, __) {
                // Estado de carga inicial
                if (prov.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                // Error
                if (prov.error.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.errorColor, size: 48),
                        const SizedBox(height: 12),
                        Text(prov.error,
                            style: const TextStyle(color: AppTheme.textMedium),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => prov.cargarProductos(
                              search: _searchCtrl.text),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                // Sin resultados
                if (prov.productos.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 56, color: AppTheme.textLight),
                        SizedBox(height: 12),
                        Text('No se encontraron productos',
                            style: TextStyle(color: AppTheme.textMedium)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: prov.productos.length + (prov.hayMasPaginas ? 1 : 0),
                  itemBuilder: (_, index) {
                    // Último item = botón "cargar más"
                    if (index == prov.productos.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 40),
                        child: prov.isLoadingMore
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: AppTheme.primary, strokeWidth: 2))
                            : OutlinedButton.icon(
                                onPressed: prov.cargarMas,
                                icon: const Icon(Icons.expand_more),
                                label: const Text('Cargar más'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(
                                      color: AppTheme.primary),
                                ),
                              ),
                      );
                    }

                    return ProductoCard(
                        producto: prov.productos[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ── FAB: ir al carrito si tiene items ──────────────────────────────
      floatingActionButton: Consumer<CarritoProvider>(
        builder: (_, carrito, __) {
          if (carrito.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: AppTheme.accent,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CarritoScreen()),
            ),
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            label: Text(
              'Ver carrito (${carrito.totalProductos})',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }
}