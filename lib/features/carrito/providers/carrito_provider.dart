import 'package:flutter/foundation.dart';
import 'package:tarea_bimestre/features/carrito/models/carrito_item_model.dart';
import 'package:tarea_bimestre/features/productos/models/producto_model.dart';

/// El carrito vive en memoria (no se persiste en BD).
/// Se limpia al cerrar sesión o al completar el pedido.
class CarritoProvider extends ChangeNotifier {
  final List<CarritoItem> _items = [];

  List<CarritoItem> get items => List.unmodifiable(_items);

  int get totalProductos => _items.fold(0, (sum, i) => sum + i.cantidad);

  double get totalPrecio => _items.fold(0, (sum, i) => sum + i.subtotal);

  bool get isEmpty => _items.isEmpty;

  // ── Agregar producto ──────────────────────────────────────────────────────
  void agregar(ProductoModel producto) {
    final index = _items.indexWhere((i) => i.producto.idProducto == producto.idProducto);
    if (index >= 0) {
      _items[index].cantidad++;
    } else {
      _items.add(CarritoItem(producto: producto));
    }
    notifyListeners();
  }

  // ── Incrementar cantidad ──────────────────────────────────────────────────
  void incrementar(int idProducto) {
    final index = _items.indexWhere((i) => i.producto.idProducto == idProducto);
    if (index >= 0) {
      _items[index].cantidad++;
      notifyListeners();
    }
  }

  // ── Decrementar cantidad (elimina si llega a 0) ───────────────────────────
  void decrementar(int idProducto) {
    final index = _items.indexWhere((i) => i.producto.idProducto == idProducto);
    if (index >= 0) {
      if (_items[index].cantidad > 1) {
        _items[index].cantidad--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // ── Eliminar item completo ────────────────────────────────────────────────
  void eliminar(int idProducto) {
    _items.removeWhere((i) => i.producto.idProducto == idProducto);
    notifyListeners();
  }

  // ── Cantidad de un producto específico (para mostrar en lista) ────────────
  int cantidadEn(int idProducto) {
    final index = _items.indexWhere((i) => i.producto.idProducto == idProducto);
    return index >= 0 ? _items[index].cantidad : 0;
  }

  // ── Vaciar carrito ────────────────────────────────────────────────────────
  void limpiar() {
    _items.clear();
    notifyListeners();
  }
}