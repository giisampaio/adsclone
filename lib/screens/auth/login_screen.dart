import 'package:adscloneia/services/auth_service.dart';
import 'package:adscloneia/theme/app_palette.dart';
import 'package:adscloneia/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Login: email/senha, tema claro, animações fade-up.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onNavigateToRegister,
    this.auth,
  });

  final VoidCallback onNavigateToRegister;
  final AuthService? auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _loading = false;
  String? _error;

  AuthService get _auth => widget.auth ?? AuthService();

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _auth.signIn(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      if (res.session == null && mounted) {
        setState(() {
          _error = 'Confirme o email ou verifique as credenciais.';
          _loading = false;
        });
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _formatAuthError(e);
          _loading = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _loading = false);
  }

  String _formatAuthError(Object e) {
    final s = e.toString();
    if (s.contains('message:')) {
      final i = s.indexOf('message:');
      return s.substring(i + 8).trim();
    }
    return s.replaceFirst('Exception: ', '').replaceFirst('AuthException', 'Erro');
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.light;
    return Theme(
      data: AppTheme.light(),
      child: Builder(
        builder: (context) {
          final themeP = context.p;
          return Scaffold(
            backgroundColor: p.background,
            body: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -60,
                  child: _orb(p.accent.withValues(alpha: 0.22), 220),
                ),
                Positioned(
                  bottom: 100,
                  left: -100,
                  child: _orb(p.secondary.withValues(alpha: 0.18), 280),
                ),
                Positioned(
                  top: 180,
                  left: 40,
                  child: _orb(p.tertiary.withValues(alpha: 0.12), 120),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: FadeTransition(
                          opacity: _fade,
                          child: SlideTransition(
                            position: _slide,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          gradient: p.heroGradient,
                                          boxShadow: [
                                            BoxShadow(
                                              color: p.accent
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'adscloneia',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: p.text,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Creative Studio',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: p.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    decoration: _fieldDec(
                                      themeP,
                                      label: 'Email',
                                      icon: Icons.mail_outline_rounded,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Informe o email';
                                      }
                                      if (!v.contains('@')) {
                                        return 'Email inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: true,
                                    decoration: _fieldDec(
                                      themeP,
                                      label: 'Senha',
                                      icon: Icons.lock_outline_rounded,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Informe a senha';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      _error!,
                                      style: GoogleFonts.dmSans(
                                        color: themeP.tertiary,
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  const SizedBox(height: 28),
                                  SizedBox(
                                    height: 52,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: p.heroGradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: p.accent
                                                .withValues(alpha: 0.35),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _loading ? null : _submit,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: Center(
                                            child: _loading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text(
                                                    'Entrar',
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : widget.onNavigateToRegister,
                                    child: Text(
                                      'Criar conta',
                                      style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w600,
                                        color: p.accent,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _orb(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }

  InputDecoration _fieldDec(
    AppPalette p, {
    required String label,
    required IconData icon,
  }) {
    final focusPurple = BorderSide(color: p.accent, width: 2);
    return InputDecoration(
      prefixIcon: Icon(icon, color: p.muted, size: 22),
      labelText: label,
      labelStyle: GoogleFonts.dmSans(color: p.muted),
      filled: true,
      fillColor: p.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: focusPurple,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.tertiary),
      ),
    );
  }
}
