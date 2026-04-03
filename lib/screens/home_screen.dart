import 'package:adscloneia/models/generation.dart';
import 'package:adscloneia/screens/generation_detail_screen.dart';
import 'package:adscloneia/services/generation_service.dart';
import 'package:adscloneia/theme/app_palette.dart';
import 'package:adscloneia/widgets/constrained_page.dart';
import 'package:adscloneia/widgets/status_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

/// Início: estatísticas e projetos recentes (web-first).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.service,
    required this.onNavigateToCreate,
  });

  final GenerationService? service;
  final VoidCallback onNavigateToCreate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Generation>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _future = _load();
    }
  }

  Future<List<Generation>> _load() async {
    final s = widget.service;
    if (s == null) return [];
    return s.fetchGenerations(limit: 50);
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Widget _statShimmer(AppPalette p) {
    return Shimmer.fromColors(
      baseColor: p.surface,
      highlightColor: p.muted.withValues(alpha: 0.2),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    if (widget.service == null) {
      return ColoredBox(
        color: p.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              'Faça login para ver os seus projetos.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: p.muted,
                height: 1.45,
                fontSize: 15,
              ),
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: p.background,
      child: RefreshIndicator(
        color: p.accent,
        onRefresh: _reload,
        child: FutureBuilder<List<Generation>>(
          future: _future,
          builder: (context, snap) {
            final px = context.p;
            final loading = snap.connectionState == ConnectionState.waiting;
            final items = snap.data ?? [];
            final totalVariants =
                items.fold<int>(0, (a, g) => a + g.variantCount);
            final completed = items.where((g) {
              final s = g.status.toLowerCase();
              return s == 'complete' || s == 'completed';
            }).length;
            final ratePct = items.isEmpty
                ? 0
                : ((completed / items.length) * 100).round();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: MaxWidthBox(
                    maxWidth: 900,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 28, 0, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                px.heroGradient.createShader(bounds),
                            child: Text(
                              'adscloneia',
                              style: GoogleFonts.dmSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Variações de criativos para Meta Ads com IA.',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              height: 1.4,
                              color: px.text,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (loading)
                            Row(
                              children: [
                                Expanded(child: _statShimmer(px)),
                                const SizedBox(width: 16),
                                Expanded(child: _statShimmer(px)),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total pedido',
                                    value: '$totalVariants',
                                    subtitle: 'variações (soma dos projetos)',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Taxa de sucesso',
                                    value: '$ratePct%',
                                    subtitle: '${items.length} projetos',
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 28),
                          FilledButton(
                            onPressed: widget.onNavigateToCreate,
                            style: FilledButton.styleFrom(
                              backgroundColor: px.accent,
                              foregroundColor: px.onAccent,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Criar novo',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Projetos recentes',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: px.text,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!loading && items.isEmpty)
                  SliverToBoxAdapter(
                    child: MaxWidthBox(
                      maxWidth: 900,
                      child: Text(
                        'Nenhum projeto ainda. Toque em Criar novo.',
                        style: GoogleFonts.dmSans(color: px.muted),
                      ),
                    ),
                  ),
                if (!loading && items.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final g = items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MaxWidthBox(
                            maxWidth: 900,
                            child: _RecentProjectTile(
                              generation: g,
                              onTap: () async {
                                await Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => GenerationDetailScreen(
                                      service: widget.service!,
                                      generation: g,
                                    ),
                                  ),
                                );
                                if (mounted) await _reload();
                              },
                            ),
                          ),
                        );
                      },
                      childCount: items.length < 5 ? items.length : 5,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: p.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: p.mono(
              fontSize: 26,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: p.muted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentProjectTile extends StatelessWidget {
  const _RecentProjectTile({
    required this.generation,
    required this.onTap,
  });

  final Generation generation;
  final VoidCallback onTap;

  static String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CachedNetworkImage(
                    imageUrl: generation.originalImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: p.surface,
                      highlightColor: p.muted.withValues(alpha: 0.25),
                      child: Container(color: p.background),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: p.background,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: p.muted,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${generation.variantCount} variações',
                      style: p.mono(
                        fontSize: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(generation.createdAt),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: p.muted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: generation.status),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}
