import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/auth/providers/auth_provider.dart';
import 'package:tarea_bimestre/core/services/sync_service.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _obscure      = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth    = context.read<AuthProvider>();
    final sync    = context.read<SyncService>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
      syncService: sync,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Error banner ────────────────────────────────────────────────
          if (auth.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: auth.errorMessage!.contains('local')
                    ? Colors.orange.shade50
                    : AppTheme.errorColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: auth.errorMessage!.contains('local')
                      ? Colors.orange.shade300
                      : AppTheme.errorColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    auth.errorMessage!.contains('local')
                        ? Icons.wifi_off
                        : Icons.error_outline,
                    color: auth.errorMessage!.contains('local')
                        ? Colors.orange
                        : AppTheme.errorColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      auth.errorMessage!,
                      style: TextStyle(
                        color: auth.errorMessage!.contains('local')
                            ? Colors.orange.shade800
                            : AppTheme.errorColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: auth.clearError,
                    child: Icon(Icons.close,
                        size: 16,
                        color: auth.errorMessage!.contains('local')
                            ? Colors.orange
                            : AppTheme.errorColor),
                  ),
                ],
              ),
            ),

          // ── Email ────────────────────────────────────────────────────────
          TextFormField(
            controller:   _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration:   const InputDecoration(
              labelText:   'Correo electrónico',
              prefixIcon:  Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu correo';
              if (!v.contains('@'))       return 'Correo no válido';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Password ─────────────────────────────────────────────────────
          TextFormField(
            controller:     _passwordCtrl,
            obscureText:    _obscure,
            decoration: InputDecoration(
              labelText:  'Contraseña',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
              if (v.length < 6)           return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // ── Botón ─────────────────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Iniciar sesión',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}