import 'package:adscloneia/config/app_version.dart';
import 'package:adscloneia/screens/brand_profiles_screen.dart';
import 'package:adscloneia/services/auth_service.dart';
import 'package:adscloneia/services/generation_service.dart';
import 'package:adscloneia/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Config: conta, aparência, sobre, perfis de marca.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.generationService,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final GenerationService generationService;
  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode mode) onThemeModeChanged;

  Future<void> _signOut(BuildContext context) async {
    final auth = AuthService();
    await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '—';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          'Configurações',
          style: GoogleFonts.dmSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: p.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Conta, aparência e informações do app.',
          style: GoogleFonts.dmSans(
            color: p.muted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Conta',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: p.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, color: p.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: p.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: p.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text(
                    'Sair',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.tertiary.withValues(alpha: 0.9),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Aparência',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: p.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Claro'),
              icon: Icon(Icons.light_mode_outlined, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Escuro'),
              icon: Icon(Icons.dark_mode_outlined, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('Sistema'),
              icon: Icon(Icons.brightness_auto_rounded, size: 18),
            ),
          ],
          selected: {themeMode},
          onSelectionChanged: (s) {
            if (s.isNotEmpty) onThemeModeChanged(s.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStateProperty.all(
              GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Workspace',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: p.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      BrandProfilesScreen(service: generationService),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          p.secondary.withValues(alpha: 0.35),
                          p.accent.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      color: p.text,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perfis de marca',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: p.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Briefing de produto, público e tom para reutilizar no Criar',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: p.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: p.muted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Sobre',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: p.muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: p.accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'adscloneia',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: p.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Versão ${AppVersion.label}',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: p.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
