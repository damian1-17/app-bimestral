import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tarea_bimestre/core/theme/app_theme.dart';
import 'package:tarea_bimestre/features/auth/providers/auth_provider.dart';
import 'package:tarea_bimestre/features/auth/widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // ── Cabecera corporativa ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Registro de\nPedidos',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inicia sesión para continuar',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMedium,
                ),
              ),
              const SizedBox(height: 40),

              // ── Mensaje de error global ───────────────────────────────────
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.errorMessage == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.08),
                      border: Border.all(
                          color: AppTheme.errorColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.errorColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => auth.clearError(),
                          child: const Icon(Icons.close,
                              color: AppTheme.errorColor, size: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ── Formulario ────────────────────────────────────────────────
              const LoginForm(),

              const SizedBox(height: 32),

              // ── Footer ────────────────────────────────────────────────────
              Center(
                child: Text(
                  'v1.0.0 · Uso interno',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}