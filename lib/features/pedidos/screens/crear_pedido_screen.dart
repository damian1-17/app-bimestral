import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/carrito/providers/carrito_provider.dart';
import 'package:tarea_bimestre/features/clientes/models/cliente_model.dart';
import 'package:tarea_bimestre/features/clientes/widgets/selector_cliente_widget.dart';
import 'package:tarea_bimestre/features/pedidos/providers/pedido_provider.dart';

import 'package:tarea_bimestre/features/pedidos/widgets/resumen_carrito_widget.dart';

class CrearPedidoScreen extends StatefulWidget {
  const CrearPedidoScreen({super.key});

  @override
  State<CrearPedidoScreen> createState() => _CrearPedidoScreenState();
}

class _CrearPedidoScreenState extends State<CrearPedidoScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _nombreCtrl    = TextEditingController();
  final _cedulaCtrl    = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _descuentoCtrl = TextEditingController(text: '0');
  final _obsCtrl       = TextEditingController();

  ClienteModel? _clienteSeleccionado;
  String        _formaPago  = 'efectivo';
  File?         _foto;
  double?       _latitud;
  double?       _longitud;
  bool          _gpsLoading = false;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cedulaCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _descuentoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  // ── GPS automático ────────────────────────────────────────────────────────
  Future<void> _obtenerUbicacion() async {
    setState(() => _gpsLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _gpsLoading = false); return; }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) { setState(() => _gpsLoading = false); return; }
      }
      if (perm == LocationPermission.deniedForever) { setState(() => _gpsLoading = false); return; }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() { _latitud = pos.latitude; _longitud = pos.longitude; _gpsLoading = false; });
    } catch (_) { setState(() => _gpsLoading = false); }
  }

  // ── Foto ──────────────────────────────────────────────────────────────────
  Future<void> _seleccionarFoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
        source: source, imageQuality: 70, maxWidth: 1024);
    if (picked != null) setState(() => _foto = File(picked.path));
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
            title: const Text('Tomar foto'),
            onTap: () { Navigator.pop(context); _seleccionarFoto(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppTheme.primary),
            title: const Text('Elegir de galería'),
            onTap: () { Navigator.pop(context); _seleccionarFoto(ImageSource.gallery); },
          ),
        ]),
      ),
    );
  }

  // ── Selector de cliente ───────────────────────────────────────────────────
  Future<void> _seleccionarCliente() async {
    final c = await mostrarSelectorCliente(context);
    if (c != null) {
      setState(() {
        _clienteSeleccionado = c;
        _nombreCtrl.text   = c.nombre;
        _cedulaCtrl.text   = c.cedula;
        _emailCtrl.text    = c.email;
      });
    }
  }

  // ── Enviar ────────────────────────────────────────────────────────────────
  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    final carrito = context.read<CarritoProvider>();
    if (carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío'),
            backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    final ok = await context.read<PedidoProvider>().crearPedido(
      cliente:         _clienteSeleccionado,
      nombreCliente:   _nombreCtrl.text.trim(),
      cedula:          _cedulaCtrl.text.trim(),
      direccion:       _direccionCtrl.text.trim(),
      telefono:        _telefonoCtrl.text.trim(),
      email:           _emailCtrl.text.trim(),
      formaPago:       _formaPago,
      items:           carrito.items,
      descuentoGlobal: double.tryParse(_descuentoCtrl.text) ?? 0,
      observaciones:   _obsCtrl.text.trim(),
      latitud:         _latitud,
      longitud:        _longitud,
      foto:            _foto,
    );

    if (ok && mounted) {
      carrito.limpiar();
      _mostrarExito(context.read<PedidoProvider>().successMsg);
    }
  }

  void _mostrarExito(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: AppTheme.success, size: 64),
          const SizedBox(height: 16),
          const Text('¡Pedido guardado!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Text(msg, textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMedium, fontSize: 13)),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov      = context.watch<PedidoProvider>();
    final isLoading = prov.status == PedidoStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Nuevo Pedido')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── 1. Cliente ─────────────────────────────────────────────────
            _Titulo('1. Datos del cliente'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _seleccionarCliente,
              icon: const Icon(Icons.person_search),
              label: Text(_clienteSeleccionado == null
                  ? 'Buscar cliente existente'
                  : 'Cliente: ${_clienteSeleccionado!.nombre}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('o ingresa manualmente',
                    style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 8),
            _Campo(ctrl: _nombreCtrl,    label: 'Nombre completo *',
                hint: 'Juan Pérez',      icon: Icons.person_outline,
                validator: _requerido),
            const SizedBox(height: 12),
            _Campo(ctrl: _cedulaCtrl,    label: 'Cédula *',
                hint: '1234567890',      icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                validator: _requerido),
            const SizedBox(height: 12),
            _Campo(ctrl: _telefonoCtrl,  label: 'Teléfono *',
                hint: '0987654321',      icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _requerido),
            const SizedBox(height: 12),
            _Campo(ctrl: _emailCtrl,     label: 'Email',
                hint: 'cliente@email.com', icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _Campo(ctrl: _direccionCtrl, label: 'Dirección *',
                hint: 'Av. Principal y Calle',
                icon: Icons.location_on_outlined,
                validator: _requerido),

            const SizedBox(height: 24),

            // ── 2. Forma de pago ───────────────────────────────────────────
            _Titulo('2. Forma de pago'),
            const SizedBox(height: 8),
            Row(children: [
              _RadioPago(valor: 'efectivo',      grupo: _formaPago,
                  label: 'Efectivo',       icon: Icons.payments_outlined,
                  onChanged: (v) => setState(() => _formaPago = v!)),
              const SizedBox(width: 12),
              _RadioPago(valor: 'transferencia', grupo: _formaPago,
                  label: 'Transferencia',  icon: Icons.account_balance_outlined,
                  onChanged: (v) => setState(() => _formaPago = v!)),
            ]),

            const SizedBox(height: 24),

            // ── 3. Productos ───────────────────────────────────────────────
            _Titulo('3. Productos'),
            const SizedBox(height: 8),
            const ResumenCarritoWidget(),
            const SizedBox(height: 12),
            _Campo(
              ctrl: _descuentoCtrl,
              label: 'Descuento global (\$)',
              hint: '0',
              icon: Icons.discount_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),

            const SizedBox(height: 24),

            // ── 4. Evidencia ───────────────────────────────────────────────
            _Titulo('4. Evidencia'),
            const SizedBox(height: 12),

            // GPS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(children: [
                Icon(_latitud != null ? Icons.gps_fixed : Icons.gps_not_fixed,
                    color: _latitud != null ? AppTheme.success : AppTheme.textMedium),
                const SizedBox(width: 10),
                Expanded(
                  child: _gpsLoading
                      ? const Text('Obteniendo ubicación...',
                          style: TextStyle(color: AppTheme.textMedium))
                      : _latitud != null
                          ? Text(
                              'Lat: ${_latitud!.toStringAsFixed(6)}\nLon: ${_longitud!.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textDark))
                          : const Text('Ubicación no disponible',
                              style: TextStyle(color: AppTheme.textMedium)),
                ),
                if (_gpsLoading)
                  const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primary))
                else
                  TextButton(onPressed: _obtenerUbicacion,
                      child: const Text('Reintentar')),
              ]),
            ),

            const SizedBox(height: 12),

            // Foto
            GestureDetector(
              onTap: _mostrarOpcionesFoto,
              child: Container(
                height: _foto == null ? 120 : 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _foto == null ? AppTheme.border : AppTheme.accent,
                    width: _foto == null ? 1 : 2,
                  ),
                ),
                child: _foto == null
                    ? const Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 36,
                              color: AppTheme.textLight),
                          SizedBox(height: 8),
                          Text('Tomar foto o elegir de galería',
                              style: TextStyle(color: AppTheme.textMedium)),
                        ])
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.file(_foto!, fit: BoxFit.cover,
                            width: double.infinity)),
              ),
            ),

            const SizedBox(height: 24),

            // ── 5. Observaciones ───────────────────────────────────────────
            _Titulo('5. Observaciones (opcional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _obsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Notas adicionales...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.notes, color: AppTheme.textMedium),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Error
            if (prov.status == PedidoStatus.error)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.08),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(prov.error,
                    style: const TextStyle(color: AppTheme.errorColor)),
              ),

            // Botón
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _enviar,
                icon: isLoading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.save),
                label: Text(isLoading ? 'Guardando...' : 'Guardar pedido'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String? _requerido(String? v) => (v == null || v.isEmpty) ? 'Campo requerido' : null;
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────
class _Titulo extends StatelessWidget {
  final String text;
  const _Titulo(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
          color: AppTheme.primary));
}

class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _Campo({required this.ctrl, required this.label, required this.hint,
      required this.icon, this.keyboardType, this.validator, this.inputFormatters});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, keyboardType: keyboardType,
    inputFormatters: inputFormatters, validator: validator,
    decoration: InputDecoration(labelText: label, hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textMedium, size: 20)),
  );
}

class _RadioPago extends StatelessWidget {
  final String valor, grupo, label;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _RadioPago({required this.valor, required this.grupo,
      required this.label, required this.icon, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final sel = valor == grupo;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(valor),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: sel ? AppTheme.primary.withOpacity(0.08) : Colors.white,
            border: Border.all(
                color: sel ? AppTheme.primary : AppTheme.border,
                width: sel ? 1.8 : 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Radio<String>(value: valor, groupValue: grupo, onChanged: onChanged,
                activeColor: AppTheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
            Icon(icon, size: 18,
                color: sel ? AppTheme.primary : AppTheme.textMedium),
            const SizedBox(width: 4),
            Flexible(child: Text(label,
                style: TextStyle(fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                    color: sel ? AppTheme.primary : AppTheme.textDark))),
          ]),
        ),
      ),
    );
  }
}