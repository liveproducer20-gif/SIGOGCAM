import 'package:flutter/material.dart';

import '../../core/cnst/app_cnst.dart';
import '../../core/thm/app_thm.dart';
import '../dash/dash_scr.dart';
import 'auth_api.dart';

class AuthScr extends StatelessWidget {
  const AuthScr({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isWide ? const _AuthWide() : const _AuthMob(),
    );
  }
}

class _AuthWide extends StatelessWidget {
  const _AuthWide();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 5, child: _AuthImgPanel()),
        Expanded(flex: 4, child: _AuthFrmPanel()),
      ],
    );
  }
}

class _AuthMob extends StatelessWidget {
  const _AuthMob();

  @override
  Widget build(BuildContext context) {
    return const _AuthFrmPanel();
  }
}

class _AuthImgPanel extends StatelessWidget {
  const _AuthImgPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/img/auth_bg.jpg', fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppThm.priClr.withValues(alpha: 0.15),
                AppThm.priClr.withValues(alpha: 0.95),
              ],
            ),
          ),
        ),
        const Positioned(
          left: 60,
          right: 60,
          bottom: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Sistema Inteligente de\nGestión Operativa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Cuerpo de agentes de control Municipal de Guayaquil',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              SizedBox(height: 18),
              Text(
                'SIGO-GCAM',
                style: TextStyle(
                  color: AppThm.accClr,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 22),
              Text(
                'Lealtad, Valor, Orden',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthFrmPanel extends StatefulWidget {
  const _AuthFrmPanel();

  @override
  State<_AuthFrmPanel> createState() => _AuthFrmPanelState();
}

class _AuthFrmPanelState extends State<_AuthFrmPanel> {
  final usuarioCtl = TextEditingController();
  final passCtl = TextEditingController();
  final api = AuthApi();
  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    usuarioCtl.dispose();
    passCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/img/logo_sigo_gcam.png',
                      height: 100,
                      width: 100,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Bienvenido Agente',
                          style: TextStyle(
                            color: AppThm.priClr,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: 58,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppThm.secClr,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Inicia sesión para continuar',
                  style: TextStyle(color: Colors.black54, fontSize: 18),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Correo institucional',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: usuarioCtl,
                  decoration: InputDecoration(
                    hintText: 'usuario@institucion.gob.ec',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Contraseña',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtl,
                  obscureText: !showPassword,
                  onSubmitted: (_) => loading ? null : _login(),
                  decoration: InputDecoration(
                    hintText: 'Ingresa tu contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: showPassword
                          ? 'Ocultar contraseña'
                          : 'Ver contraseña',
                      onPressed: () {
                        setState(() => showPassword = !showPassword);
                      },
                      icon: Icon(
                        showPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: loading ? null : _login,
                  icon: Icon(
                    loading ? Icons.hourglass_top : Icons.lock_outline,
                  ),
                  label: Text(
                    loading ? 'Ingresando...' : 'Iniciar sesión',
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
                const SizedBox(height: 42),
                const Divider(),
                const SizedBox(height: 28),
                Center(
                  child: Image.asset(
                    'assets/img/sigo_gcam.png',
                    height: 240,
                    width: 240,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Versión ${AppCnst.appVer}',
                    style: TextStyle(color: Colors.black45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final usuario = usuarioCtl.text.trim();
    final password = passCtl.text.trim();

    if (usuario.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingrese el correo institucional y la cédula como contraseña',
          ),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final user = await api.login(usuario: usuario, password: password);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashScr(user: user)),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
