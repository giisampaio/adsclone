import 'dart:math' as math;

import 'package:adscloneia/models/generation.dart';
import 'package:adscloneia/screens/generation_detail_screen.dart';
import 'package:adscloneia/services/generation_service.dart';
import 'package:adscloneia/theme/app_palette.dart';
import 'package:adscloneia/utils/project_card_helpers.dart';
import 'package:adscloneia/widgets/app_empty_state.dart';
import 'package:adscloneia/widgets/constrained_page.dart';
import 'package:adscloneia/widgets/hover_card.dart';
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

class _HomeData {
  _HomeData(this.generations, this.previewUrls);

  final List<Generation> generations;
  final Map<String, List<String>> previewUrls;
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future;

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

  Future<_HomeData> _load() async {
    final s = widget.service;
    if (s == null) return _HomeData([], {});
    final gens = await s.fetchGenerations(limit: 50);
    final top = gens.take(5).map((g) => g.id).toList();
    final previews = top.isEmpty
        ? <String, List<String>>{}
        : await s.fetchPreviewImageUrlsByGenerationIds(top, limitPerGen: 5);
    return _HomeData(gens, previews);
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

  static int _recentCols(double width) {
    if (width >= 1024) return 3;
    if (width >= 600) return 2;
    return 1;
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
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snap) {
            final px = context.p;
            final loading = snap.connectionState == ConnectionState.waiting;
            final items = snap.data?.generations ?? [];
            final previews = snap.data?.previewUrls ?? {};
            final totalVariants =
                items.fold<int>(0, (a, g) => a + g.variantCount);
            final completed = items.where((g) {
              final s0 = g.status.toLowerCase();
              return s0 == 'complete' || s0 == 'completed';
            }).length;
            final ratePct = items.isEmpty
                ? 0
                : ((completed / items.length) * 100).round();
            final recentCount = math.min(5, items.length);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: MaxWidthBox(
                    maxWidth: 1200,
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
                                  child: HoverScaleCard(
                                    borderRadius: 16,
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: _StatCardInner(
                                        label: 'Total pedido',
                                        value: '$totalVariants',
                                        subtitle:
                                            'variações (soma dos projetos)',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: HoverScaleCard(
                                    borderRadius: 16,
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: _StatCardInner(
                                        label: 'Taxa de sucesso',
                                        value: '$ratePct%',
                                        subtitle: '${items.length} projetos',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 28),
                          Tooltip(
                            message:
                                'Criar novas variações de um criativo',
                            child: FilledButton(
                              onPressed: widget.onNavigateToCreate,
                              style: _accentFilledHoverStyle(px),
                              child: Text(
                                'Criar novo',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
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
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: MaxWidthBox(
                      maxWidth: 900,
                      child: AppEmptyState(
                        icon: Icons.image_outlined,
                        secondaryIcon: Icons.auto_awesome_rounded,
                        title: 'Nenhum projeto ainda',
                        subtitle:
                            'Comece enviando seu primeiro criativo campeão',
                        actionLabel: 'Criar primeiro projeto',
                        onAction: widget.onNavigateToCreate,
                      ),
                    ),
                  ),
                if (!loading && items.isNotEmpty)
                  SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final cols = _recentCols(constraints.crossAxisExtent);
                      return SliverPadding(
                        padding: const EdgeInsets.only(bottom: 32),
                        sliver: SliverToBoxAdapter(
                          child: MaxWidthBox(
                            maxWidth: 1200,
                            child: LayoutBuilder(
                              builder: (context, c2) {
                                final w = c2.maxWidth;
                                final colW = (w - (cols - 1) * 16) / cols;
                                return Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    for (var i = 0; i < recentCount; i++)
                                      SizedBox(
                                        width: colW,
                                        child: _RecentProjectTile(
                                          generation: items[i],
                                          previewUrls:
                                              previews[items[i].id] ?? [],
                                          onTap: () async {
                                            await Navigator.of(context)
                                                .push<void>(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    GenerationDetailScreen(
                                                  service: widget.service!,
                                                  generation: items[i],
                                                ),
                                              ),
                                            );
                                            if (mounted) await _reload();
                                          },
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

ButtonStyle _accentFilledHoverStyle(AppPalette px) {
  return FilledButton.styleFrom(
    backgroundColor: px.accent,
    foregroundColor: px.onAccent,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    elevation: 2,
    shadowColor: px.accent.withValues(alpha: 0.45),
  ).copyWith(
    elevation: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) return 10;
      if (states.contains(WidgetState.pressed)) return 1;
      return 3;
    }),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) {
        return Color.alphaBlend(
          Colors.white.withValues(alpha: 0.12),
          px.accent,
        );
      }
      return px.accent;
    }),
  );
}

class _StatCardInner extends StatelessWidget {
  const _StatCardInner({
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
    return Column(
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
    );
  }
}

class _RecentProjectTile extends StatelessWidget {
  const _RecentProjectTile({
    required this.generation,
    required this.previewUrls,
    required this.onTap,
  });

  final Generation generation;
  final List<String> previewUrls;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final brief = generationCreativeBrief(generation.analysis);
    final rel = formatRelativeTimePt(generation.createdAt);

    return HoverScaleCard(
      borderRadius: 14,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
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
            const SizedBox(width: 12),
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
                    brief,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      height: 1.3,
                      color: p.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rel,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: p.muted,
                    ),
                  ),
                  if (previewUrls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final u in previewUrls.take(5))
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CachedNetworkImage(
                                    imageUrl: u,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Shimmer.fromColors(
                                      baseColor: p.surface,
                                      highlightColor: p.muted
                                          .withValues(alpha: 0.2),
                                      child: Container(color: p.background),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: p.background,
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 14,
                                        color: p.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: generation.status),
                const SizedBox(height: 8),
                Icon(Icons.chevron_right_rounded, color: p.muted, size: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
