import 'package:adscloneia/services/auth_service.dart';
import 'package:adscloneia/theme/app_palette.dart';
import 'package:adscloneia/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Registro: email, senha, confirmar senha.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onNavigateToLogin,
    this.auth,
  });

  final VoidCallback onNavigateToLogin;
  final AuthService? auth;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _loading = false;
  String? _error;
  String? _success;

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
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final res = await _auth.signUp(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      if (mounted) {
        if (res.session != null) {
          _success = null;
        } else {
          _success =
              'Verifique seu email para confirmar a conta (se a confirmação estiver ativa no projeto).';
        }
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
                  top: -60,
                  left: -80,
                  child: _orb(p.secondary.withValues(alpha: 0.2), 240),
                ),
                Positioned(
                  bottom: 40,
                  right: -40,
                  child: _orb(p.accent.withValues(alpha: 0.15), 200),
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
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: _loading
                                            ? null
                                            : widget.onNavigateToLogin,
                                        icon: Icon(
                                          Icons.arrow_back_rounded,
                                          color: p.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Criar conta',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: p.text,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Comece a gerar variações dos seus criativos.',
                                    style: GoogleFonts.dmSans(
                                      color: p.muted,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
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
                                      if (v == null || v.length < 6) {
                                        return 'Mínimo 6 caracteres';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _confirmCtrl,
                                    obscureText: true,
                                    decoration: _fieldDec(
                                      themeP,
                                      label: 'Confirmar senha',
                                      icon: Icons.lock_outline_rounded,
                                    ),
                                    validator: (v) {
                                      if (v != _passCtrl.text) {
                                        return 'Senhas não coincidem';
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
                                    ),
                                  ],
                                  if (_success != null) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      _success!,
                                      style: GoogleFonts.dmSans(
                                        color: themeP.accent,
                                        fontSize: 13,
                                      ),
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
                                                    'Criar conta',
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
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : widget.onNavigateToLogin,
                                    child: Text(
                                      'Já tenho conta',
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
