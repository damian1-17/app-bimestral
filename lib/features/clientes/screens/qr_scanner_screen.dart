import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import 'package:tarea_bimestre/core/network/dio_client.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/clientes/models/cliente_model.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _procesando = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_procesando) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() { _procesando = true; _error = null; });
    await _controller.stop();

    final raw = barcode!.rawValue!.trim();

    // El QR puede contener solo el id o una URL que termine en el id
    final idStr  = raw.split('/').last;
    final id     = int.tryParse(idStr);

    if (id == null) {
      _mostrarError('QR no válido: no contiene un ID de cliente.');
      return;
    }

    await _buscarCliente(id);
  }

  Future<void> _buscarCliente(int id) async {
    try {
      final response = await DioClient.instance
          .get('usuarios/$id')
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Extraer roles como lista de strings
        final rolesRaw = data['roles'] as List? ?? [];
        final roles    = rolesRaw
            .map((r) => (r as Map<String, dynamic>)['nombre']?.toString() ?? '')
            .where((r) => r.isNotEmpty)
            .toList();

        final cliente = ClienteModel(
          idUsuario:  data['idUsuario'] as int,
          nombre:     data['nombre']    as String,
          cedula:     data['cedula']    as String,
          email:      data['email']     as String? ?? '',
          estado:     data['estado']    as String? ?? 'activo',
          roles:      roles,
        );

        if (mounted) Navigator.pop(context, cliente);
      } else if (response.statusCode == 404) {
        _mostrarError('Cliente no encontrado en el servidor.');
      } else {
        _mostrarError('Error ${response.statusCode} al buscar el cliente.');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        _mostrarError('Sin conexión. Verifica tu internet.');
      } else {
        _mostrarError('Error de red: ${e.message}');
      }
    } catch (e) {
      _mostrarError('Error inesperado: $e');
    }
  }

  void _mostrarError(String msg) {
    setState(() { _error = msg; _procesando = false; });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Leer QR del cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Linterna',
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Cámara ────────────────────────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ── Marco guía ────────────────────────────────────────────────────
          Center(
            child: Container(
              width:  260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accent, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // ── Instrucción ───────────────────────────────────────────────────
          Positioned(
            bottom: 60,
            left: 0, right: 0,
            child: Column(
              children: [
                if (_procesando)
                  const Column(children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text('Buscando cliente...',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ])
                else if (_error != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(children: [
                      Text(_error!,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _error = null),
                        child: const Text('Reintentar',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ]),
                  )
                else
                  const Text(
                    'Apunta al QR del cliente',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}