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

/// Lista de projetos (gerações) com preview das variações.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({
    super.key,
    required this.service,
    this.onNavigateToCreate,
  });

  final GenerationService? service;
  final VoidCallback? onNavigateToCreate;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryData {
  _GalleryData(this.generations, this.previewUrls);

  final List<Generation> generations;
  final Map<String, List<String>> previewUrls;
}

class _GalleryScreenState extends State<GalleryScreen> {
  late Future<_GalleryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_GalleryData> _load() async {
    final s = widget.service;
    if (s == null) {
      return _GalleryData([], {});
    }
    final gens = await s.fetchGenerations();
    final previews = await s.fetchPreviewImageUrlsByGenerationIds(
      gens.map((g) => g.id),
      limitPerGen: 6,
    );
    return _GalleryData(gens, previews);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _confirmDeleteProject(BuildContext context, Generation g) async {
    final s = widget.service;
    if (s == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final d = ctx.p;
        return AlertDialog(
          backgroundColor: d.surface,
          title: Text(
            'Excluir projeto?',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              color: d.text,
            ),
          ),
          content: Text(
            'Remove o projeto, variações e arquivos no armazenamento.',
            style: GoogleFonts.dmSans(color: d.muted, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar', style: GoogleFonts.dmSans(color: d.muted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Excluir',
                style: GoogleFonts.dmSans(
                  color: StatusBadgeColors.failed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    try {
      await s.deleteGeneration(g.id);
      if (context.mounted) await _refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
  }

  Future<void> _openDetail(Generation g) async {
    final s = widget.service;
    if (s == null) return;
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => GenerationDetailScreen(
          service: s,
          generation: g,
        ),
      ),
    );
    if (deleted == true && mounted) await _refresh();
  }

  static int _cols(double width) {
    if (width >= 1024) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    if (widget.service == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            'Após configurar as chaves de API, seus projetos aparecerão aqui.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: p.muted,
              height: 1.45,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: p.background,
      child: RefreshIndicator(
        color: p.accent,
        onRefresh: _refresh,
        child: FutureBuilder<_GalleryData>(
          future: _future,
          builder: (context, snap) {
            final px = context.p;
            if (snap.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 24),
                children: [
                  MaxWidthBox(
                    maxWidth: 1100,
                    paddingMode: MaxWidthPaddingMode.gallery,
                    child: Column(
                      children: [
                        _ShimmerTile(palette: px),
                        const SizedBox(height: 16),
                        _ShimmerTile(palette: px),
                        const SizedBox(height: 16),
                        _ShimmerTile(palette: px),
                      ],
                    ),
                  ),
                ],
              );
            }
            if (snap.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erro ao carregar: ${snap.error}',
                      style: GoogleFonts.dmSans(color: px.tertiary),
                    ),
                  ),
                ],
              );
            }
            final data = snap.data!;
            final items = data.generations;
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.08),
                  MaxWidthBox(
                    maxWidth: 900,
                    paddingMode: MaxWidthPaddingMode.gallery,
                    child: AppEmptyState(
                      icon: Icons.collections_outlined,
                      title: 'Sua galeria está vazia',
                      subtitle:
                          'Os projetos concluídos aparecerão aqui',
                      actionLabel: 'Criar projeto',
                      onAction: widget.onNavigateToCreate ?? () {},
                    ),
                  ),
                ],
              );
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
                    child: MaxWidthBox(
                      maxWidth: 1100,
                      paddingMode: MaxWidthPaddingMode.gallery,
                      child: Text(
                        'Projetos',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: px.text,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final cols = _cols(constraints.crossAxisExtent);
                    return SliverPadding(
                      padding: const EdgeInsets.only(bottom: 40),
                      sliver: SliverToBoxAdapter(
                        child: MaxWidthBox(
                          maxWidth: 1100,
                          paddingMode: MaxWidthPaddingMode.gallery,
                          child: LayoutBuilder(
                            builder: (context, c2) {
                              final w = c2.maxWidth;
                              final colW =
                                  (w - (cols - 1) * 16) / math.max(1, cols);
                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  for (final g in items)
                                    SizedBox(
                                      width: colW,
                                      child: _ProjectCard(
                                        generation: g,
                                        previewUrls:
                                            data.previewUrls[g.id] ?? [],
                                        onOpen: () => _openDetail(g),
                                        onDelete: () =>
                                            _confirmDeleteProject(context, g),
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

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.generation,
    required this.previewUrls,
    required this.onOpen,
    required this.onDelete,
  });

  final Generation generation;
  final List<String> previewUrls;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final brief = generationCreativeBrief(generation.analysis);
    final rel = formatRelativeTimePt(generation.createdAt);

    return HoverScaleCard(
      borderRadius: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              hoverColor: p.accent.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 100,
                        height: 100,
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
                              fontSize: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            brief,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              height: 1.35,
                              color: p.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StatusBadge(status: generation.status),
                          const SizedBox(height: 6),
                          Text(
                            rel,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: p.muted,
                            ),
                          ),
                          if (previewUrls.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final u in previewUrls)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: CachedNetworkImage(
                                            imageUrl: u,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Shimmer.fromColors(
                                              baseColor: p.surface,
                                              highlightColor: p.muted
                                                  .withValues(alpha: 0.2),
                                              child: Container(
                                                color: p.background,
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              color: p.background,
                                              child: Icon(
                                                Icons.image_outlined,
                                                size: 18,
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
                  ],
                ),
              ),
            ),
          ),
          Tooltip(
            message: 'Excluir projeto',
            child: IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: p.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerTile extends StatelessWidget {
  const _ShimmerTile({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: palette.surface,
      highlightColor: palette.muted.withValues(alpha: 0.2),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
