import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/auth/providers/auth_provider.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _obscurePass  = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth    = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Email ─────────────────────────────────────────────────────────
          _FieldLabel(text: 'Correo electrónico'),
          const SizedBox(height: 8),
          TextFormField(
            controller:   _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled:      !isLoading,
            decoration: const InputDecoration(
              hintText:    'usuario@ejemplo.com',
              prefixIcon:  Icon(Icons.mail_outline, size: 20,
                               color: AppTheme.textMedium),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu correo';
              if (!v.contains('@')) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // ── Contraseña ────────────────────────────────────────────────────
          _FieldLabel(text: 'Contraseña'),
          const SizedBox(height: 8),
          TextFormField(
            controller:  _passwordCtrl,
            obscureText: _obscurePass,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            enabled:     !isLoading,
            decoration: InputDecoration(
              hintText:   '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, size: 20,
                              color: AppTheme.textMedium),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility_outlined
                               : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppTheme.textMedium,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 32),

          // ── Botón login ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      width:  22,
                      height: 22,
                      child:  CircularProgressIndicator(
                        color:       Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Iniciar sesión'),
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────────
          const SizedBox(height: 24),
          Row(children: [
            const Expanded(child: Divider(color: AppTheme.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('versión de prueba',
                  style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
            ),
            const Expanded(child: Divider(color: AppTheme.border)),
          ]),
        ],
      ),
    );
  }
}

// ── Widget auxiliar de etiqueta de campo ──────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize:   13,
      fontWeight: FontWeight.w600,
      color:      AppTheme.textDark,
      letterSpacing: 0.1,
    ),
  );
}