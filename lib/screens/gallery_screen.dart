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
                    maxWidth: 900,
                    child: Column(
                      children: [
                        _ShimmerTile(palette: px),
                        const SizedBox(height: 14),
                        _ShimmerTile(palette: px),
                        const SizedBox(height: 14),
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
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                  MaxWidthBox(
                    maxWidth: 900,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: px.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: px.border,
                            ),
                          ),
                          child: Icon(
                            Icons.folder_open_rounded,
                            size: 56,
                            color: px.muted.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Nenhum projeto ainda',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: px.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Crie variações a partir de um criativo na aba Criar.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: px.muted,
                            height: 1.45,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: widget.onNavigateToCreate ?? () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: px.accent,
                            foregroundColor: px.onAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Criar primeiro',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 40),
              itemCount: items.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 0, right: 0, bottom: 8),
                    child: MaxWidthBox(
                      maxWidth: 900,
                      child: Text(
                        'Projetos',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: px.text,
                        ),
                      ),
                    ),
                  );
                }
                final g = items[i - 1];
                final previews = data.previewUrls[g.id] ?? [];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: MaxWidthBox(
                    maxWidth: 900,
                    child: _ProjectCard(
                      generation: g,
                      previewUrls: previews,
                      onOpen: () => _openDetail(g),
                      onDelete: () => _confirmDeleteProject(context, g),
                    ),
                  ),
                );
              },
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

  static String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} · '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.all(14),
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
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          const SizedBox(height: 8),
                          StatusBadge(status: generation.status),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(generation.createdAt),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: p.muted,
                            ),
                          ),
                          if (previewUrls.isNotEmpty) ...[
                            const SizedBox(height: 12),
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
                                          width: 40,
                                          height: 40,
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
          IconButton(
            tooltip: 'Excluir projeto',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: p.tertiary,
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
        height: 120,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
